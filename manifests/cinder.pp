
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
  $default_lvm_backend        = 'lvmdriver',
)
{
    notify {'Configure Cinder to use ScaleIO cluster': }

    include cinder::params
    
    $services_to_notify = [
      $cinder::params::api_service,
      $cinder::params::scheduler_service,
      $cinder::params::volume_service,
    ]

    # TODO: refactory to remove dublication with the code from volume_type.pp
    $pools_list = regsubst(join(flatten(zip($protection_domains, $storage_pools)), ':'), '(\w+):(\w+):', '\1:\2,', 'G')

    if ! $::cinder_path {
      fail('Cinder is not installed on this node')
    }

    $enabled_backends = $ensure ? { absent  => $default_lvm_backend, default => 'ScaleIO'}

    file { $scaleio_cinder_config_file:
      ensure  => $ensure,
      content => template('scaleio_openstack/cinder_scaleio.conf.erb'),
    } ->
      
    file_from_source {'scaleio.py':
      path => "${::cinder_path}/volume/drivers/emc",
    } ->
    
    scaleio_filter_file { 'cinder':
      ensure => $ensure,
    } ->
    
    cinder_config {
      'DEFAULT/enabled_backends':           value => $enabled_backends;
      'ScaleIO/volume_driver':              ensure => $ensure, value => 'cinder.volume.drivers.emc.scaleio.ScaleIODriver';
      'ScaleIO/cinder_scaleio_config_file': ensure => $ensure, value => $scaleio_cinder_config_file;
      'ScaleIO/volume_backend_name':        ensure => $ensure, value => 'ScaleIO';
    } ~>
    
    service { $services_to_notify:
      ensure => running,
    }
} # class scaleio::cinder

