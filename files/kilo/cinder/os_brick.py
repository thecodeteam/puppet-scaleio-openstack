"""
MonkeyPatched os_brick factory() method (OpenStack Kilo)
"""
#
# Copyright (c) 2015 EMC Corporation
# All Rights Reserved
#
# This software contains the intellectual property of EMC Corporation
# or is licensed to EMC Corporation from third parties.  Use of this
# software and the intellectual property contained therein is expressly
# limited to the terms and conditions of the License Agreement under which
# it is provided by or on behalf of EMC.
#

import json
import os.path
import platform
import requests
import time
from oslo_concurrency import processutils as putils
from oslo_log import log as logging
from cinder.brick import exception
from cinder.brick.initiator.connector import InitiatorConnector
from cinder.i18n import _, _LE, _LW
from six.moves import urllib

LOG = logging.getLogger(__name__)
DEVICE_SCAN_ATTEMPTS_DEFAULT = 3
SDC_BIN_PATHS = ("/opt/emc/scaleio", "/emc/scaleio", "/bin/emc/scaleio") # epc-1094

@staticmethod
def factory(protocol, root_helper, driver=None,
            execute=putils.execute, use_multipath=False,
            device_scan_attempts=DEVICE_SCAN_ATTEMPTS_DEFAULT,
            arch=platform.machine(),
            *args, **kwargs):
    """
    epc-1094
    Patched factory() which is a nested function inside of the
    cinder.brick.initiator.connector. InitiatorConnector class()
    Build a Connector object based upon protocol and architecture.
    :param protocol: Backend type SCALEIO to use for Cinder backups
    :param root_helper:
    :param driver: Connection driver (scaleio.py)
    :param execute:
    :param use_multipath:
    :param device_scan_attempts:
    :param arch:
    :param args:
    :param kwargs:
    :return:
    """

    LOG.debug("Factory for %s on %s" % (protocol, arch))
    protocol = protocol.upper()
    if protocol == "SCALEIO": # epc-1094 adding SCALEIO support in Kilo
        return ScaleIOConnector(
            root_helper=root_helper,
            driver=driver,
            execute=execute,
            device_scan_attempts=device_scan_attempts,
            *args, **kwargs
        )
    else:
        msg = (_("Invalid InitiatorConnector protocol "
                 "specified %(protocol)s") %
               dict(protocol=protocol))
        raise ValueError(msg)


