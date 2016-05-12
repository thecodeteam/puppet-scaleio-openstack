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

  if ! $::nova_path {
    warning('Nova is not installed on this node')
  }
  else {

    service { 'nova-compute':
      ensure => running,
    }
    Ini_setting <| |> ~> Service['nova-compute']
    Ini_subsetting <| |> ~> Service['nova-compute']
    File <| |> ~> Service['nova-compute']
    File_from_source <| |> ~> Service['nova-compute']
    Nova_common <| |> ~> Service['nova-compute']

    # Array of custom MOS versions, if a version is not in the array default patch will be applied,
    # in case of new custom mos patch it is needed to add its version into this table.
    $custom_mos_versions = [
      '30', '46',   # mos6.1
      '19676',      # mos7.0 (for 2015.1.1 but copy of 2015.1.3.diff)
    ]
    $version_str = split($::nova_version, '-')
    $core_version = $version_str[0]
    $custom_version_str = split($version_str[1], 'mos')
    if count($custom_version_str) > 1 and $custom_version_str[1] in $custom_mos_versions {
      $custom_version = $custom_version_str[1]
    } else {
      $custom_version = ''
    }
    if $custom_version and $custom_version != '' {
      $version = "${core_version}-mos${custom_version}"
    }
    else {
      $version = $core_version
    }

    notify { "Detected nova version: ${version}": }
    if $core_version in ['12.0.0', '12.0.1', '12.0.2'] {
      notify { "Detected nova version ${version} - treat as Liberty": }

      scaleio_openstack::nova_common { 'nova common for Liberty':
        ensure => $ensure,
        gateway_user => $gateway_user,
        gateway_password => $gateway_password,
        gateway_ip => $gateway_ip,
        gateway_port => $gateway_port,
        protection_domains => $protection_domains,
        storage_pools => $storage_pools,
        provisioning_type => $provisioning_type,
        openstack_version => 'liberty',
        siolib_file => 'siolib-1.4.5.tar.gz',
        nova_patch => "${version}.diff",
        nova_config_file => $nova_config_file,
      }
    }
    elsif $core_version in ['2015.1.1', '2015.1.2', '2015.1.3']  {
      notify { "Detected nova version ${version} - treat as Kilo": }

      scaleio_openstack::nova_common { 'nova common for Kilo':
        ensure => $ensure,
        gateway_user => $gateway_user,
        gateway_password => $gateway_password,
        gateway_ip => $gateway_ip,
        gateway_port => $gateway_port,
        protection_domains => $protection_domains,
        storage_pools => $storage_pools,
        provisioning_type => $provisioning_type,
        openstack_version => 'kilo',
        siolib_file => 'siolib-1.3.5.tar.gz',
        nova_patch => "${version}.diff",
        nova_config_file => $nova_config_file,
      } ->

      file { ["${::nova_path}/virt/libvirt/drivers", "${::nova_path}/virt/libvirt/drivers/emc"]:
        ensure  => directory,
        mode    => '0755',
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
        ensure => $ensure,
        gateway_user => $gateway_user,
        gateway_password => $gateway_password,
        gateway_ip => $gateway_ip,
        gateway_port => $gateway_port,
        protection_domains => $protection_domains,
        storage_pools => $storage_pools,
        provisioning_type => $provisioning_type,
        openstack_version => 'juno',
        siolib_file => 'siolib-1.2.5.tar.gz',
        nova_patch => "${version}.diff",
        nova_config_file => $nova_config_file,
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
