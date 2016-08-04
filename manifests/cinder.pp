class scaleio_openstack::cinder (
  $ensure                     = present,    # could be present or absent
  $gateway_user               = 'admin',
  $gateway_password           = undef,
  $gateway_ip                 = undef,
  $gateway_port               = 4443,
  $protection_domains         = undef,
  $storage_pools              = undef,
  $verify_server_certificate  = 'False',
  $server_certificate_path    = undef,
  $round_volume_capacity      = 'True',
  $cinder_config_file         = '/etc/cinder/cinder.conf',  # file where cinder config parameters will be stored
  $scaleio_cinder_config_file = '/etc/cinder/cinder_scaleio.config',  # individual config file for versions under liberty
  $default_lvm_backend        = 'lvmdriver',
  $provisioning_type          = 'thick',  # string - thin | thick
)
{
  notify {'Configure Cinder to use ScaleIO cluster': }

  $cinder_volume_service = $::osfamily ? {
    'RedHat' => 'openstack-cinder-volume',
    'Debian' => 'cinder-volume',
  }

  if ! $::cinder_path {
    warning('Cinder is not installed on this node')
  }
  else {
    $domains = split($protection_domains,',')
    $pools = split($storage_pools,',')
    $pools_list = regsubst(join(flatten(zip($domains, $pools)), ':'), '(\w+):(\w+):', '\1:\2,', 'G')
    $enabled_backends = $ensure ? { 'absent' => $default_lvm_backend, default => 'scaleio' }
    $default_protection_domain = $domains[0]
    $default_storage_pool = $pools[0]

    $version_str = split($::cinder_version, '-')
    $version = $version_str[0]
    $version_array = split($version, '\.')

    package { ['patch']:
      ensure => present,
    } ->
    service { $cinder_volume_service:
      ensure => running
    }
    Ini_setting <| |> ~> Service[$cinder_volume_service]
    File <| |> ~> Service[$cinder_volume_service]
    Scaleio_openstack::File_from_source <| |> ~> Service[$cinder_volume_service]

    if $version_array[0] == '2014' and $version_array[1] == '2' {
      notify { "Detected cinder version ${version} - treat as Juno": }

      scaleio_openstack::file_from_source {'scaleio driver for cinder':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/drivers/emc",
        file_name => 'scaleio.py',
        src_dir   => 'juno/cinder'
      } ->

      scaleio_openstack::patch_common { 'patch juno cinder conf':
        ensure                     => $ensure,
        cinder_config_file         => $cinder_config_file,
        scaleio_cinder_config_file => $scaleio_cinder_config_file,
        provisioning_type          => $provisioning_type,
        cinder_volume_service      => $cinder_volume_service,
        enabled_backends           => $enabled_backends,
      }
    }
    elsif $version_array[0] == '2015' and $version_array[1] == '1' {
      notify { "Detected cinder version ${version} - treat as Kilo": }

      file { 'Ensure managers directory present: ':
        ensure => directory,
        path   => "${::cinder_path}/volume/managers",
        mode   => '0755',
      } ->
      file { 'Ensure emc directory present: ':
        ensure => directory,
        path   => "${::cinder_path}/volume/managers/emc",
        mode   => '0755',
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

      scaleio_openstack::patch_common { 'patch kilo cinder conf':
        ensure                     => $ensure,
        cinder_config_file         => $cinder_config_file,
        scaleio_cinder_config_file => $scaleio_cinder_config_file,
        provisioning_type          => $provisioning_type,
        cinder_volume_service      => $cinder_volume_service,
        enabled_backends           => $enabled_backends,
      }
    }
    elsif $version_array[0] == '7' or $version_array[0] == '8' {
      notify { "Detected cinder version ${version} - treat as Liberty/Mitaka": }

      $san_thin_provision = $provisioning_type ? {
        'thin'  => 'True',
        default => 'False'
      }
      $version_name = $version_array[0] ? {
        '7' => 'liberty',
        '8' => 'mitaka'
      }

      if $version_array[0] == '7' and $::os_brick_path {
        file { '/tmp/9e70f2c4.diff':
          source  => "puppet:///modules/scaleio_openstack/${version_name}/cinder/9e70f2c4.diff",
          require => Scaleio_openstack::File_from_source['scaleio driver for cinder']
        } ->
        exec { 'os-brick patch':
          onlyif  => "test ${ensure} = present && patch -p 2 -i /tmp/9e70f2c4.diff -d ${::os_brick_path} -b -f --dry-run",
          command => "patch -p 2 -i /tmp/9e70f2c4.diff -d ${::os_brick_path} -b",
          path    => '/bin:/usr/bin',
        } ->
        exec { 'os-brick un-patch':
          onlyif  => "test ${ensure} = absent && patch -p 2 -i /tmp/9e70f2c4.diff -d ${::os_brick_path} -b -R -f --dry-run",
          command => "patch -p 2 -i /tmp/9e70f2c4.diff -d ${::os_brick_path} -b -R",
          path    => '/bin:/usr/bin',
        }
      }

      scaleio_openstack::file_from_source {'scaleio driver for cinder':
        ensure    => $ensure,
        dir       => "${::cinder_path}/volume/drivers/emc",
        file_name => 'scaleio_ext.py',
        src_dir   => "${version_name}/cinder"
      } ->
      ini_setting { 'enabled_backends':
        path    => $cinder_config_file,
        section => 'DEFAULT',
        setting => 'enabled_backends',
        value   => $scaleio_openstack::cinder::enabled_backends,
      } ->
      ini_setting { 'san_thin_provision':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'san_thin_provision',
        value   => $san_thin_provision,
      } ->
      ini_setting { 'scaleio volume_driver':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'volume_driver',
        value   => 'cinder.volume.drivers.emc.scaleio_ext.ScaleIODriver',
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
      ini_setting { 'scaleio sio_server_certificate_path':
        path    => $cinder_config_file,
        section => 'scaleio',
        setting => 'sio_server_certificate_path',
        value   => $server_certificate_path,
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
      }
    }
    else {
      fail("Version ${version} isn't supported.")
    }
  }
}

define scaleio_openstack::patch_common(
  $ensure                     = present,    # could be present or absent
  $cinder_config_file         = undef,
  $scaleio_cinder_config_file = undef,
  $provisioning_type          = undef,
  $cinder_volume_service      = undef,
  $enabled_backends           = undef,
) {
  $scaleio_provisioning_type = $provisioning_type ? {
    'thin'  => 'ThinProvisioned',
    default => 'ThickProvisioned'
  }

  file { $scaleio_cinder_config_file:
    ensure  => $ensure,
    content => template('scaleio_openstack/cinder_scaleio.conf.erb'),
  } ->
  scaleio_openstack::scaleio_filter_file { 'cinder filter file':
    ensure  => $ensure,
    service => 'cinder',
    notify  => Service[$cinder_volume_service]
  } ->

  ini_setting { 'enabled_backends':
    path    => $cinder_config_file,
    section => 'DEFAULT',
    setting => 'enabled_backends',
    value   => $enabled_backends,
  } ->
  ini_setting { 'volume_driver':
    path    => $cinder_config_file,
    section => 'scaleio',
    setting => 'volume_driver',
    value   => 'cinder.volume.drivers.emc.scaleio.ScaleIODriver',
  } ->
  ini_setting { 'cinder_scaleio_config_file':
    path    => $cinder_config_file,
    section => 'scaleio',
    setting => 'cinder_scaleio_config_file',
    value   => $scaleio_cinder_config_file,
  } ->
  ini_setting { 'volume_backend_name':
    path    => $cinder_config_file,
    section => 'scaleio',
    setting => 'volume_backend_name',
    value   => 'scaleio',
  }
}

