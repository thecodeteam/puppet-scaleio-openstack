#
# Copyright (C) 2016 EMC
#
# Author: EMC
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for scaleio_openstack::nova class
#

require 'spec_helper'

describe 'scaleio_openstack::nova', :type => :class do

  it { is_expected.to contain_class('scaleio_openstack::nova') }

  let :default_params do {
    :ensure              => 'present',
    :gateway_user        => 'admin',
    :gateway_port        => '4443',
    :nova_compute_conf_file_name => 'nova.conf',
  }
  end
  let (:params) { default_params }

  it { is_expected.to contain_notify('Configuring Compute node for ScaleIO integration')}
  describe 'nova is not installed on the node' do
    let (:facts) do
      {:nova_path => nil,}
    end

    it { should_not contain_file_from_source('scaleio driver for nova') }
    it { should_not contain_scaleio_filter_file('nova filter file') }
    it { should_not contain_service('nova-compute') }
  end

  describe 'nova is installed on the node' do

### LIBERTY
    context 'when nova version is 12.0.1' do
      let (:facts) do
        {:nova_path => '/some/fake/path',
         :nova_version => '12.0.1-ubuntu1'}
      end

      it { is_expected.to contain_notify("Detected nova version: 12.0.1") }
      it { is_expected.to contain_notify("Detected nova version 12.0.1 - treat as Liberty") }

      it { is_expected.to contain_scaleio_openstack__nova_common('nova common for Liberty').with(
        :ensure => 'present',
        :gateway_user => 'admin',
        :gateway_port => '4443',
        :openstack_version => 'liberty',
        :siolib_file => 'siolib-1.4.5.tar.gz',
        :nova_patch => "12.0.1.diff",)}
      it { is_expected.to contain_service('nova-compute').with_ensure('running')}

      it { is_expected.to contain_file("/tmp/siolib-1.4.5.tar.gz").with(
        :source => "puppet:///modules/scaleio_openstack/liberty/siolib-1.4.5.tar.gz")}

      it { is_expected.to contain_package('python-pip').with_ensure('present')}

      it { is_expected.to contain_exec('siolib').with(
        :command => "pip install /tmp/siolib-1.4.5.tar.gz",
        :path => '/bin:/usr/bin:/usr/local/bin')}

      it { is_expected.to contain_scaleio_openstack__scaleio_filter_file('nova filter file').with(
        :ensure  => 'present',
        :service => 'nova')}

      it { is_expected.to contain_file("/usr/share").with_ensure('directory')}
      it { is_expected.to contain_file("/usr/share/nova").with_ensure('directory')}
      it { is_expected.to contain_file("/usr/share/nova/rootwrap").with_ensure('directory')}

      it { is_expected.to contain_scaleio_openstack__file_from_source('/usr/share/nova/rootwrap/scaleio.nova.filters').with(
        :ensure    => 'present',
        :dir       => '/usr/share/nova/rootwrap',
        :file_name => 'scaleio.nova.filters',
        :src_dir   => '.')}

      it { is_expected.to contain_file("/usr/share/nova/rootwrap/scaleio.nova.filters").with(
        :ensure => 'present',
        :source => "puppet:///modules/scaleio_openstack/./scaleio.nova.filters",
        :mode  => '0644',
        :owner => 'root',
        :group => 'root',)}

      it { is_expected.to contain_ini_subsetting("Ensure rootwrap path is in nova config").with(
        :ensure               => 'present',
        :path                 => "/etc/nova/rootwrap.conf",
        :section              => 'DEFAULT',
        :setting              => 'filters_path',
        :subsetting           =>'/usr/share/nova/rootwrap/scaleio.nova.filters',
        :subsetting_separator => ',')}

      it { is_expected.to contain_file("Ensure directory has access: /bin/emc/scaleio").with(
        :ensure  => 'directory',
        :path    => '/bin/emc/scaleio',
        :recurse => true,
        :mode  => '0755',)}

      it { is_expected.to contain_file("/tmp/12.0.1.diff").with(
        :source => "puppet:///modules/scaleio_openstack/liberty/nova/12.0.1.diff")}

      it { is_expected.to contain_exec('nova patch').with(
        :onlyif => "test present = present && patch -p 2 -i /tmp/12.0.1.diff -d /some/fake/path -b -f --dry-run",
        :command => "patch -p 2 -i /tmp/12.0.1.diff -d /some/fake/path -b",
        :path => '/bin:/usr/bin',)}
      it { is_expected.to contain_exec('nova un-patch').with(
        :onlyif => "test present = absent && patch -p 2 -i /tmp/12.0.1.diff -d /some/fake/path -b -R -f --dry-run",
        :command => "patch -p 2 -i /tmp/12.0.1.diff -d /some/fake/path -b -R",
        :path => '/bin:/usr/bin',)}

      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config images_type').with(
        :section => 'libvirt',
        :setting => 'images_type',
        :value   => 'sio',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_ip').with(
        :section => 'scaleio',
        :setting => 'rest_server_ip',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_port').with(
        :section => 'scaleio',
        :setting => 'rest_server_port',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_username').with(
        :section => 'scaleio',
        :setting => 'rest_server_username',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_password').with(
        :section => 'scaleio',
        :setting => 'rest_server_password',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config protection_domain_name').with(
        :section => 'scaleio',
        :setting => 'protection_domain_name',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config storage_pool_name').with(
        :section => 'scaleio',
        :setting => 'storage_pool_name',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config default_sdcguid').with(
        :section => 'scaleio',
        :setting => 'default_sdcguid',)}
    end

