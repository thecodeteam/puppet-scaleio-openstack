
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
    $domains = split($protection_domains,',')
    $pools = split($storage_pools,',')
    $pools_list = regsubst(join(flatten(zip($domains, $pools)), ':'), '(\w+):(\w+):', '\1:\2,', 'G')
    $enabled_backends = $ensure ? { absent  => $default_lvm_backend, default => 'ScaleIO'}

    $version = $::cinder_version
    if versioncmp($version, '2014.2.0') < 0 {
      fail("Version $version too small and isn't supported.")
    }
    elsif versioncmp($version, '2015.1.0') < 0 {
      notify { "Detected cinder version $version - treat as Juno":; }


      $default_protection_domain = $domains[0]
      $default_storage_pool = $pools[0]
      file { $scaleio_cinder_config_file:
        ensure  => $ensure,
        content => template('scaleio_openstack/cinder_scaleio.conf.erb'),
      } ->

      # --- Juno specific start
      file_from_source {'scaleio driver for cinder':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/drivers/emc",
        file_name => 'scaleio.py',
        src_dir   => 'juno/cinder'
      } ->
      # --- Juno specific start

      scaleio_filter_file { 'cinder filter file':
        ensure  => $ensure,
        service => 'cinder'
      } ->

      file { "Ensure directory has access: /bin/emc/scaleio":
        ensure  => directory,
        path    => '/bin/emc/scaleio',
        recurse => true,
        mode  => '0755',
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
    elsif versioncmp($version, '2015.2.0') < 0 {
      notify { "Detected cinder version $version - treat as Kilo":; }


      $default_protection_domain = $domains[0]
      $default_storage_pool = $pools[0]
      file { $scaleio_cinder_config_file:
        ensure  => $ensure,
        content => template('scaleio_openstack/cinder_scaleio.conf.erb'),
      } ->

      # --- Kilo specific start
      file { "Ensure directory present: ":
        ensure  => directory,
        path    => '${::cinder_path}/volume/managers/emc',
        recurse => true,
        mode    => '0755',
      } ->
      file_from_source {'scaleio driver for cinder file 001':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/managers",
        file_name => '__init__.py',
        src_dir   => 'kilo/cinder'
      } ->
      file_from_source {'scaleio driver for cinder file 002':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/managers/emc",
        file_name => '__init__.py',
        src_dir   => 'kilo/cinder'
      } ->
      file_from_source {'scaleio driver for cinder file 003':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/managers/emc",
        file_name => 'manager.py',
        src_dir   => 'kilo/cinder'
      } ->
      file_from_source {'scaleio driver for cinder file 004':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/drivers/emc",
        file_name => 'os_brick.py',
        src_dir   => 'kilo/cinder'
      } ->
      file_from_source {'scaleio driver for cinder file 005':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/drivers/emc",
        file_name => 'scaleio.py',
        src_dir   => 'kilo/cinder'
      } ->
      file_from_source {'scaleio driver for cinder file 006':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/drivers/emc",
        file_name => 'swift_client.py',
        src_dir   => 'kilo/cinder'
      } ->
      # --- Kilo specific start

      scaleio_filter_file { 'cinder filter file':
        ensure  => $ensure,
        service => 'cinder'
      } ->

      file { "Ensure directory has access: /bin/emc/scaleio":
        ensure  => directory,
        path    => '/bin/emc/scaleio',
        recurse => true,
        mode  => '0755',
      } ->
      # --- Kilo specific start
      ini_setting { 'enabled_backends':
        path    => '/etc/cinder/cinder.conf',
        section => 'DEFAULT',
        setting => 'volume_manager',
        value   => 'cinder.volume.managers.emc.manager.EMCVolumeManager',
      } ->
      # --- Kilo specific end
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
    else {
      fail("Version $version too high and isn't supported.")
    }


  }
} # class scaleio::cinder

