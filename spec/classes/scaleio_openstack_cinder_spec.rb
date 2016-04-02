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
# Unit tests for scaleio_openstack::cinder class
#

require 'spec_helper'

describe 'scaleio_openstack::cinder', :type => :class  do

  let :default_params do {
    :ensure                     => 'present',    # could be present or absent
    :gateway_user               => 'admin',
    :gateway_port               => '4443',
    :gateway_password   => 'password',
    :gateway_ip         => '1.2.3.4',
    :protection_domains => 'pd1',
    :storage_pools      => 'sp1',
    :verify_server_certificate  => 'False',
    :force_delete               => 'True',
    :round_volume_capacity      => 'True',
    :scaleio_cinder_config_file => '/etc/cinder/cinder_scaleio.config',
    :default_lvm_backend        => 'lvmdriver',}
  end
  let (:params) { default_params }
  let (:content) { /rest_server_ip = 1.2.3.4\nrest_server_port = 4443\nrest_server_username = admin\nrest_server_password = password\nprotection_domain_name = pd1\nstorage_pools = pd1:sp1\nstorage_pool_name = sp1\nround_volume_capacity = True\nforce_delete = True\nverify_server_certificate = False\n/ }

  it { is_expected.to contain_class('scaleio_openstack::cinder')}
  it { is_expected.to contain_notify('Configure Cinder to use ScaleIO cluster')}

### NOT INSTALLED
  context 'when cinder is not installed on the node' do
    let (:facts) do
      {:cinder_path => nil,}
    end
    it { is_expected.not_to raise_error() }
    it { should_not contain_file_from_source(/scaleio driver for cinder/) }
    it { should_not contain_scaleio_filter_file(/cinder filter file/) }
    it { should_not contain_service('cinder-compute') }
  end

### UNSUPPORTED 
  context 'cinder unsupported version' do
    let (:facts) do {
      :cinder_path      => '/some/fake/path',
      :cinder_version   => '2014.1.1',
    } end
    it { is_expected.to raise_error(Puppet::Error, /Version 2014.1.1 isn't supported./)}
  end

### JUNO
  context 'cinder Juno is installed on the node' do
    let (:facts) {{
      :cinder_path      => '/some/fake/path',
      :cinder_version   => '2014.2.2'
    }}

    it { is_expected.not_to raise_error() }
    it { is_expected.to contain_notify ("Detected cinder version 2014.2.2 - treat as Juno")}

    it { is_expected.to contain_file("Ensure directory has access: /bin/emc/scaleio").with(
        :ensure  => 'directory',
        :path    => '/bin/emc/scaleio',
        :recurse => true,
        :mode  => '0755',)}

    it { should contain_scaleio_openstack__file_from_source('scaleio driver for cinder').with({
      :ensure           => 'present',
      :dir              => '/some/fake/path/volume/drivers/emc',
      :file_name        => 'scaleio.py',
      :src_dir          => 'juno/cinder',})
#      }).that_comes_before(['Scaleio_filter_file[cinder filter file]'])
    }

    it { is_expected.to contain_scaleio_openstack__cinder__patch_common('patch juno cinder conf')}

    it { is_expected.to contain_file("/some/fake/path/volume/drivers/emc/scaleio.py").with(
      :ensure => 'present',
      :source => "puppet:///modules/scaleio_openstack/juno/cinder/scaleio.py",
      :mode  => '0644',
      :owner => 'root',
      :group => 'root',)}

    it { is_expected.to contain_file('/etc/cinder/cinder_scaleio.config').with_ensure('present')
      .with_content(content)}

    it { is_expected.to contain_ini_setting('enabled_backends').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'DEFAULT',
      :setting => 'enabled_backends',
      :value   => 'scaleio',)}
    it { is_expected.to contain_ini_setting('volume_driver').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'volume_driver',
      :value   => 'cinder.volume.drivers.emc.scaleio.ScaleIODriver',)}
    it { is_expected.to contain_ini_setting('cinder_scaleio_config_file').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'cinder_scaleio_config_file',
      :value   => '/etc/cinder/cinder_scaleio.config',)}
    it { is_expected.to contain_ini_setting('volume_backend_name').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'volume_backend_name',
      :value   => 'scaleio',)}

    it { should contain_scaleio_openstack__scaleio_filter_file('cinder filter file').with({
      :ensure           => :present,
      :service          => 'cinder',
      })
#     .that_notifies(['Service[nova-compute]'])
    }

    it { should contain_file("/usr/share").with_ensure('directory')}
    it { should contain_file("/usr/share/cinder").with_ensure('directory')}
    it { should contain_file("/usr/share/cinder/rootwrap").with_ensure('directory')}

    it { should contain_scaleio_openstack__file_from_source('/usr/share/cinder/rootwrap/scaleio.cinder.filters').with(
      :ensure    => 'present',
      :dir       => '/usr/share/cinder/rootwrap',
      :file_name => 'scaleio.cinder.filters',
      :src_dir   => '.')}

    it { is_expected.to contain_file("/usr/share/cinder/rootwrap/scaleio.cinder.filters").with(
      :ensure => 'present',
      :source => "puppet:///modules/scaleio_openstack/./scaleio.cinder.filters",
      :mode  => '0644',
      :owner => 'root',
      :group => 'root',)}

    it { should contain_ini_subsetting("Ensure rootwrap path is in cinder config").with(
      :ensure               => 'present',
      :path                 => "/etc/cinder/rootwrap.conf",
      :section              => 'DEFAULT',
      :setting              => 'filters_path',
      :subsetting           => '/usr/share/cinder/rootwrap/scaleio.cinder.filters',
      :subsetting_separator => ',',)}

    it { should contain_service('cinder-api').with_ensure('running')}
    it { should contain_service('cinder-scheduler').with_ensure('running')}
    it { should contain_service('cinder-volume').with_ensure('running')}
  end

