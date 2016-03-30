# ScaleIO for OpenStack plugin

## Overview

A Puppet module that updates OpenStack to work with ScaleIO 2.0 block storage.
Provides supports for volumes and ephemeral storages including live migration and resize.

## Setup

### What Puppet-ScaleIO affects

* Adds rootwrap filters
* Modifies nova.conf and nova-compute.conf
* Patches nova python files
* Modifies cinder.conf
* Patches cinder python files

### Tested with

* Puppet 3.7.2+
* ScaleIO 2.0
* Ubuntu 14.04
* Linux kernel 4.2.0-30-generic
* OpenStack Juno, Kilo, Liberty

### Setup Requirements

Requires nova-compute and/or cinder installed on the node along with ScaleIO SDC.

### Beginning with scaleio
  ```
  puppet module install cloudscaling-scaleio_openstack
  ```

## Structure and specifics

There are 4 manifests:
  * cinder.pp - installs scaleio cinder driver, updates cinder services configurations and notifies services
  * nova.pp   - installs scale nova driver and notify nova service
  * volume_type.pp - create volume type for provided domains and storage pools
  * qos.pp - create QoS rules for volumes

## Usage example
  ```
  class {'scaleio_openstack::cinder':
    ensure              => present,
    gateway_ip          => '192.168.1.10',
    gateway_port        => 4443,
    gateway_user        => 'admin',
    gateway_password    => 'admin',
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

  class {'scaleio_openstack::nova':
    ensure => present,
  }
  ```
