require 'spec_helper'

describe 'scaleio_openstack::scaleio_filter_file' do

  let (:title) {'title'}
  let (:params) {{
    :ensure => 'ensure',
    :service    => 'service',
    :openstack_version => 'openstack_version'}}

  it { is_expected.to contain_scaleio_openstack__scaleio_filter_file(title) }

  it { is_expected.to contain_file('/etc/service/rootwrap.d').with_ensure('directory')}

  it { is_expected.to contain_scaleio_openstack__file_from_source('/etc/service/rootwrap.d/scaleio.service.filters').with(
    :ensure    => 'ensure',
    :dir       => '/etc/service/rootwrap.d',
    :file_name => 'scaleio.service.filters',
    :src_dir   => 'openstack_version')}
  it { is_expected.to contain_file('/etc/service/rootwrap.d/scaleio.service.filters').with(
    :ensure => 'ensure',
    :source => 'puppet:///modules/scaleio_openstack/openstack_version/scaleio.service.filters',
    :mode   => '0644',
    :owner  => 'root',
    :group  => 'root')}
end
