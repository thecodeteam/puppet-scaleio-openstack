class scaleio_openstack::nova(
  $ensure              = present,
  $gateway_user        = admin,
  $gateway_password    = undef,
  $gateway_ip          = undef,
  $gateway_port        = 4443,
  $protection_domains  = undef,
  $storage_pools       = undef,
  $provisioning_type   = 'thick',
  $nova_config_file    = '/etc/nova/nova.conf',  # file where nova config parameters will be stored
)
{
  notify {'Configuring Compute node for ScaleIO integration': }

  $nova_compute_service = $::osfamily ? {
    'RedHat' => 'openstack-nova-compute',
    'Debian' => 'nova-compute',
  }

  if ! $::nova_path {
    warning('Nova is not installed on this node')
  }
  else {

    service { $nova_compute_service:
      ensure => running,
    }
    Ini_setting <| |> ~> Service[$nova_compute_service]
    Ini_subsetting <| |> ~> Service[$nova_compute_service]
    File <| |> ~> Service[$nova_compute_service]
    Scaleio_openstack::File_from_source <| |> ~> Service[$nova_compute_service]
    Scaleio_openstack::Nova_common <| |> ~> Service[$nova_compute_service]

    $version_str = split($::nova_version, '-')
    $core_version = $version_str[0]

    $custom_canonical_version_str = split($version_str[1], 'cloud')
    $custom_mos_version_str = split($version_str[1], 'mos')
    if count($custom_mos_version_str) > 1 {
      # Array of custom MOS versions, if a version is not in the array default patch will be applied,
      # in case of new custom mos patch it is needed to add its version into this table.
      $custom_mos_versions = [
        '30', '31', '46', '48',                               # mos6.1
        '19662', '19676', '19695', '19696', '19698', '19701', # mos7.0 (for 2015.1.1 but copy of 2015.1.3.diff)
        '43', '21', '10',                                     # mos8
        '43', '20',                                           # mos9
      ]

      $custom_mos_version = $custom_mos_version_str[1]
      if $custom_mos_version in $custom_mos_versions {
        $version = "${core_version}-mos${custom_mos_version}"
      } else {
        $version = $core_version
      }
    }
    elsif count($custom_canonical_version_str) > 1 {
      $custom_canonical_versions = {
        '12.0.4' => ['1']
      }

      $custom_canonical_version = $custom_canonical_version_str[1]
      if $core_version in $custom_canonical_versions and $custom_canonical_version in $custom_canonical_versions[$core_version] {
        $version = "${core_version}-cloud${custom_canonical_version}"
      } else {
        $version = $core_version
      }
    }
    else {
      $version = $core_version
    }

    notify { "Detected nova version: ${version}": }
    if $core_version in ['12.0.0', '12.0.1', '12.0.2', '12.0.3', '12.0.4', '12.0.5'] {
      notify { "Detected nova version ${version} - treat as Liberty": }

      scaleio_openstack::nova_common { 'nova common for Liberty':
        ensure             => $ensure,
        gateway_user       => $gateway_user,
        gateway_password   => $gateway_password,
        gateway_ip         => $gateway_ip,
        gateway_port       => $gateway_port,
        protection_domains => $protection_domains,
        storage_pools      => $storage_pools,
        provisioning_type  => $provisioning_type,
        openstack_version  => 'liberty',
        siolib_file        => 'siolib-1.4.5.tar.gz',
        nova_patch         => "${version}.diff",
        nova_config_file   => $nova_config_file,
      }
    }
    elsif $core_version in ['13.0.0', '13.1.0', '13.1.1', '13.1.2'] {
      notify { "Detected nova version ${version} - treat as Mitaka": }

      scaleio_openstack::nova_common { 'nova common for Mitaka':
        ensure             => $ensure,
        gateway_user       => $gateway_user,
        gateway_password   => $gateway_password,
        gateway_ip         => $gateway_ip,
        gateway_port       => $gateway_port,
        protection_domains => $protection_domains,
        storage_pools      => $storage_pools,
        provisioning_type  => $provisioning_type,
        openstack_version  => 'mitaka',
        siolib_file        => 'siolib-1.5.5.tar.gz',
        nova_patch         => "${version}.diff",
        nova_config_file   => $nova_config_file,
      }
    }
    elsif $core_version in ['14.0.1', '14.0.2'] {
      notify { "Detected nova version ${version} - treat as Newton": }

      scaleio_openstack::nova_common { 'nova common for Newton':
        ensure             => $ensure,
        gateway_user       => $gateway_user,
        gateway_password   => $gateway_password,
        gateway_ip         => $gateway_ip,
        gateway_port       => $gateway_port,
        protection_domains => $protection_domains,
        storage_pools      => $storage_pools,
        provisioning_type  => $provisioning_type,
        openstack_version  => 'newton',
        siolib_file        => 'siolib-1.6.5.tar.gz',
        nova_patch         => "${version}.diff",
        nova_config_file   => $nova_config_file,
      }
    }
    elsif $core_version in ['2015.1.1', '2015.1.2', '2015.1.3', '2015.1.4']  {
      notify { "Detected nova version ${version} - treat as Kilo": }

      scaleio_openstack::nova_common { 'nova common for Kilo':
        ensure             => $ensure,
        gateway_user       => $gateway_user,
        gateway_password   => $gateway_password,
        gateway_ip         => $gateway_ip,
        gateway_port       => $gateway_port,
        protection_domains => $protection_domains,
        storage_pools      => $storage_pools,
        provisioning_type  => $provisioning_type,
        openstack_version  => 'kilo',
        siolib_file        => 'siolib-1.3.5.tar.gz',
        nova_patch         => "${version}.diff",
        nova_config_file   => $nova_config_file,
      } ->

      file { ["${::nova_path}/virt/libvirt/drivers", "${::nova_path}/virt/libvirt/drivers/emc"]:
        ensure => directory,
        mode   => '0755',
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for nova file 001':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt/drivers",
        file_name => '__init__.py',
        src_dir   => 'kilo/nova'
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for nova file 002':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt/drivers/emc",
        file_name => '__init__.py',
        src_dir   => 'kilo/nova'
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for nova file 003':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt/drivers/emc",
        file_name => 'scaleiolibvirtdriver.py',
        src_dir   => 'kilo/nova'
      }
    }
    elsif $core_version in ['2014.2.2', '2014.2.4'] {
      notify { "Detected nova version ${version} - treat as Juno": }

      scaleio_openstack::nova_common { 'nova common for Juno':
        ensure             => $ensure,
        gateway_user       => $gateway_user,
        gateway_password   => $gateway_password,
        gateway_ip         => $gateway_ip,
        gateway_port       => $gateway_port,
        protection_domains => $protection_domains,
        storage_pools      => $storage_pools,
        provisioning_type  => $provisioning_type,
        openstack_version  => 'juno',
        siolib_file        => 'siolib-1.2.5.tar.gz',
        nova_patch         => "${version}.diff",
        nova_config_file   => $nova_config_file,
      } ->

      scaleio_openstack::file_from_source { 'scaleio driver for nova':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt",
        file_name => 'scaleiolibvirtdriver.py',
        src_dir   => 'juno/nova'
      } ->
      ini_subsetting { 'scaleio_nova_config':
        ensure               => $ensure,
        path                 => $nova_config_file,
        section              => 'libvirt',
        setting              => 'volume_drivers',
        subsetting           => 'scaleio=nova.virt.libvirt.scaleiolibvirtdriver.LibvirtScaleIOVolumeDriver',
        subsetting_separator => ',',
      }
    }
    else {
      fail("Version ${::nova_version} isn't supported.")
    }
  }

  # TODO: Disintigrate to separate files for each version
}
