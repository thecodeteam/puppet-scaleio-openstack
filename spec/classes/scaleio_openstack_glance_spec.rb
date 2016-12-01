require 'spec_helper'

describe 'scaleio_openstack::glance', :type => :class  do
  let(:default_facts) {{
    :osfamily => 'Debian'
  }}

  it { is_expected.to contain_class('scaleio_openstack::glance').with_ensure('present')}
  it { is_expected.to contain_notify('Configure Glance to use ScaleIO cluster via Cinder')}

  context 'when no glance_path' do
    let :facts do
      default_facts.merge(
        :glance_path => '')
    end
    it { should_not contain_scaleio_openstack__scaleio_filter_file('glance filter file')}
  end

  context 'when glance_path on version >= 12' do
    let :facts do
      default_facts.merge(
        :glance_path => '/glance/path',
        :glance_version => '12.4.4')
    end

    it { is_expected.to contain_notify("Detected glance version 12.4.4")}

    it { is_expected.to contain_package('python-cinderclient').with_ensure('present')}
    it { is_expected.to contain_package('python-os-brick').with_ensure('present')}
    it { is_expected.to contain_package('python-oslo.rootwrap').with_ensure('present')}

    it 'contains glance filter file' do
      is_expected.to contain_scaleio_openstack__scaleio_filter_file('glance filter file').with(
        :ensure  => 'present',
        :service => 'glance',)
      is_expected.to contain_file('/etc/glance/rootwrap.d').with_ensure('directory')
      is_expected.to contain_scaleio_openstack__file_from_source('/etc/glance/rootwrap.d/scaleio.glance.filters').with(
        :ensure    => 'present',
        :dir       => '/etc/glance/rootwrap.d',
        :file_name => 'scaleio.glance.filters',
        :src_dir   => '.')
      is_expected.to contain_file('/etc/glance/rootwrap.d/scaleio.glance.filters').with(
        :ensure => 'present',
        :source => "puppet:///modules/scaleio_openstack/./scaleio.glance.filters",
        :mode   => '0644',
        :owner  => 'root',
        :group  => 'root')
    end

    it 'contains glance files' do
      is_expected.to contain_scaleio_openstack__file_from_source('glance_rootwrap').with(
        :ensure        => 'present',
        :dir           => '/etc/glance',
        :file_name     => 'glance_rootwrap.conf',
        :src_dir       => '.',
        :dst_file_name => 'rootwrap.conf')
      is_expected.to contain_file('/etc/glance/rootwrap.conf').with(
        :ensure => 'present',
        :source => 'puppet:///modules/scaleio_openstack/./glance_rootwrap.conf',
        :mode   => '0644',
        :owner  => 'root',
        :group  => 'root')
      is_expected.to contain_scaleio_openstack__file_from_source('glance_sudoers').with(
        :ensure    => 'present',
        :dir       => '/etc/sudoers.d',
        :file_name => 'glance_sudoers',
        :src_dir   => '.')
      is_expected.to contain_file('/etc/sudoers.d/glance_sudoers').with(
        :ensure => 'present',
        :source => 'puppet:///modules/scaleio_openstack/./glance_sudoers',
        :mode   => '0644',
        :owner  => 'root',
        :group  => 'root')
    end

    it 'contains glance config files' do
      is_expected.to contain_scaleio_openstack__glance_config("glance config: /etc/glance/glance-api.conf").with(
        :config_file   => '/etc/glance/glance-api.conf',
        :cinder_region => 'RegionOne',
        :require       => 'Scaleio_openstack::File_from_source[glance_sudoers]')
      is_expected.to contain_ini_subsetting('/etc/glance/glance-api.conf: stores').with(
        :ensure               => 'present',
        :path                 => '/etc/glance/glance-api.conf',
        :section              => 'glance_store',
        :setting              => 'stores',
        :subsetting           => 'glance.store.cinder.Store',
        :subsetting_separator => ',')
      is_expected.to contain_ini_setting('/etc/glance/glance-api.conf: default_store').with(
        :ensure  => 'present',
        :path    => '/etc/glance/glance-api.conf',
        :section => 'glance_store',
        :setting => 'default_store',
        :value   => 'cinder')
      is_expected.to contain_ini_setting('/etc/glance/glance-api.conf: cinder_os_region_name').with(
        :ensure  => 'present',
        :path    => '/etc/glance/glance-api.conf',
        :section => 'glance_store',
        :setting => 'cinder_os_region_name',
        :value   => 'RegionOne')

      is_expected.to contain_scaleio_openstack__glance_config("glare config: /etc/glance/glance-glare.conf").with(
        :config_file   => '/etc/glance/glance-glare.conf',
        :cinder_region => 'RegionOne')
      is_expected.to contain_ini_subsetting('/etc/glance/glance-glare.conf: stores').with(
        :ensure               => 'present',
        :path                 => '/etc/glance/glance-glare.conf',
        :section              => 'glance_store',
        :setting              => 'stores',
        :subsetting           => 'glance.store.cinder.Store',
        :subsetting_separator => ',')
      is_expected.to contain_ini_setting('/etc/glance/glance-glare.conf: default_store').with(
        :ensure  => 'present',
        :path    => '/etc/glance/glance-glare.conf',
        :section => 'glance_store',
        :setting => 'default_store',
        :value   => 'cinder')
      is_expected.to contain_ini_setting('/etc/glance/glance-glare.conf: cinder_os_region_name').with(
        :ensure  => 'present',
        :path    => '/etc/glance/glance-glare.conf',
        :section => 'glance_store',
        :setting => 'cinder_os_region_name',
        :value   => 'RegionOne')

      is_expected.to contain_service('glance-api').with(
        :ensure => 'running',
        :enable => 'true')
      is_expected.to contain_service('glance-glare').with(
        :ensure => 'running',
        :enable => 'true')
      is_expected.to contain_service('glance-registry').with(
        :ensure => 'running',
        :enable => 'true')

    end
  end

  context 'when glance_path on version < 12' do
    let :facts do
      default_facts.merge(
        :glance_path => '/glance/path',
        :glance_version => '11.1.1')
    end

    it { should raise_error(Puppet::Error, /Version 11.1.1 of python-glance isn't supported./)}
 end
end