
class scaleio_openstack::cinder (
  $ensure                     = present,    # could be present or absent
  $gateway_user               = undef,
  $gateway_password           = undef,
  $gateway_ip                 = undef,
  $gateway_port               = 4443,
  $protection_domains         = undef,
  $storage_pools              = undef,
  $verify_server_certeficate  = 'False',
  $force_delete               = 'True',
  $round_volume_capacity      = 'True',
  $scaleio_cinder_config_file = '/etc/cinder/cinder_scaleio.config',
  $scaleio_filter_file_path   = '/usr/share/cinder/rootwrap',
  $default_lvm_backend        = 'lvmdriver',
)
{
    notify {'Configure Cinder to use ScaleIO cluster': }

    $services_to_notify = [
      $cinder::params::api_service,
      $cinder::params::scheduler_service,
      $cinder::params::volume_service,
    ]    

    # TODO: refactory to remove dublication with the code from volume_type.pp
    $pools_list = regsubst(join(flatten(zip($protection_domains, $storage_pools)), ':'), '(\w+):(\w+):', '\1:\2,', 'G') 

    File {
      mode  => '0644',
      owner => 'root',
      group => 'root',
    }

    file {$scaleio_cinder_config_file:
      ensure  => $ensure,
      path    => $scaleio_cinder_config_file,
      content => template('cinder_scaleio.conf.erb'),
    } ->
    
    file {'scaleio.py':
      ensure => $ensure,
      path   => "${::cinder_path}/volume/drivers/emc/scaleio.py",
      source => 'puppet:///files/scaleio.py',
    } ->
  
    file {'scaleio.filters':
      ensure => $ensure,
      path   => "${scaleio_filter_file_path}/scaleio.filters",
      source => 'puppet:///files/scaleio.filters',
    } ->
    
    ini_subsetting {'Ensure rootwrap path is in cinder config':
      ensure               => present,
      path                 => '/etc/cinder/rootwrap.conf',
      section              => 'DEFAULT',
      setting              => 'filters_path',
      subsetting           => "${scaleio_filter_file_path}",
    } ->
    
    cinder_config {
      'DEFAULT/enabled_backends':           value => $ensure ? { absent  => $default_lvm_backend, default => 'ScaleIO', };
      'ScaleIO/volume_driver':              value => 'cinder.volume.drivers.emc.scaleio.ScaleIODriver', ensure => $ensure;
      'ScaleIO/cinder_scaleio_config_file': value => $scaleio_cinder_config_file, ensure => $ensure;
      'ScaleIO/volume_backend_name':        value => 'ScaleIO', ensure => $ensure;
    } ~>
    
    service { $services_to_notify:
      ensure => running,
    }            
 
} # class scaleio::cinder