### KILO
    context 'when nova version is 2015.1.1' do
      let (:facts) do
       {:nova_path => '/some/fake/path',
        :nova_version => '2015.1.1-ubuntu1'}
      end

      it { is_expected.to contain_notify("Detected nova version: 2015.1.1") }
      it { is_expected.to contain_notify("Detected nova version 2015.1.1 - treat as Kilo") }

      it { is_expected.to contain_scaleio_openstack__nova_common('nova common for Kilo').with(
        :ensure => 'present',
        :gateway_user => 'admin',
        :gateway_port => '4443',
        :openstack_version => 'kilo',
        :siolib_file => 'siolib-1.3.5.tar.gz',
        :nova_patch => "2015.1.1.diff",)}

      it { is_expected.to contain_file("/tmp/siolib-1.3.5.tar.gz").with(
        :source => "puppet:///modules/scaleio_openstack/kilo/siolib-1.3.5.tar.gz")}

      it { is_expected.to contain_package('python-pip').with_ensure('present')}

      it { is_expected.to contain_exec('siolib').with(
        :command => "pip install /tmp/siolib-1.3.5.tar.gz",
        :path => '/bin:/usr/bin:/usr/local/bin')}

      it { is_expected.to contain_scaleio_openstack__scaleio_filter_file('nova filter file').with(
        :ensure  => 'present',
        :service => 'nova')}

      it { is_expected.to contain_file("/usr/share").with_ensure('directory')}
      it { is_expected.to contain_file("/usr/share/nova").with_ensure('directory')}
      it { is_expected.to contain_file("/usr/share/nova/rootwrap").with_ensure('directory')}

      it { is_expected.to contain_scaleio_openstack__file_from_source('/usr/share/nova/rootwrap/scaleio.nova.filters').with(
        :ensure    => 'present',
        :dir       => '/usr/share/nova/rootwrap',
        :file_name => 'scaleio.nova.filters',
        :src_dir   => '.')}

      it { is_expected.to contain_file("/usr/share/nova/rootwrap/scaleio.nova.filters").with(
        :ensure => 'present',
        :source => "puppet:///modules/scaleio_openstack/./scaleio.nova.filters",
        :mode  => '0644',
        :owner => 'root',
        :group => 'root',)}

      it { is_expected.to contain_ini_subsetting("Ensure rootwrap path is in nova config").with(
        :ensure               => 'present',
        :path                 => "/etc/nova/rootwrap.conf",
        :section              => 'DEFAULT',
        :setting              => 'filters_path',
        :subsetting           =>'/usr/share/nova/rootwrap/scaleio.nova.filters',
        :subsetting_separator => ',')}

      it { is_expected.to contain_file("Ensure directory has access: /bin/emc/scaleio").with(
        :ensure  => 'directory',
        :path    => '/bin/emc/scaleio',
        :recurse => true,
        :mode  => '0755',)}

      it { is_expected.to contain_file("/tmp/2015.1.1.diff").with(
        :source => "puppet:///modules/scaleio_openstack/kilo/nova/2015.1.1.diff")}

      it { is_expected.to contain_exec('nova patch').with(
        :onlyif => "test present = present && patch -p 2 -i /tmp/2015.1.1.diff -d /some/fake/path -b -f --dry-run",
        :command => "patch -p 2 -i /tmp/2015.1.1.diff -d /some/fake/path -b",
        :path => '/bin:/usr/bin',)}
      it { is_expected.to contain_exec('nova un-patch').with(
        :onlyif => "test present = absent && patch -p 2 -i /tmp/2015.1.1.diff -d /some/fake/path -b -R -f --dry-run",
        :command => "patch -p 2 -i /tmp/2015.1.1.diff -d /some/fake/path -b -R",
        :path => '/bin:/usr/bin',)}

      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config images_type').with(
        :section => 'libvirt',
        :setting => 'images_type',
        :value   => 'sio',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_ip').with(
        :section => 'scaleio',
        :setting => 'rest_server_ip',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_port').with(
        :section => 'scaleio',
        :setting => 'rest_server_port',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_username').with(
        :section => 'scaleio',
        :setting => 'rest_server_username',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_password').with(
        :section => 'scaleio',
        :setting => 'rest_server_password',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config protection_domain_name').with(
        :section => 'scaleio',
        :setting => 'protection_domain_name',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config storage_pool_name').with(
        :section => 'scaleio',
        :setting => 'storage_pool_name',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config default_sdcguid').with(
        :section => 'scaleio',
        :setting => 'default_sdcguid',)}

      it { is_expected.to contain_file("/some/fake/path/virt/libvirt/drivers").with(
        :ensure  => 'directory',
        :mode    => '0755',)}
      it { is_expected.to contain_file("/some/fake/path/virt/libvirt/drivers/emc").with(
        :ensure  => 'directory',
        :mode    => '0755',)}

      it { is_expected.to contain_scaleio_openstack__file_from_source('scaleio driver for nova file 001').with(
        :ensure    => 'present',
        :dir       => "/some/fake/path/virt/libvirt/drivers",
        :file_name => '__init__.py',
        :src_dir   => 'kilo/nova')}
