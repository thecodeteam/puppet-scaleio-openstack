define scaleio_openstack::file_from_source(
  $ensure,
  $dir,
  $file_name,
  $src_dir,
  $dst_file_name  = $file_name,
  $mode           = '0644',
  $owner          = 'root',
  $group          = 'root',
)
{
  file { "${dir}/${dst_file_name}":
    ensure => $ensure,
    source => "puppet:///modules/scaleio_openstack/${src_dir}/${file_name}",
    mode   => $mode,
    owner  => $owner,
    group  => $group,
  }
}