### KILO
  context 'cinder Kilo is installed on the node' do
    let (:facts) {{
      :cinder_path      => '/some/fake/path',
      :cinder_version   => '2015.1.1'
    }}

    it { is_expected.not_to raise_error() }
    it { is_expected.to contain_notify ("Detected cinder version 2015.1.1 - treat as Kilo")}

    it { is_expected.to contain_file("Ensure directory has access: /bin/emc/scaleio").with(
        :ensure  => 'directory',
        :path    => '/bin/emc/scaleio',
        :recurse => true,
        :mode  => '0755',)}

    it { is_expected.to contain_file("Ensure managers directory present: ").with(
        :ensure  => 'directory',
        :path    => "/some/fake/path/volume/managers",
        :mode    => '0755',)}
    it { is_expected.to contain_file("Ensure emc directory present: ").with(
        :ensure  => 'directory',
        :path    => "/some/fake/path/volume/managers/emc",
        :mode    => '0755')}

    it { should contain_scaleio_openstack__file_from_source('scaleio driver for cinder file 001').with({
      :ensure           => 'present',
      :dir              => '/some/fake/path/volume/managers',
      :file_name        => '__init__.py',
      :src_dir          => 'kilo/cinder',})
#      }).that_comes_before(['Scaleio_filter_file[cinder filter file]'])
    }
    it { is_expected.to contain_file("/some/fake/path/volume/managers/__init__.py").with(
      :ensure => 'present',
      :source => "puppet:///modules/scaleio_openstack/kilo/cinder/__init__.py",
      :mode  => '0644',
      :owner => 'root',
      :group => 'root',)}

    it { should contain_scaleio_openstack__file_from_source('scaleio driver for cinder file 002').with({
      :ensure           => 'present',
      :dir              => '/some/fake/path/volume/managers/emc',
      :file_name        => '__init__.py',
      :src_dir          => 'kilo/cinder',})
#      }).that_comes_before(['Scaleio_filter_file[cinder filter file]'])
    }
    it { is_expected.to contain_file("/some/fake/path/volume/managers/emc/__init__.py").with(
      :ensure => 'present',
      :source => "puppet:///modules/scaleio_openstack/kilo/cinder/__init__.py",
      :mode  => '0644',
      :owner => 'root',
      :group => 'root',)}

    it { should contain_scaleio_openstack__file_from_source('scaleio driver for cinder file 003').with({
      :ensure           => 'present',
      :dir              => '/some/fake/path/volume/managers/emc',
      :file_name        => 'manager.py',
      :src_dir          => 'kilo/cinder',})
#      }).that_comes_before(['Scaleio_filter_file[cinder filter file]'])
    }
    it { is_expected.to contain_file("/some/fake/path/volume/managers/emc/manager.py").with(
      :ensure => 'present',
      :source => "puppet:///modules/scaleio_openstack/kilo/cinder/manager.py",
      :mode  => '0644',
      :owner => 'root',
      :group => 'root',)}

    it { should contain_scaleio_openstack__file_from_source('scaleio driver for cinder file 004').with({
      :ensure           => 'present',
      :dir              => '/some/fake/path/volume/drivers/emc',
      :file_name        => 'os_brick.py',
      :src_dir          => 'kilo/cinder',})
#      }).that_comes_before(['Scaleio_filter_file[cinder filter file]'])
    }
    it { is_expected.to contain_file("/some/fake/path/volume/drivers/emc/os_brick.py").with(
      :ensure => 'present',
      :source => "puppet:///modules/scaleio_openstack/kilo/cinder/os_brick.py",
      :mode  => '0644',
      :owner => 'root',
      :group => 'root',)}

    it { should contain_scaleio_openstack__file_from_source('scaleio driver for cinder file 005').with({
      :ensure           => 'present',
      :dir              => '/some/fake/path/volume/drivers/emc',
      :file_name        => 'scaleio.py',
      :src_dir          => 'kilo/cinder',})
#      }).that_comes_before(['Scaleio_filter_file[cinder filter file]'])
    }
    it { is_expected.to contain_file("/some/fake/path/volume/drivers/emc/scaleio.py").with(
      :ensure => 'present',
      :source => "puppet:///modules/scaleio_openstack/kilo/cinder/scaleio.py",
      :mode  => '0644',
      :owner => 'root',
      :group => 'root',)}

    it { should contain_scaleio_openstack__file_from_source('scaleio driver for cinder file 006').with({
      :ensure           => 'present',
      :dir              => '/some/fake/path/volume/drivers/emc',
      :file_name        => 'swift_client.py',
      :src_dir          => 'kilo/cinder',})
#      }).that_comes_before(['Scaleio_filter_file[cinder filter file]'])
    }
    it { is_expected.to contain_file("/some/fake/path/volume/drivers/emc/swift_client.py").with(
      :ensure => 'present',
      :source => "puppet:///modules/scaleio_openstack/kilo/cinder/swift_client.py",
      :mode  => '0644',
      :owner => 'root',
      :group => 'root',)}

     it { is_expected.to contain_ini_setting('change_volume_manager').with(
        :ensure  => 'present',
        :path    => '/etc/cinder/cinder.conf',
        :section => 'DEFAULT',
        :setting => 'volume_manager',
        :value   => 'cinder.volume.managers.emc.manager.EMCVolumeManager',)}

    it { is_expected.to contain_scaleio_openstack__cinder__patch_common('patch kilo cinder')}

    it { should contain_scaleio_openstack__scaleio_filter_file('cinder filter file').with({
      :ensure           => :present,
      :service          => 'cinder',
      })
#     .that_notifies(['Service[nova-compute]'])
    }

    it { is_expected.to contain_file('/etc/cinder/cinder_scaleio.config').with_ensure('present')
      .with_content(content)}

    it { is_expected.to contain_ini_setting('enabled_backends').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'DEFAULT',
      :setting => 'enabled_backends',
      :value   => 'scaleio',)}
    it { is_expected.to contain_ini_setting('volume_driver').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'volume_driver',
      :value   => 'cinder.volume.drivers.emc.scaleio.ScaleIODriver',)}
    it { is_expected.to contain_ini_setting('cinder_scaleio_config_file').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'cinder_scaleio_config_file',
      :value   => '/etc/cinder/cinder_scaleio.config',)}
    it { is_expected.to contain_ini_setting('volume_backend_name').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'volume_backend_name',
      :value   => 'scaleio',)}

    it { should contain_file("/usr/share").with_ensure('directory')}
    it { should contain_file("/usr/share/cinder").with_ensure('directory')}
    it { should contain_file("/usr/share/cinder/rootwrap").with_ensure('directory')}

    it { should contain_scaleio_openstack__file_from_source('/usr/share/cinder/rootwrap/scaleio.cinder.filters').with(
      :ensure    => 'present',
      :dir       => '/usr/share/cinder/rootwrap',
      :file_name => 'scaleio.cinder.filters',
      :src_dir   => '.')}

    it { is_expected.to contain_file("/usr/share/cinder/rootwrap/scaleio.cinder.filters").with(
      :ensure => 'present',
      :source => "puppet:///modules/scaleio_openstack/./scaleio.cinder.filters",
      :mode  => '0644',
      :owner => 'root',
      :group => 'root',)}

    it { should contain_ini_subsetting("Ensure rootwrap path is in cinder config").with(
      :ensure               => 'present',
      :path                 => "/etc/cinder/rootwrap.conf",
      :section              => 'DEFAULT',
      :setting              => 'filters_path',
      :subsetting           => '/usr/share/cinder/rootwrap/scaleio.cinder.filters',
      :subsetting_separator => ',',)}

    it { should contain_service('cinder-api').with_ensure('running')}
    it { should contain_service('cinder-scheduler').with_ensure('running')}
    it { should contain_service('cinder-volume').with_ensure('running')}
  end

