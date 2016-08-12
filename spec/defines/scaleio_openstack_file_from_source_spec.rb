require 'spec_helper'

describe 'scaleio_openstack::file_from_source' do

  let (:title) {'title'}
  let (:params) {{
    :ensure => 'present',
    :dir    => '/some/dir',
    :file_name => 'file_name',
    :src_dir   => 'src/dir' }}

  it { is_expected.to contain_scaleio_openstack__file_from_source(title) }

  it { is_expected.to contain_file('/some/dir/file_name').with(
    :ensure => 'present',
    :source => 'puppet:///modules/scaleio_openstack/src/dir/file_name',
    :mode   => '0644',
    :owner  => 'root',
    :group  => 'root')}
end