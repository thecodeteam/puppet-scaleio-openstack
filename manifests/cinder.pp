
class scaleio_openstack::cinder (
  $ensure                     = present,    # could be present or absent
  $gateway_user               = 'admin',
  $gateway_password           = undef,
  $gateway_ip                 = undef,
  $gateway_port               = 4443,
  $protection_domains         = undef,
  $storage_pools              = undef,
  $verify_server_certificate  = 'False',
  $force_delete               = 'True',
  $round_volume_capacity      = 'True',
  $scaleio_cinder_config_file = '/etc/cinder/cinder_scaleio.config',
  $default_lvm_backend        = 'lvmdriver',
)
{
  notify {'Configure Cinder to use ScaleIO cluster': }

  $services_to_notify = [
    'cinder-api',
    'cinder-scheduler',
    'cinder-volume',
  ]

  if ! $::cinder_path {
    warning('Cinder is not installed on this node')
  }
  else {
    $pools_list = regsubst(join(flatten(zip(split($protection_domains), split($storage_pools))), ':'), '(\w+):(\w+):', '\1:\2,', 'G')
    $enabled_backends = $ensure ? { absent  => $default_lvm_backend, default => 'ScaleIO'}

    file { $scaleio_cinder_config_file:
      ensure  => $ensure,
      content => template('scaleio_openstack/cinder_scaleio.conf.erb'),
    } ->

    file_from_source {'scaleio.py':
      ensure  => $ensure,
      path => "${::cinder_path}/volume/drivers/emc",
    } ->

    scaleio_filter_file { 'cinder':
      ensure => $ensure,
    } ->

    ini_setting { 'enabled_backends':
      path    => '/etc/cinder/cinder.conf',
      section => 'DEFAULT',
      setting => 'enabled_backends',
      value   => $enabled_backends,
    } ->
    ini_setting { 'volume_driver':
      path    => '/etc/cinder/cinder.conf',
      section => 'ScaleIO',
      setting => 'volume_driver',
      value   => 'cinder.volume.drivers.emc.scaleio.ScaleIODriver',
    } ->
    ini_setting { 'cinder_scaleio_config_file':
      path    => '/etc/cinder/cinder.conf',
      section => 'ScaleIO',
      setting => 'cinder_scaleio_config_file',
      value   => $scaleio_cinder_config_file,
    } ->
    ini_setting { 'volume_backend_name':
      path    => '/etc/cinder/cinder.conf',
      section => 'ScaleIO',
      setting => 'volume_backend_name',
      value   => 'ScaleIO',
    } ~>

    service { $services_to_notify:
      ensure => running,
    }
  }
} # class scaleio::cinder

