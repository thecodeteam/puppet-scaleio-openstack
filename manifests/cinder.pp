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
  $cinder_config_file         = '/etc/cinder/cinder.conf',  # file where cinder config parameters will be stored
  $scaleio_cinder_config_file = '/etc/cinder/cinder_scaleio.config',  # individual config file for versions under liberty
  $default_lvm_backend        = 'lvmdriver',
)
{
  notify {'Configure Cinder to use ScaleIO cluster': }

  $services_to_notify = [
    'cinder-volume',
  ]

  if ! $::cinder_path {
    warning('Cinder is not installed on this node')
  }
  else {
    $domains = split($protection_domains,',')
    $pools = split($storage_pools,',')
    $pools_list = regsubst(join(flatten(zip($domains, $pools)), ':'), '(\w+):(\w+):', '\1:\2,', 'G')
    $enabled_backends = $ensure ? { absent  => $default_lvm_backend, default => 'scaleio' }
    $default_protection_domain = $domains[0]
    $default_storage_pool = $pools[0]

    $version_str = split($::cinder_version, '-')
    $version = $version_str[0]
    $version_array = split($version, '\.')

    if $version_array[0] == '2014' and $version_array[1] == '2' {
      notify { "Detected cinder version $version - treat as Juno": }

      file { "Ensure directory has access: /bin/emc/scaleio":
        ensure  => directory,
        path    => '/bin/emc/scaleio',
        recurse => true,
        mode  => '0755',
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for cinder':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/drivers/emc",
        file_name => 'scaleio.py',
        src_dir   => 'juno/cinder'
      } ->

      patch_common { 'patch juno cinder conf': } ~>
      service { $services_to_notify:
        ensure => running,
      }
    }
    elsif $version_array[0] == '2015' and $version_array[1] == '1' {
      notify { "Detected cinder version $version - treat as Kilo": }

      file { "Ensure directory has access: /bin/emc/scaleio":
        ensure  => directory,
        path    => '/bin/emc/scaleio',
        recurse => true,
        mode  => '0755',
      } ->
      file { "Ensure managers directory present: ":
        ensure  => directory,
        path    => "${::cinder_path}/volume/managers",
        mode    => '0755',
      } ->
      file { "Ensure emc directory present: ":
        ensure  => directory,
        path    => "${::cinder_path}/volume/managers/emc",
        mode    => '0755',
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for cinder file 001':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/managers",
        file_name => '__init__.py',
        src_dir   => 'kilo/cinder'
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for cinder file 002':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/managers/emc",
        file_name => '__init__.py',
        src_dir   => 'kilo/cinder'
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for cinder file 003':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/managers/emc",
        file_name => 'manager.py',
        src_dir   => 'kilo/cinder'
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for cinder file 004':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/drivers/emc",
        file_name => 'os_brick.py',
        src_dir   => 'kilo/cinder'
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for cinder file 005':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/drivers/emc",
        file_name => 'scaleio.py',
        src_dir   => 'kilo/cinder'
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for cinder file 006':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/drivers/emc",
        file_name => 'swift_client.py',
        src_dir   => 'kilo/cinder'
      } ->
      ini_setting { 'change_volume_manager':
        ensure  => $ensure,
        path    => $cinder_config_file,
        section => 'DEFAULT',
        setting => 'volume_manager',
        value   => 'cinder.volume.managers.emc.manager.EMCVolumeManager',
      } ->

      patch_common { 'patch kilo cinder': } ~>
      service { $services_to_notify:
        ensure => running,
      }
    }
    elsif $version_array[0] == '7' or $version_array[0] == '8' {
      notify { "Detected cinder version $version - treat as Liberty": }

      file { "Ensure directory has access: /bin/emc/scaleio":
        ensure  => directory,
        path    => '/bin/emc/scaleio',
        recurse => true,
        mode  => '0755',
      } ->
      ini_setting { 'enabled_backends':
        path    => $cinder_config_file,
        section => 'DEFAULT',
        setting => 'enabled_backends',
        value   => $scaleio_openstack::cinder::enabled_backends,
      } ->
      ini_setting { 'default_volume_type':
        ensure  => $ensure,
        path    => $cinder_config_file,
        section => 'DEFAULT',
        setting => 'default_volume_type',
        value   => 'scaleio',
      } ->
      ini_setting { 'scaleio volume_driver':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'volume_driver',
        value   => 'cinder.volume.drivers.emc.scaleio.ScaleIODriver',
      } ->
      ini_setting { 'scaleio volume_backend_name':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'volume_backend_name',
        value   => 'scaleio',
      } ->
      ini_setting { 'scaleio sio_round_volume_capacity':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'sio_round_volume_capacity',
        value   => $round_volume_capacity,
      } ->
      ini_setting { 'scaleio sio_verify_server_certificate':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'sio_verify_server_certificate',
        value   => $verify_server_certificate,
      } ->
      ini_setting { 'scaleio sio_force_delete':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'sio_force_delete',
        value   => $force_delete,
      } ->
      ini_setting { 'scaleio sio_unmap_volume_before_deletion':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'sio_unmap_volume_before_deletion',
        value   => 'True',
      } ->
      ini_setting { 'scaleio san_ip':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'san_ip',
        value   => $gateway_ip,
      } ->
      ini_setting { 'scaleio sio_rest_server_port':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'sio_rest_server_port',
        value   => $gateway_port,
      } ->
      ini_setting { 'scaleio san_login':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'san_login',
        value   => $gateway_user,
      } ->
      ini_setting { 'scaleio san_password':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'san_password',
        value   => $gateway_password,
      } ->
      ini_setting { 'scaleio sio_protection_domain_name':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'sio_protection_domain_name',
        value   => $default_protection_domain,
      } ->
      ini_setting { 'scaleio sio_storage_pools':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'sio_storage_pools',
        value   => $pools_list,
      } ->
      ini_setting { 'scaleio sio_storage_pool_name':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'sio_storage_pool_name',
        value   => $default_storage_pool,
      } ~>

      service { $services_to_notify:
        ensure => running,
      }
    }
    else {
      fail("Version ${version} isn't supported.")
    }
  }

  define patch_common {
    file { $scaleio_openstack::cinder::scaleio_cinder_config_file:
      ensure  =>  $scaleio_openstack::cinder::ensure,
      content => template('scaleio_openstack/cinder_scaleio.conf.erb'),
    } ->
    scaleio_openstack::scaleio_filter_file { 'cinder filter file':
      ensure  => $scaleio_openstack::cinder::ensure,
      service => 'cinder'
    } ->

    ini_setting { 'enabled_backends':
      path    => $scaleio_openstack::cinder::cinder_config_file,
      section => 'DEFAULT',
      setting => 'enabled_backends',
      value   => $scaleio_openstack::cinder::enabled_backends,
    } ->
    ini_setting { 'volume_driver':
      path    => $scaleio_openstack::cinder::cinder_config_file,
      section => 'scaleio',
      setting => 'volume_driver',
      value   => 'cinder.volume.drivers.emc.scaleio.ScaleIODriver',
    } ->
    ini_setting { 'cinder_scaleio_config_file':
      path    => $scaleio_openstack::cinder::cinder_config_file,
      section => 'scaleio',
      setting => 'cinder_scaleio_config_file',
      value   => $scaleio_openstack::cinder::scaleio_cinder_config_file,
    } ->
    ini_setting { 'volume_backend_name':
      path    => $scaleio_openstack::cinder::cinder_config_file,
      section => 'scaleio',
      setting => 'volume_backend_name',
      value   => 'scaleio',
    }
  }
} # class scaleio::cinder

