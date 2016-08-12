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