### LIBERTY
  context 'cinder Liberty is installed on the node' do
    let (:facts) {{
      :cinder_path      => '/some/fake/path',
      :cinder_version   => '7.1.1'
    }}

    it { is_expected.not_to raise_error() }
    it { is_expected.to contain_notify ("Detected cinder version 7.1.1 - treat as Liberty")}

    it { is_expected.to contain_file("Ensure directory has access: /bin/emc/scaleio").with(
        :ensure  => 'directory',
        :path    => '/bin/emc/scaleio',
        :recurse => true,
        :mode  => '0755',)}

    it { is_expected.to contain_ini_setting('enabled_backends').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'DEFAULT',
      :setting => 'enabled_backends',
      :value   => 'scaleio')}
    it { is_expected.to contain_ini_setting('default_volume_type').with(
      :ensure  => 'present',
      :path    => '/etc/cinder/cinder.conf',
      :section => 'DEFAULT',
      :setting => 'default_volume_type',
      :value   => 'scaleio',)}
    it { is_expected.to contain_ini_setting('scaleio volume_driver').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'volume_driver',
      :value   => 'cinder.volume.drivers.emc.scaleio.ScaleIODriver',)}
    it { is_expected.to contain_ini_setting('scaleio volume_backend_name').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'volume_backend_name',
      :value   => 'scaleio',)}
    it { is_expected.to contain_ini_setting('scaleio sio_round_volume_capacity').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'sio_round_volume_capacity',
      :value   => 'True')}
    it { is_expected.to contain_ini_setting('scaleio sio_verify_server_certificate').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'sio_verify_server_certificate',
      :value   => 'False',)}
    it { is_expected.to contain_ini_setting('scaleio sio_force_delete').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'sio_force_delete',
      :value   => 'True',)}
    it { is_expected.to contain_ini_setting('scaleio sio_unmap_volume_before_deletion').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'sio_unmap_volume_before_deletion',
      :value   => 'True',)}
    it { is_expected.to contain_ini_setting('scaleio san_ip').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'san_ip',
      :value   => '1.2.3.4',)}
    it { is_expected.to contain_ini_setting('scaleio sio_rest_server_port').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'sio_rest_server_port',
      :value   => '4443',)}
    it { is_expected.to contain_ini_setting('scaleio san_login').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'san_login',
      :value   => 'admin',)}
    it { is_expected.to contain_ini_setting('scaleio san_password').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'san_password',
      :value   => 'password',)}
    it { is_expected.to contain_ini_setting('scaleio sio_protection_domain_name').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'sio_protection_domain_name',
      :value   => 'pd1',)}
    it { is_expected.to contain_ini_setting('scaleio sio_storage_pools').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'sio_storage_pools',
      :value   => 'pd1:sp1',)}
    it { is_expected.to contain_ini_setting('scaleio sio_storage_pool_name').with(
      :path    => '/etc/cinder/cinder.conf',
      :section => 'scaleio',
      :setting => 'sio_storage_pool_name',
      :value   => 'sp1',)}

    it { should contain_service('cinder-api').with_ensure('running')}
    it { should contain_service('cinder-scheduler').with_ensure('running')}
    it { should contain_service('cinder-volume').with_ensure('running')}
  end
end

