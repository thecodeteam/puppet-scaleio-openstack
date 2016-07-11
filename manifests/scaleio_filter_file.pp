define scaleio_openstack::scaleio_filter_file(
  $ensure,
  $service,
  $openstack_version = undef,
)
{
  $file_name = "scaleio.${service}.filters"
  $dir = "/usr/share/${service}/rootwrap"
  $file_path = "${dir}/${file_name}"
  $src_dir = $openstack_version ? { undef => '.', default => $openstack_version }
  # workarround because puppet cant create recursively
  file { ["/usr/share", "/usr/share/${service}", "/usr/share/${service}/rootwrap"]:
    ensure  => directory,
  } ->
  scaleio_openstack::file_from_source { $file_path:
    ensure    => $ensure,
    dir       => $dir,
    file_name => $file_name,
    src_dir   => $src_dir,
  }

  ini_subsetting { "Ensure rootwrap path is in ${service} config":
    ensure               => present,
    path                 => "/etc/${service}/rootwrap.conf",
    section              => 'DEFAULT',
    setting              => 'filters_path',
    subsetting           => $file_path,
    subsetting_separator => ',',
  }
}

