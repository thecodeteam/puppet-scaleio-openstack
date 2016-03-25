"""
Custom EMC ScaleIO libvirt driver for OpenStack Nova
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

# pylint: disable=W0223
# pylint: disable=E1002

import siolib
from siolib.scaleio import ScaleIO
from nova import utils
from nova.virt.libvirt.volume import LibvirtBaseVolumeDriver


class LibvirtScaleIOVolumeDriver(LibvirtBaseVolumeDriver):

    """
    ScaleIO OpenStack libvirt driver
    """

    def __init__(self, connection, is_block_dev=False):
        """

        :param connection:
        :param is_block_dev:
        :return:
        """

        (self.sdc_guid, err) = utils.execute('drv_cfg', '--query_guid', run_as_root=True)

        super(LibvirtScaleIOVolumeDriver, self).__init__(connection,
                                                         is_block_dev=is_block_dev)

    def get_config(self, connection_info, disk_info):
        """
        Returns xml for libvirt
        :param connection_info:
        :param disk_info:
        :return:
        """

        conf = super(LibvirtScaleIOVolumeDriver, self).get_config(
            connection_info, disk_info)

        conf.source_type = 'block'
        conf.source_path = connection_info['data']['device_path']
        return conf

    def connect_volume(self, connection_info, disk_info):
        """
        Connect the volume.
        :param connection_info:
        :param disk_info:
        :return:
        """

        # initiate base method
        super(LibvirtScaleIOVolumeDriver, self).connect_volume(connection_info,
                                                               disk_info)

        conf = self._get_conf(connection_info)
        # create reference to ScaleIO connection library
        lib = ScaleIO(conf=conf)

        # retrieve volume name from connection_info
        volume_name = connection_info['data']['scaleIO_volname']
        volume_id = lib.get_volumeid(volume_name=volume_name)

        # attach (map) volume
        lib.attach_volume(volume_id=volume_id)

        # capture device path and return
        volume_path = lib.get_volumepath(volume_id=volume_id)
        connection_info['data']['device_path'] = volume_path

    def disconnect_volume(self, connection_info, disk_dev):
        """
        Disconnect the volume.
        :param connection_info:
        :param disk_dev:
        :return:
        """

        # initiate base method
        super(LibvirtScaleIOVolumeDriver, self).disconnect_volume(connection_info,
                                                                  disk_dev)

        conf = self._get_conf(connection_info)
        # create reference to ScaleIO connection library
        lib = ScaleIO(conf=conf)

        # retrieve volume name from connection_info
        volume_name = connection_info['data']['scaleIO_volname']
        volume_id = lib.get_volumeid(volume_name=volume_name)

        # detach (unmap) volume
        lib.detach_volume(volume_id=volume_id)

    def _get_conf(self, connection_info):
        # Capture connection info for siolib
        conf = siolib.ConfigOpts()
        conf.register_group(siolib.SIOGROUP)
        conf.register_opts(siolib.SIOOPTS, siolib.SIOGROUP)
        conf.scaleio.rest_server_username = connection_info[
            'data']['serverUsername']
        conf.scaleio.rest_server_password = connection_info[
            'data']['serverPassword']
        conf.scaleio.rest_server_ip = connection_info['data']['serverIP']
        conf.scaleio.rest_server_port = connection_info['data']['serverPort']
        conf.scaleio.default_sdcguid = self.sdc_guid
        return conf
