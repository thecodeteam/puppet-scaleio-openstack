"""
Custom EMC Openstack Libvirt plugin for Nova
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
# pylint: disable=E1101
# pylint: disable=F0401

from nova.virt.libvirt.driver import LibvirtDriver, libvirt_volume_drivers


class EMCLibvirtDriver(LibvirtDriver):

    def __init__(self, virtapi, read_only=False):

        # Add scaleio handler to drivers list
        libvirt_volume_drivers.append(
            'scaleio=nova.virt.libvirt.drivers.emc.scaleiolibvirtdriver.LibvirtScaleIOVolumeDriver')

        # call base LibvirtDriver class
        super(EMCLibvirtDriver, self).__init__(virtapi, read_only)