#       .that_comes_before('File[/some/fake/path/virt/libvirt/drivers/__init__.py]')}
      it { is_expected.to contain_file("/some/fake/path/virt/libvirt/drivers/__init__.py").with(
        :ensure => 'present',
        :source => "puppet:///modules/scaleio_openstack/kilo/nova/__init__.py",
        :mode  => '0644',
        :owner => 'root',
        :group => 'root',)}

      it { is_expected.to contain_scaleio_openstack__file_from_source('scaleio driver for nova file 002').with(
        :ensure    => 'present',
        :dir       => "/some/fake/path/virt/libvirt/drivers/emc",
        :file_name => '__init__.py',
        :src_dir   => 'kilo/nova')}
#      .that_comes_before('File[/some/fake/path/virt/libvirt/drivers/emc/__init__.py]')}
      it { is_expected.to contain_file("/some/fake/path/virt/libvirt/drivers/emc/__init__.py").with(
        :ensure => 'present',
        :source => "puppet:///modules/scaleio_openstack/kilo/nova/__init__.py",
        :mode  => '0644',
        :owner => 'root',
        :group => 'root',)}

      it { is_expected.to contain_scaleio_openstack__file_from_source('scaleio driver for nova file 003').with(
        :ensure    => 'present',
        :dir       => "/some/fake/path/virt/libvirt/drivers/emc",
        :file_name => 'driver.py',
        :src_dir   => 'kilo/nova')}