class ScaleIOConnector(InitiatorConnector):
    """
    epc-1094
    Class implements the connector driver for ScaleIO. Code is used by os.brick
    It is monkey patched and augmented here. Supports OpenStack (Kilo)
    """

    OK_STATUS_CODE = 200
    VOLUME_NOT_MAPPED_ERROR = 84
    VOLUME_ALREADY_MAPPED_ERROR = 81
    GET_GUID_CMD = ['drv_cfg', '--query_guid']

    def __init__(self, root_helper, driver=None, execute=putils.execute,
                 device_scan_attempts=DEVICE_SCAN_ATTEMPTS_DEFAULT,
                 *args, **kwargs):
        super(ScaleIOConnector, self).__init__(
            root_helper,
            driver=driver,
            execute=execute,
            device_scan_attempts=device_scan_attempts,
            *args, **kwargs
        )

        self.local_sdc_ip = None
        self.server_ip = None
        self.server_port = None
        self.server_username = None
        self.server_password = None
        self.server_token = None
        self.volume_id = None
        self.volume_name = None
        self.volume_path = None
        self.iops_limit = None
        self.bandwidth_limit = None
        # epc-1094 check if running in container
        self.is_container = self._in_container()

    def get_search_path(self):
        """
        Return path to search for volumes. If running inside a Docker container
        this will be "/var/scaleio/dev/disk/by-id" outside of a container
        "/dev/disk/by-id"
        :return: Path to search for mapped ScaleIO volumes in
        """

        # epc-1094
        if self.is_container:
            return "/var/scaleio/dev/disk/by-id"
        else:
            return "/dev/disk/by-id"

    def get_volume_paths(self, connection_properties):
        """
        Return the volume path information based on the connection_properties
        :param connection_properties:
        :return: List of volume paths
        """

        self.get_config(connection_properties)
        volume_paths = []
        device_paths = [self._find_volume_path()]
        for path in device_paths:
            if os.path.exists(path):
                volume_paths.append(path)
        return volume_paths

    def _in_container(self):
        """
        Check if we are running inside a container.  Check cgroups to determine if
        we are running inside a container.

        :return: Boolean True, running in a container False, not running in a container
        """

        import re

        containerized = False
        cn_match =  re.compile('.*?' + '(docker)|(lxc)', re.IGNORECASE|re.DOTALL)
        with open("/proc/1/cgroup") as cgroup_out:
            match = cn_match.search(cgroup_out.read()) # stop at first match
            if match:
                LOG.info("ScaleIO OpenStack Nova LibVirt driver is running "
                         "inside of a {0} container.".format(match.group(1)))
                containerized = True

        return containerized

    def _find_volume_path(self):
        """
        Internal method that will wait and search for the ScaleIO volume
        to appear after it has been mapped by the local SDC client
        :return: Full mapped disk path
        """

        LOG.info(_LE(
            "Looking for volume %(volume_id)s, maximum tries: %(tries)s"),
            {'volume_id': self.volume_id, 'tries': self.device_scan_attempts}
        )

        # look for the volume in /dev/disk/by-id directory
        by_id_path = self.get_search_path()

        disk_filename = self._wait_for_volume_path(by_id_path)
        full_disk_name = ("%(path)s/%(filename)s" %
                          {'path': by_id_path, 'filename': disk_filename})
        LOG.info(_LE("Full disk name is %(full_path)s"),
                 {'full_path': full_disk_name})
        return full_disk_name

    def _wait_for_volume_path(self, path):
        """
        Wait for mapped volume to appear in path. There is a delay
        between the time the ScaleIO volume is mapped and it appearing
        in the disk device path
        :param path: Path to search for volume in
        :return: Full mapped disk path
        """

        disk_filename = None
        tries = 0

        if not os.path.isdir(path):
            msg = (
                _("ScaleIO volume %(volume_id)s not found at "
                  "expected path.") % {'volume_id': self.volume_id}
                )

            LOG.debug(msg)
            raise exception.BrickException(message=msg)

        while not disk_filename:
            if tries > self.device_scan_attempts:
                msg = (_("ScaleIO volume %(volume_id)s not found.") %
                   {'volume_id': self.volume_id})
                LOG.debug(msg)
                raise exception.BrickException(message=msg)

            filenames = os.listdir(path)
            LOG.debug(_LE(
                "Files found in %(path)s path: %(files)s "),
                {'path': path, 'files': filenames}
            )

            for filename in filenames:
                if (filename.startswith("emc-vol") and
                        filename.endswith(self.volume_id)):
                    disk_filename = filename
            if not disk_filename:
                LOG.warn("ScaleIO volume {0} not yet "
                         "found. Try number: {1} ".format(self.volume_id, tries))
                tries = tries + 1
                time.sleep(1)
            else:
                LOG.info(_LE("ScaleIO volume %(volume_id)s "
                             "found!"), {'volume_id': self.volume_id})

        return disk_filename

    def _get_client_id(self):
        """
        Return the local SDC GUID
        :return: Unique ScaleIO SDC ID
        """

        request = (
            "https://%(server_ip)s:%(server_port)s/"
            "api/types/Client/instances/getByIp::%(sdc_ip)s/" %
            {
                'server_ip': self.server_ip,
                'server_port': self.server_port,
                'sdc_ip': self.local_sdc_ip
            }
        )

        LOG.info(_LE("ScaleIO get client id by ip request: %(request)s"),
                 {'request': request})

        r = requests.get(
            request,
            auth=(self.server_username, self.server_token),
            verify=False
        )

        r = self._check_response(r, request)
        sdc_id = r.json()
        if not sdc_id:
            msg = (_("Client with ip %(sdc_ip)s was not found.") %
                   {'sdc_ip': self.local_sdc_ip})
            raise exception.BrickException(message=msg)

        if r.status_code != 200 and "errorCode" in sdc_id:
            msg = (_("Error getting sdc id from ip %(sdc_ip)s: %(err)s") %
                   {'sdc_ip': self.local_sdc_ip, 'err': sdc_id['message']})

            LOG.error(msg)
            raise exception.BrickException(message=msg)

        LOG.info(_LE("ScaleIO sdc id is %(sdc_id)s."),
                 {'sdc_id': sdc_id})
        return sdc_id

    def _get_volume_id(self):
        """
        Return the current volume contexts ScaleIO unique volume identifier
        :return: ScaleIO volume ID
        """

        volname_encoded = urllib.parse.quote(self.volume_name, '')
        volname_double_encoded = urllib.parse.quote(volname_encoded, '')
        LOG.debug(_(
            "Volume name after double encoding is %(volume_name)s."),
            {'volume_name': volname_double_encoded}
        )

        request = (
            "https://%(server_ip)s:%(server_port)s/api/types/Volume/instances"
            "/getByName::%(encoded_volume_name)s" %
            {
                'server_ip': self.server_ip,
                'server_port': self.server_port,
                'encoded_volume_name': volname_double_encoded
            }
        )

        LOG.info(
            _LE("ScaleIO get volume id by name request: %(request)s"),
            {'request': request}
        )

        r = requests.get(request,
                         auth=(self.server_username, self.server_token),
                         verify=False)

        r = self._check_response(r, request)

        volume_id = r.json()
        if not volume_id:
            msg = (_("Volume with name %(volume_name)s wasn't found.") %
                   {'volume_name': self.volume_name})

            LOG.error(msg)
            raise exception.BrickException(message=msg)

        if r.status_code != self.OK_STATUS_CODE and "errorCode" in volume_id:
            msg = (
                _("Error getting volume id from name %(volume_name)s: "
                  "%(err)s") %
                {'volume_name': self.volume_name, 'err': volume_id['message']}
            )

            LOG.error(msg)
            raise exception.BrickException(message=msg)

        LOG.info(_LE("ScaleIO volume id is %(volume_id)s."),
                 {'volume_id': volume_id})
        return volume_id

    def _check_response(self, response, request, is_get_request=True,
                        params=None):
        """
        Checks the HTTP return code from the ScaleIO gateway. If a 401
        or 403 received it will attempt the request again using a new
        token.
        :param response:
        :param request:
        :param is_get_request:
        :param params:
        :return: HTTP response
        """

        if response.status_code == 401 or response.status_code == 403:
            LOG.info(_LE("Token is invalid, "
                         "going to re-login to get a new one"))

            login_request = (
                "https://%(server_ip)s:%(server_port)s/api/login" %
                {'server_ip': self.server_ip, 'server_port': self.server_port}
            )

            r = requests.get(
                login_request,
                auth=(self.server_username, self.server_password),
                verify=False
            )

            token = r.json()
            # repeat request with valid token
            LOG.debug(_("Going to perform request %(request)s again "
                        "with valid token"), {'request': request})

            if is_get_request:
                res = requests.get(request,
                                   auth=(self.server_username, token),
                                   verify=False)
            else:
                headers = {'content-type': 'application/json'}
                res = requests.post(
                    request,
                    data=json.dumps(params),
                    headers=headers,
                    auth=(self.server_username, token),
                    verify=False
                )

            self.server_token = token
            return res

        return response

    def get_config(self, connection_properties):
        """
        Set ScaleIO specific configuration data on the ScaleIOInitiator object
        :param connection_properties:
        :return: DeviceInfo data structure
        """

        self.local_sdc_ip = connection_properties['hostIP']
        self.volume_name = connection_properties['scaleIO_volname']
        self.server_ip = connection_properties['serverIP']
        self.server_port = connection_properties['serverPort']
        self.server_username = connection_properties['serverUsername']
        self.server_password = connection_properties['serverPassword']
        self.server_token = connection_properties['serverToken']
        self.iops_limit = connection_properties['iopsLimit']
        self.bandwidth_limit = connection_properties['bandwidthLimit']
        device_info = {'type': 'block',
                       'path': self.volume_path}

        return device_info

    def connect_volume(self, connection_properties):
        """Connect the volume.

        :param connection_properties: The dictionary that describes all
                                      of the target volume attributes.
        :type connection_properties: dict
        :returns: dict
        """
        device_info = self.get_config(connection_properties)
        LOG.debug(
            _LE(
                "scaleIO Volume name: %(volume_name)s, SDC IP: %(sdc_ip)s, "
                "REST Server IP: %(server_ip)s, "
                "REST Server username: %(username)s, "
                "iops limit:%(iops_limit)s, "
                "bandwidth limit: %(bandwidth_limit)s."
            ), {
                'volume_name': self.volume_name,
                'sdc_ip': self.local_sdc_ip,
                'server_ip': self.server_ip,
                'username': self.server_username,
                'iops_limit': self.iops_limit,
                'bandwidth_limit': self.bandwidth_limit
            }
        )

        LOG.info(_LE("ScaleIO sdc query guid command: %(cmd)s"),
                 {'cmd': self.GET_GUID_CMD})

        try:
            (out, err) = self._execute(*self.GET_GUID_CMD, run_as_root=True,
                                       root_helper=self._root_helper)

            LOG.info(_LE("Map volume %(cmd)s: stdout=%(out)s "
                         "stderr=%(err)s"),
                     {'cmd': self.GET_GUID_CMD, 'out': out, 'err': err})

        except putils.ProcessExecutionError as e:
            msg = (_("Error querying sdc guid: %(err)s") % {'err': e.stderr})
            LOG.error(msg)
            raise exception.BrickException(message=msg)

        guid = out
        LOG.info(_LE("Current sdc guid: %(guid)s"), {'guid': guid})
        params = {'guid': guid, 'allowMultipleMappings': 'TRUE'}
        self.volume_id = self._get_volume_id()

        headers = {'content-type': 'application/json'}
        request = (
            "https://%(server_ip)s:%(server_port)s/api/instances/"
            "Volume::%(volume_id)s/action/addMappedSdc" %
            {'server_ip': self.server_ip, 'server_port': self.server_port,
             'volume_id': self.volume_id}
        )

        LOG.info(_LE("map volume request: %(request)s"), {'request': request})
        r = requests.post(
            request,
            data=json.dumps(params),
            headers=headers,
            auth=(self.server_username, self.server_token),
            verify=False
        )

        r = self._check_response(r, request, False, params)
        if r.status_code != self.OK_STATUS_CODE:
            response = r.json()
            error_code = response['errorCode']
            if error_code == self.VOLUME_ALREADY_MAPPED_ERROR:
                LOG.warning(_LW(
                    "Ignoring error mapping volume %(volume_name)s: "
                    "volume already mapped."),
                    {'volume_name': self.volume_name}
                )
            else:
                msg = (
                    _("Error mapping volume %(volume_name)s: %(err)s") %
                    {'volume_name': self.volume_name,
                     'err': response['message']}
                )

                LOG.error(msg)
                raise exception.BrickException(message=msg)

        self.volume_path = self._find_volume_path()
        device_info['path'] = self.volume_path

        # Set QoS settings after map was performed
        if self.iops_limit is not None or self.bandwidth_limit is not None:
            params = {'guid': guid}
            if self.bandwidth_limit is not None:
                params['bandwidthLimitInKbps'] = self.bandwidth_limit
            if self.iops_limit is not None:
                params['iopsLimit'] = self.iops_limit

            request = (
                "https://%(server_ip)s:%(server_port)s/api/instances/"
                "Volume::%(volume_id)s/action/setMappedSdcLimits" %
                {'server_ip': self.server_ip, 'server_port': self.server_port,
                 'volume_id': self.volume_id}
            )

            LOG.info(_LE("Set client limit request: %(request)s"),
                     {'request': request})

            r = requests.post(
                request,
                data=json.dumps(params),
                headers=headers,
                auth=(self.server_username, self.server_token),
                verify=False
            )
            r = self._check_response(r, request, False, params)
            if r.status_code != self.OK_STATUS_CODE:
                response = r.json()
                LOG.info(_LE("Set client limit response: %(response)s"),
                         {'response': response})
                msg = (
                    _("Error setting client limits for volume "
                      "%(volume_name)s: %(err)s") %
                    {'volume_name': self.volume_name,
                     'err': response['message']}
                )

                LOG.error(msg)

        return device_info

    def disconnect_volume(self, connection_properties, device_info):
        """Disconnect the ScaleIO volume.

        :param connection_properties: The dictionary that describes all
                                      of the target volume attributes.
        :type connection_properties: dict
        :param device_info: historical difference, but same as connection_props
        :type device_info: dict
        """
        self.get_config(connection_properties)
        self.volume_id = self._get_volume_id()
        LOG.info(_LE(
            "ScaleIO disconnect volume in ScaleIO brick volume driver."
        ))

        LOG.debug(
            _("ScaleIO Volume name: %(volume_name)s, SDC IP: %(sdc_ip)s, "
              "REST Server IP: %(server_ip)s"),
            {'volume_name': self.volume_name, 'sdc_ip': self.local_sdc_ip,
             'server_ip': self.server_ip}
        )

        LOG.info(_LE("ScaleIO sdc query guid command: %(cmd)s"),
                 {'cmd': self.GET_GUID_CMD})

        try:
            (out, err) = self._execute(*self.GET_GUID_CMD, run_as_root=True,
                                       root_helper=self._root_helper)
            LOG.info(
                _LE("Unmap volume %(cmd)s: stdout=%(out)s stderr=%(err)s"),
                {'cmd': self.GET_GUID_CMD, 'out': out, 'err': err}
            )

        except putils.ProcessExecutionError as e:
            msg = _("Error querying sdc guid: %(err)s") % {'err': e.stderr}
            LOG.error(msg)
            raise exception.BrickException(message=msg)

        guid = out
        LOG.info(_LE("Current sdc guid: %(guid)s"), {'guid': guid})

        params = {'guid': guid}
        headers = {'content-type': 'application/json'}
        request = (
            "https://%(server_ip)s:%(server_port)s/api/instances/"
            "Volume::%(volume_id)s/action/removeMappedSdc" %
            {'server_ip': self.server_ip, 'server_port': self.server_port,
             'volume_id': self.volume_id}
        )

        LOG.info(_LE("Unmap volume request: %(request)s"),
                 {'request': request})
        r = requests.post(
            request,
            data=json.dumps(params),
            headers=headers,
            auth=(self.server_username, self.server_token),
            verify=False
        )

        r = self._check_response(r, request, False, params)
        if r.status_code != self.OK_STATUS_CODE:
            response = r.json()
            error_code = response['errorCode']
            if error_code == self.VOLUME_NOT_MAPPED_ERROR:
                LOG.warning(_LW(
                    "Ignoring error unmapping volume %(volume_id)s: "
                    "volume not mapped."), {'volume_id': self.volume_name}
                )
            else:
                msg = (_("Error unmapping volume %(volume_id)s: %(err)s") %
                       {'volume_id': self.volume_name,
                        'err': response['message']})
                LOG.error(msg)
                raise exception.BrickException(message=msg)