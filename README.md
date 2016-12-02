# ScaleIO for OpenStack plugin

## Overview

A Puppet module that updates OpenStack to work with ScaleIO 2.0 block storage.
Provides supports for volumes and nova ephemeral storages including live migration and resize.

Important: ScaleIO supports only 8gb increases for storage allocation so special flavors for storage in multiples of 8
should be created in OpenStack.

## Setup

### What Puppet-ScaleIO-Openstack affects

* Adds rootwrap filters for nova/cinder/glance
* Modifies nova.conf
* Patches nova python files
* Modifies cinder.conf
* Adds cinder_scaleio.config for Juno and Kilo versions
* Patches/Adds cinder python files for some versions
* config-drive=False is set in nova config because config drive live migration is not supported
* Patches glance.conf
* Adds glance user to sudoers

### Tested with

* Puppet 3.*, 4.*
* ScaleIO 2.0+
* Ubuntu 14.04/16.04, Centos 6, Centos 7
* OpenStack Juno, Kilo, Liberty, Mitaka, Newton

### Setup Requirements

Requires nova-compute and/or cinder installed on the node along with ScaleIO SDC.
Also ScaleIO SDC must be installed on glance controller node if cinder with ScaleIO backend is used for glance store.

### Beginning with scaleio
  ```
  puppet module install cloudscaling-scaleio_openstack
  ```

## Structure and specifics

There are 3 manifests to use:
  * cinder.pp - installs scaleio cinder driver, updates cinder services configurations and notifies services
  * nova.pp   - installs scaleio nova driver and notify nova service
  * glance.pp   - configures glance to use cinder as default store

Common code:
  * nova_common.pp - common patching and configuration of nova for all versions of OpenStack
  * init.pp - utility functions
  * and some internal manifests...

Files:
  * juno, kilo, liberty, mitaka, newton
  * for cinder, nova and glance

## Usage example
  ```
  class {'scaleio_openstack::cinder':
    ensure              => present,
    gateway_ip          => '192.168.1.10',
    gateway_port        => 4443,
    gateway_user        => 'admin',
    gateway_password    => 'admin',
  }

  class {'scaleio_openstack::nova':
    ensure           => present,
    gateway_user     => 'admin',
    gateway_password => 'password',
    gateway_ip       => '1.2.3.4',
    gateway_port     => 4443,
  }

  class {'scaleio_openstack::glance':
    ensure => present,
  }

  class {'scaleio_openstack::volume_type':
    ensure              => present,
    protection_domains  => ['pd1', 'pd1', pd2, pd2],
    storage_pools       => ['sp1', 'sp2', sp1, sp2],
    provisioning        => ['thin', 'thick', 'thin', 'thick'],
    os_password         => 'admin',
    os_tenant_name      => 'services',
    os_username         => 'admin',
    os_auth_url         => 'http://127.0.0.1:5000/v2.0/'
  }
  ```

## Nova and cinder extensions

1. ScaleIO ephemeral storage backend for nova is supported (see README here https://github.com/codedellemc/nova-scaleio-ephemeral )

2. Volume type QoS additions. The user can specify those in order to get QoS correlated with
the volume size. The driver will always choose the minimum between the scaling QoS
keys and the pertinent maximum limitation key: sio:iops_limit, sio:bandwidth_limit:
  * sio:iops_per_gb
  * sio:bandwidth_per_gb

3. Cinder configuration addition:
  * provisioning_type for Juno and Kilo (thin or thick)
  * san_thin_provision for Liberty and later (true or false)

## Contact information

- [Project Bug Tracker](https://github.com/codedellemc/puppet-scaleio-openstack/issues)
