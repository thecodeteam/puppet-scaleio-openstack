require 'spec_helper'

describe 'scaleio_openstack::nova_common' do

  let (:title) {'title'}
  let (:params) {{
    :ensure              => 'ensure',
    :gateway_user        => 'gateway_user',
    :gateway_password    => 'gateway_password',
    :gateway_ip          => 'gateway_ip',
    :gateway_port        => 'gateway_port',
    :protection_domains  => 'pd1,pd2',
    :storage_pools       => 'sp1,sp2',
    :provisioning_type   => 'thin',
    :openstack_version   => 'openstack_version',
    :siolib_file         => 'siolib_file',
    :nova_patch          => 'nova_patch',
    :nova_config_file    => 'nova_config_file',}}

  it { is_expected.to contain_scaleio_openstack__nova_common(title) }

  it { is_expected.to contain_file('/tmp/siolib_file').with(
    :source => 'puppet:///modules/scaleio_openstack/openstack_version/siolib_file')}

  it { is_expected.to contain_package('python-pip').with_ensure('present')}
  it { is_expected.to contain_package('patch').with_ensure('present')}

  it { is_expected.to contain_exec('siolib').with(
    :command => 'pip install /tmp/siolib_file',
    :path    => '/bin:/usr/bin:/usr/local/bin')}

  it 'contains nova filter file' do
    is_expected.to contain_scaleio_openstack__scaleio_filter_file('nova filter file').with(
      :ensure            => 'ensure',
      :service           => 'nova',
      :openstack_version => 'openstack_version')

    is_expected.to contain_file('/etc/nova/rootwrap.d').with_ensure('directory')

    is_expected.to contain_scaleio_openstack__file_from_source('/etc/nova/rootwrap.d/scaleio.nova.filters').with(
      :ensure    => 'ensure',
      :dir       => '/etc/nova/rootwrap.d',
      :file_name => 'scaleio.nova.filters',
      :src_dir   => 'openstack_version')
    is_expected.to contain_file('/etc/nova/rootwrap.d/scaleio.nova.filters').with(
      :ensure => 'ensure',
      :source => 'puppet:///modules/scaleio_openstack/openstack_version/scaleio.nova.filters',
      :mode   => '0644',
      :owner  => 'root',
      :group  => 'root')
  end
  it { is_expected.to contain_file('Ensure directory has access: /bin/emc/scaleio').with(
    :ensure  => 'directory',
    :path    => '/bin/emc/scaleio',
    :recurse => true,
    :mode    => '0755')}

  it { is_expected.to contain_file('/tmp/nova_patch').with(
    :source => 'puppet:///modules/scaleio_openstack/openstack_version/nova/nova_patch')}

  it { is_expected.to contain_exec('nova patch').with(
    :onlyif  => 'test ensure = present && patch -p 2 -i /tmp/nova_patch -d  -b -f --dry-run',
    :command => 'patch -p 2 -i /tmp/nova_patch -d  -b',
    :path    => '/bin:/usr/bin')}
  it { is_expected.to contain_exec('nova un-patch').with(
    :onlyif  => 'test ensure = absent && patch -p 2 -i /tmp/nova_patch -d  -b -R -f --dry-run',
    :command => 'patch -p 2 -i /tmp/nova_patch -d  -b -R',
    :path    => '/bin:/usr/bin')}

  it 'contains ini_settings' do
    is_expected.to contain_ini_setting('scaleio_nova_compute_config force_config_drive').with(
      :section => 'DEFAULT',
      :setting => 'force_config_drive',
      :value   => 'False')
    is_expected.to contain_ini_setting('scaleio_nova_compute_config images_type').with(
      :section => 'libvirt',
      :setting => 'images_type',
      :value   => 'sio',)
    is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_ip').with(
      :section => 'scaleio',
      :setting => 'rest_server_ip',)
    is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_port').with(
      :section => 'scaleio',
      :setting => 'rest_server_port',)
    is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_username').with(
      :section => 'scaleio',
      :setting => 'rest_server_username',)
    is_expected.to contain_ini_setting('scaleio_nova_compute_config rest_server_password').with(
      :section => 'scaleio',
      :setting => 'rest_server_password',)
    is_expected.to contain_ini_setting('scaleio_nova_compute_config protection_domain_name').with(
      :section => 'scaleio',
      :setting => 'protection_domain_name',)
    is_expected.to contain_ini_setting('scaleio_nova_compute_config storage_pool_name').with(
      :section => 'scaleio',
      :setting => 'storage_pool_name',)
    is_expected.to contain_ini_setting('scaleio_nova_compute_config default_sdcguid').with(
      :section => 'scaleio',
      :setting => 'default_sdcguid',)
    is_expected.to contain_ini_setting('scaleio_nova_compute_config provisioning_type').with(
      :section => 'scaleio',
      :setting => 'provisioning_type',
      :value   => 'ThinProvisioned')
  end
end