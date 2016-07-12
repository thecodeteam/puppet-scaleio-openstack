# Copyright (c) 2016 EMC Corporation.
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
"""
Extension of driver for EMC ScaleIO based on ScaleIO remote CLI.
"""

from oslo_log import log as logging
import six

from cinder import exception
from cinder.i18n import _, _LI, _LW
from cinder.volume.drivers.emc import scaleio

LOG = logging.getLogger(__name__)

IOPS_PER_GB = 'sio:iops_per_gb'
BANDWIDTH_PER_GB = 'sio:bandwidth_per_gb'
QOS_IOPS_PER_GB = 'maxIOPSperGB'
QOS_BANDWIDTH_PER_GB = 'maxBWSperGB'

MIN_BWS_SCALING_SIZE = 128

class ScaleIODriver(scaleio.ScaleIODriver):

    def __init__(self, *args, **kwargs):
        scaleio_qos_keys = (scaleio.QOS_IOPS_LIMIT_KEY,
                            scaleio.QOS_BANDWIDTH_LIMIT,
                            QOS_IOPS_PER_GB, QOS_BANDWIDTH_PER_GB)
        super(ScaleIODriver, self).__init__(*args, **kwargs)
        self.provisioning_type = (
            'thin'
            if self.configuration.san_thin_provision else
            'thick')

    def initialize_connection(self, volume, connector):
        result = super(ScaleIODriver, self).initialize_connection(volume,
                                                                  connector)
        storage_type = self._get_volumetype_extraspecs(volume)
        round_volume_size = int(self._round_to_num_gran(volume.size))
        iops_limit = self._get_iops_limit(round_volume_size, storage_type)
        bandwidth_limit = self._get_bandwidth_limit(round_volume_size,
                                                    storage_type)
        LOG.info(_LI("iops limit is %s"), iops_limit)
        LOG.info(_LI("bandwidth limit is %s"), bandwidth_limit)
        result['data']['iopsLimit'] = iops_limit
        result['data']['bandwidthLimit'] = bandwidth_limit
        return result

    def _get_bandwidth_limit(self, size, storage_type):
        try:
            max_bandwidth = self._find_limit(storage_type,
                scaleio.QOS_BANDWIDTH_LIMIT, scaleio.BANDWIDTH_LIMIT)
            if max_bandwidth is not None:
                max_bandwidth = (self._round_to_num_gran(int(max_bandwidth),
                                                         units.Ki))
                max_bandwidth = six.text_type(max_bandwidth)
            LOG.info(_LI("max bandwidth is: %s"), max_bandwidth)
            bw_per_gb = self._find_limit(storage_type,
                QOS_BANDWIDTH_PER_GB, BANDWIDTH_PER_GB)
            LOG.info(_LI("bandwidth per gb is: %s"), bw_per_gb)
            if bw_per_gb is None:
                return max_bandwidth
            # Since ScaleIO volumes size is in 8GB granularity
            # and BWS limitation is in 1024 KBs granularity, we need to make
            # sure that scaled_bw_limit is in 128 granularity.
            scaled_bw_limit = (size *
                               self._round_to_num_gran(int(bw_per_gb),
                                                       MIN_BWS_SCALING_SIZE))
            if max_bandwidth is None or scaled_bw_limit < int(max_bandwidth):
                return six.text_type(scaled_bw_limit)
            else:
                return max_bandwidth
        except ValueError:
            msg = _("None numeric BWS QoS limitation")
            raise exception.InvalidInput(reason=msg)

    def _get_iops_limit(self, size, storage_type):
        max_iops = self._find_limit(storage_type,
            scaleio.QOS_IOPS_LIMIT_KEY, scaleio.IOPS_LIMIT_KEY)
        LOG.info(_LI("max iops is: %s"), max_iops)
        iops_per_gb = self._find_limit(storage_type,
            QOS_IOPS_PER_GB, IOPS_PER_GB)
        LOG.info(_LI("iops per gb is: %s"), iops_per_gb)
        try:
            if iops_per_gb is None:
                if max_iops is not None:
                    return six.text_type(max_iops)
                else:
                    return None
            scaled_iops_limit = size * int(iops_per_gb)
            if max_iops is None or scaled_iops_limit < int(max_iops):
                return six.text_type(scaled_iops_limit)
            else:
                return six.text_type(max_iops)
        except ValueError:
            msg = _("None numeric IOPS QoS limitation")
            raise exception.InvalidInput(reason=msg)

    def _round_to_num_gran(self, size, num=8):
        if size % num == 0:
            return size
        return size + num - (size % num)

    def _find_provisioning_type(self, storage_type):
        return storage_type.get(scaleio.PROVISIONING_KEY,
                                self.provisioning_type)
