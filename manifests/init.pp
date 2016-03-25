class scaleio_openstack
{
  define file_from_source(
    $ensure,
    $dir,
    $file_name,
    $src_dir,
  )
  {
    file { "${dir}/${file_name}":
      ensure => $ensure,
      source => "puppet:///modules/scaleio_openstack/${src_dir}/${file_name}",
      mode  => '0644',
      owner => 'root',
      group => 'root',
    }
  }

  define scaleio_filter_file(
    $ensure,
    $service,
  )
  {
    $file_name = "scaleio.${service}.filters"
    $dir = "/usr/share/${service}/rootwrap"
    $file_path = "${dir}/${file_name}"
    # workarround because puppet cant create recursively
    file { ["/usr/share", "/usr/share/${service}", "/usr/share/${service}/rootwrap"]:
      ensure  => directory,
    } ->

    file_from_source {$file_path:
      ensure    => $ensure,
      dir       => $dir,
      file_name => $file_name,
      src_dir   => '.'
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
} # class scaleio

