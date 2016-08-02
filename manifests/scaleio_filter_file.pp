define scaleio_openstack::scaleio_filter_file(
  $ensure,
  $service,
  $openstack_version = undef,
)
{
  $file_name = "scaleio.${service}.filters"
  $dir = "/etc/${service}/rootwrap.d"
  $file_path = "${dir}/${file_name}"
  $src_dir = $openstack_version ? { undef => '.', default => $openstack_version }
  file { $dir:
    ensure  => directory,
  } ->
  scaleio_openstack::file_from_source { $file_path:
    ensure    => $ensure,
    dir       => $dir,
    file_name => $file_name,
    src_dir   => $src_dir,
  }
}

