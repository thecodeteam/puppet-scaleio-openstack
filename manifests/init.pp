class scaleio_openstack
{
  File {
      mode  => '0644',
      owner => 'root',
      group => 'root',
  }
    
  Exec {
    path    => ['/usr/bin', '/bin'],
  }

  define scaleio_filter_file(
    $ensure,
    $service    = $name,
    $path       = "/usr/share/${service}/rootwrap",
    $file_name  = 'scaleio.filters',
  )
  {
    file { "${path}/${file_name}":
      ensure => $ensure,
      source => "puppet:///files/${file_name}",
    } ->
    ini_subsetting { "Ensure rootwrap path is in ${service} config":
      ensure               => present,
      path                 => "/etc/${service}/rootwrap.conf",
      section              => 'DEFAULT',
      setting              => 'filters_path',
      subsetting           => "${path}",
      subsetting_separator => ',',
    }    
  }
   
} # class scaleio
