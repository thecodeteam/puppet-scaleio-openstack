class scaleio_openstack
{
  define file_from_source(
    $ensure,
    $path,
    $file_name = $name,
  )
  {
    File {
      mode  => '0644',
      owner => 'root',
      group => 'root',
    }

    file { "Ensure directory ${path}":
      ensure  => directory,
      path    => $path,
      recurse => true,
    } ->

    file { "${path}/${file_name}":
      ensure => $ensure,
      source => "puppet:///modules/scaleio_openstack/${file_name}",
    }
  }

  define scaleio_filter_file(
    $ensure,
    $service    = $name,
    $path       = "/usr/share/${service}/rootwrap",
    $file_name  = 'scaleio.filters',
  )
  {

    file_from_source {"${path}/${file_name}":
      ensure => $ensure,
      path => $path,
      file_name => $file_name,
    }

    ini_subsetting { "Ensure rootwrap path is in ${service} config":
      ensure               => present,
      path                 => "/etc/${service}/rootwrap.conf",
      section              => 'DEFAULT',
      setting              => 'filters_path',
      subsetting           => $path,
      subsetting_separator => ',',
    }
  }
} # class scaleio

