"""
Custom EMC Openstack compute manager plugin for Nova
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

from cinder.volume.manager import VolumeManager
from math import ceil

VOLSIZE_MULTIPLE_GB = 8

def volume_size(requested_size_gb):
        """
        ScaleIO creates volumes in multiples of 8. Based on the requested size,
        round up to the nearest multiple of 8 and return the new size.
        :param requested_size_gb: Initial requested size in GB
        :return: New size in GB that is a multiple of 8GB
        """

        size_gb = int(ceil(requested_size_gb/float(VOLSIZE_MULTIPLE_GB)) * VOLSIZE_MULTIPLE_GB)

        return size_gb

class EMCVolumeManager(VolumeManager):

    """
     Subclassed VolumeManager to enable support for a ScaleIO volume extensions
    in OpenStack Cinder.
    """

    def __init__(self, volume_driver=None, service_name=None,
                 *args, **kwargs):
        """
        Initialize custom EMC volume manager that will be used by Cinder
        :param volume_driver:
        :param service_name:
        :param args:
        :param kwargs:
        :return:
        """

        # pylint: disable=E1002
        # call base class initialization
        super(EMCVolumeManager, self).__init__(volume_driver, service_name,
                 *args, **kwargs)

    def extend_volume(self, context, volume_id, new_size, reservations):
        """
        Extend a Cinder volume.  Overwritten because ScaleIO volume sizes
        must be in a granularity of 8GB.  In order to match what is reported in
        both Cinder and ScaleIO, we override the size value.

        :param context:
        :param volume_id:
        :param new_size:
        :param reservations:
        :return:
        """

        # adjust size to the nearest multiple of 8
        new_size = volume_size(requested_size_gb=new_size)

        # call base method
        super(EMCVolumeManager, self).extend_volume(context, volume_id,
                                                    new_size, reservations)