#      .that_comes_before('File[/some/fake/path/virt/libvirt/drivers/emc/driver.py]')}
      it { is_expected.to contain_file("/some/fake/path/virt/libvirt/drivers/emc/driver.py").with(
        :ensure => 'present',
        :source => "puppet:///modules/scaleio_openstack/kilo/nova/driver.py",
        :mode  => '0644',
        :owner => 'root',
        :group => 'root',)}

      it { is_expected.to contain_scaleio_openstack__file_from_source('scaleio driver for nova file 004').with(
        :ensure    => 'present',
        :dir       => "/some/fake/path/virt/libvirt/drivers/emc",
        :file_name => 'scaleiolibvirtdriver.py',
        :src_dir   => 'kilo/nova')}
#      .that_comes_before('File[/some/fake/path/virt/libvirt/drivers/emc/scaleiolibvirtdriver.py]')}
      it { is_expected.to contain_file("/some/fake/path/virt/libvirt/drivers/emc/scaleiolibvirtdriver.py").with(
        :ensure => 'present',
        :source => "puppet:///modules/scaleio_openstack/kilo/nova/scaleiolibvirtdriver.py",
        :mode  => '0644',
        :owner => 'root',
        :group => 'root',)}

      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config compute_driver').with(
        :ensure  => 'present',
        :path    => "/etc/nova/nova.conf",
        :section => 'DEFAULT',
        :setting => 'compute_driver',
        :value   => 'nova.virt.libvirt.drivers.emc.driver.EMCLibvirtDriver',)}

      it { is_expected.to contain_service('nova-compute').with_ensure('running')}
    end

