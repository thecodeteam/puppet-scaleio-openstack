class scaleio_openstack::nova(
  $ensure              = present,
  $gateway_user        = admin,
  $gateway_password    = undef,
  $gateway_ip          = undef,
  $gateway_port        = 4443,
  $protection_domains  = undef,
  $storage_pools       = undef,
)
{
  notify {'Configuring Compute node for ScaleIO integration': }

  if ! $::nova_path {
    warning('Nova is not installed on this node')
  }
  else {

    $version = $::nova_version
    if versioncmp($version, '2014.2.0') < 0 {
      fail("Version $version too small and isn't supported.")
    }
    elsif versioncmp($version, '2015.1.0') < 0 {
      notify { "Detected nova version $version - treat as Juno":; }

      file { '/tmp/siolib-1.2.5.tar.gz':
        source => 'puppet:///modules/scaleio_openstack/juno/siolib-1.2.5.tar.gz'
      } ->
      package { 'siolib':
        ensure => $ensure,
        provider => 'pip',
        source => 'file:///tmp/siolib-1.2.5.tar.gz'
      } ->
      file_from_source { 'scaleio driver for nova':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt",
        file_name => 'scaleiolibvirtdriver.py',
        src_dir   => 'juno/nova'
      } ->
      scaleio_filter_file { 'nova filter file':
        ensure  => $ensure,
        service => 'nova'
      } ->
      ini_subsetting { 'scaleio_nova_config':
        ensure               => $ensure,
        path                 => '/etc/nova/nova.conf',
        section              => 'libvirt',
        setting              => 'volume_drivers',
        subsetting           => 'scaleio=nova.virt.libvirt.scaleiolibvirtdriver.LibvirtScaleIOVolumeDriver',
        subsetting_separator => ',',
      } ~>
      service { 'nova-compute':
        ensure => running,
      }

    }
    elsif versioncmp($version, '2015.2.0') < 0 {
      notify { "Detected nova version $version - treat as Kilo":; }

      file { '/tmp/siolib-1.3.5.tar.gz':
        source => 'puppet:///modules/scaleio_openstack/kilo/siolib-1.3.5.tar.gz'
      } ->
      package { 'siolib':
        ensure => $ensure,
        provider => 'pip',
        source => 'file:///tmp/siolib-1.3.5.tar.gz'
      } ->

      file { ["${::nova_path}/virt/libvirt/drivers", "${::nova_path}/virt/libvirt/drivers/emc"]:
        ensure  => directory,
        mode    => '0755',
      } ->
      file_from_source {'scaleio driver for nova file 001':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt/drivers",
        file_name => '__init__.py',
        src_dir   => 'kilo/nova'
      } ->
      file_from_source {'scaleio driver for nova file 002':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt/drivers/emc",
        file_name => '__init__.py',
        src_dir   => 'kilo/nova'
      } ->
      file_from_source {'scaleio driver for nova file 003':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt/drivers/emc",
        file_name => 'driver.py',
        src_dir   => 'kilo/nova'
      } ->
      file_from_source {'scaleio driver for nova file 004':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt/drivers/emc",
        file_name => 'scaleiolibvirtdriver.py',
        src_dir   => 'kilo/nova'
      } ->
      ini_setting { 'scaleio_nova_compute_config compute_driver':
        ensure  => $ensure,
        path    => '/etc/nova/nova-compute.conf',
        section => 'DEFAULT',
        setting => 'compute_driver',
        value   => 'nova.virt.libvirt.drivers.emc.driver.EMCLibvirtDriver',
      } ->

      file { '/tmp/2015.1.2.diff':
        source => 'puppet:///modules/scaleio_openstack/kilo/nova/2015.1.2.diff'
      } ->
      exec { 'nova patch':
        onlyif => "test ${ensure} == present && patch -p 2 -i /tmp/2015.1.2.diff -d ${::nova_path} -b -f --dry-run",
        command => "patch -p 2 -i /root/2015.1.2.diff -d ${::nova_path} -b",
        path => '/bin:/usr/bin',
      } ->
      exec { 'nova un-patch':
        onlyif => "test ${ensure} == absent && patch -p 2 -i /tmp/2015.1.2.diff -d ${::nova_path} -b -R -f --dry-run",
        command => "patch -p 2 -i /root/2015.1.2.diff -d ${::nova_path} -b -R",
        path => '/bin:/usr/bin',
      } ->
      nova_config { 'nova config for Kilo':
        ensure => $ensure,
        gateway_user => $gateway_user,
        gateway_password => $gateway_password,
        gateway_ip => $gateway_ip,
        gateway_port => $gateway_port,
        protection_domains => $protection_domains,
        storage_pools => $storage_pools,
      } ->
      scaleio_filter_file { 'nova filter file':
        ensure  => $ensure,
        service => 'nova'
      } ~>
      service { 'nova-compute':
        ensure => running,
      }

    }
    else {
      fail("Version $version too high and isn't supported.")
    }
  }
}


define scaleio_openstack::nova_config(
  $ensure              = present,
  $gateway_user        = admin,
  $gateway_password    = undef,
  $gateway_ip          = undef,
  $gateway_port        = 4443,
  $protection_domains  = undef,
  $storage_pools       = undef,
) {
  ini_setting { 'scaleio_nova_compute_config use_cow_images':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'DEFAULT',
    setting => 'use_cow_images',
    value   => 'False',
  } ->
  ini_setting { 'scaleio_nova_compute_config force_raw_images':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'DEFAULT',
    setting => 'force_raw_images',
    value   => 'False',
  } ->
  ini_setting { 'scaleio_nova_compute_config images_type':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'libvirt',
    setting => 'images_type',
    value   => 'sio',
  } ->
  ini_setting { 'scaleio_nova_compute_config rest_server_ip':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    setting => 'rest_server_ip',
    value   => $gateway_ip,
  } ->
  ini_setting { 'scaleio_nova_compute_config rest_server_port':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    setting => 'rest_server_port',
    value   => $gateway_port,
  } ->
  ini_setting { 'scaleio_nova_compute_config rest_server_username':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    setting => 'rest_server_username',
    value   => $gateway_user,
  } ->
  ini_setting { 'scaleio_nova_compute_config rest_server_password':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    setting => 'rest_server_password',
    value   => $gateway_port,
  } ->
  ini_setting { 'scaleio_nova_compute_config protection_domain_name':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    # TODO: domain or domains?
    setting => 'protection_domain_name',
    value   => $protection_domains,
  } ->
  ini_setting { 'scaleio_nova_compute_config storage_pool_name':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    # TODO: pool or pools?
    setting => 'storage_pool_name',
    value   => $storage_pools,
  } ->
  ini_setting { 'scaleio_nova_compute_config default_sdcguid':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    setting => 'default_sdcguid',
    value   => $::sdc_guid,
  }
}