### JUNO
    context 'when nova version is 2014.2.2' do
      let (:facts) do
       {:nova_path => '/some/fake/path',
        :nova_version => '2014.2.2-ubuntu1'}
      end

      it { is_expected.to contain_notify("Detected nova version: 2014.2.2") }
      it { is_expected.to contain_notify("Detected nova version 2014.2.2 - treat as Juno") }

      it { is_expected.to contain_scaleio_openstack__nova_common('nova common for Juno').with(
        :ensure => 'present',
        :gateway_user => 'admin',
        :gateway_port => '4443',
        :openstack_version => 'juno',
        :siolib_file => 'siolib-1.2.5.tar.gz',
        :nova_patch => "2014.2.2.diff",)}

      it { is_expected.to contain_file("/tmp/siolib-1.2.5.tar.gz").with(
        :source => "puppet:///modules/scaleio_openstack/juno/siolib-1.2.5.tar.gz")}

      it { is_expected.to contain_package('python-pip').with_ensure('present')}

      it { is_expected.to contain_exec('siolib').with(
        :command => "pip install /tmp/siolib-1.2.5.tar.gz",
        :path => '/bin:/usr/bin:/usr/local/bin')}

      it { is_expected.to contain_scaleio_openstack__scaleio_filter_file('nova filter file').with(
        :ensure  => 'present',
        :service => 'nova')}

      it { is_expected.to contain_file("/usr/share").with_ensure('directory')}
      it { is_expected.to contain_file("/usr/share/nova").with_ensure('directory')}
      it { is_expected.to contain_file("/usr/share/nova/rootwrap").with_ensure('directory')}

      it { is_expected.to contain_scaleio_openstack__file_from_source('/usr/share/nova/rootwrap/scaleio.nova.filters').with(
        :ensure    => 'present',
        :dir       => '/usr/share/nova/rootwrap',
        :file_name => 'scaleio.nova.filters',
        :src_dir   => '.')}

      it { is_expected.to contain_file("/usr/share/nova/rootwrap/scaleio.nova.filters").with(
        :ensure => 'present',
        :source => "puppet:///modules/scaleio_openstack/./scaleio.nova.filters",
        :mode  => '0644',
        :owner => 'root',
        :group => 'root',)}

      it { is_expected.to contain_ini_subsetting("Ensure rootwrap path is in nova config").with(
        :ensure               => 'present',
        :path                 => "/etc/nova/rootwrap.conf",
        :section              => 'DEFAULT',
        :setting              => 'filters_path',
        :subsetting           =>'/usr/share/nova/rootwrap/scaleio.nova.filters',
        :subsetting_separator => ',')}

      it { is_expected.to contain_file("Ensure directory has access: /bin/emc/scaleio").with(
        :ensure  => 'directory',
        :path    => '/bin/emc/scaleio',
        :recurse => true,
        :mode  => '0755',)}

      it { is_expected.to contain_file("/tmp/2014.2.2.diff").with(
        :source => "puppet:///modules/scaleio_openstack/juno/nova/2014.2.2.diff")}

      it { is_expected.to contain_exec('nova patch').with(
        :onlyif => "test present = present && patch -p 2 -i /tmp/2014.2.2.diff -d /some/fake/path -b -f --dry-run",
        :command => "patch -p 2 -i /tmp/2014.2.2.diff -d /some/fake/path -b",
        :path => '/bin:/usr/bin',)}
      it { is_expected.to contain_exec('nova un-patch').with(
        :onlyif => "test present = absent && patch -p 2 -i /tmp/2014.2.2.diff -d /some/fake/path -b -R -f --dry-run",
        :command => "patch -p 2 -i /tmp/2014.2.2.diff -d /some/fake/path -b -R",
        :path => '/bin:/usr/bin',)}

      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config images_type').with(
        :section => 'libvirt',
        :setting => 'images_type',
        :value   => 'sio',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_ip').with(
        :section => 'scaleio',
        :setting => 'rest_server_ip',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_port').with(
        :section => 'scaleio',
        :setting => 'rest_server_port',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_username').with(
        :section => 'scaleio',
        :setting => 'rest_server_username',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_password').with(
        :section => 'scaleio',
        :setting => 'rest_server_password',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config protection_domain_name').with(
        :section => 'scaleio',
        :setting => 'protection_domain_name',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config storage_pool_name').with(
        :section => 'scaleio',
        :setting => 'storage_pool_name',)}
      it { is_expected.to contain_ini_setting('scaleio_nova_compute_config default_sdcguid').with(
        :section => 'scaleio',
        :setting => 'default_sdcguid',)}

      it { is_expected.to contain_scaleio_openstack__file_from_source('scaleio driver for nova').with(
        :ensure    => 'present',
        :dir       => "/some/fake/path/virt/libvirt",
        :file_name => 'scaleiolibvirtdriver.py',
        :src_dir   => 'juno/nova')}
#      .that_comes_before('File[/some/fake/path/virt/libvirt/drivers/emc/scaleiolibvirtdriver.py]')}
      it { is_expected.to contain_file("/some/fake/path/virt/libvirt/scaleiolibvirtdriver.py").with(
        :ensure => 'present',
        :source => "puppet:///modules/scaleio_openstack/juno/nova/scaleiolibvirtdriver.py",
        :mode  => '0644',
        :owner => 'root',
        :group => 'root',)}

      it { is_expected.to contain_ini_subsetting('scaleio_nova_config').with(
        :ensure  => 'present',
        :path    => "/etc/nova/nova.conf",
        :section => 'libvirt',
        :setting => 'volume_drivers',
        :subsetting           => 'scaleio=nova.virt.libvirt.scaleiolibvirtdriver.LibvirtScaleIOVolumeDriver',
        :subsetting_separator => ',',)}

      it { is_expected.to contain_service('nova-compute').with_ensure('running')}
    end

### UNSUPPORTED
    context 'when nova version is fake' do
      let (:facts) do {
        :nova_path => '/some/fake/path',
        :nova_version => 'fake-ubuntu1'}
      end
      it { is_expected.to raise_error(Puppet::Error, /Version fake-ubuntu1 isn't supported./)}
    end
  end
end
