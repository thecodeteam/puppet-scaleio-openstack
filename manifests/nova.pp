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

    $version_str = split($::nova_version, '-')
    $version = $version_str[0]
    if versioncmp($version, '2014.2.0') < 0 {
      fail("Version $version too small and isn't supported.")
    }
    elsif versioncmp($version, '2015.1.0') < 0 {
      notify { "Detected nova version $version - treat as Juno":; }

      file { '/tmp/siolib-1.2.5.tar.gz':
        source => 'puppet:///modules/scaleio_openstack/juno/siolib-1.2.5.tar.gz'
      } ->
      package { ['python-pip']:
        ensure => present,
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
      ini_subsetting { 'scaleio_nova_config':
        ensure               => $ensure,
        path                 => '/etc/nova/nova.conf',
        section              => 'libvirt',
        setting              => 'volume_drivers',
        subsetting           => 'scaleio=nova.virt.libvirt.scaleiolibvirtdriver.LibvirtScaleIOVolumeDriver',
        subsetting_separator => ',',
      } ->

      file { "/tmp/${version}.diff":
        source => "puppet:///modules/scaleio_openstack/juno/nova/${version}.diff"
      } ->
      exec { 'nova patch':
        onlyif => "test ${ensure} = present && patch -p 2 -i /tmp/${version}.diff -d ${::nova_path} -b -f --dry-run",
        command => "patch -p 2 -i /tmp/${version}.diff -d ${::nova_path} -b",
        path => '/bin:/usr/bin',
      } ->
      exec { 'nova un-patch':
        onlyif => "test ${ensure} = absent && patch -p 2 -i /tmp/${version}.diff -d ${::nova_path} -b -R -f --dry-run",
        command => "patch -p 2 -i /tmp/${version}.diff -d ${::nova_path} -b -R",
        path => '/bin:/usr/bin',
      } ->
      nova_config { 'nova config for Juno':
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
    elsif versioncmp($version, '2015.2.0') < 0 {
      notify { "Detected nova version $version - treat as Kilo":; }

      file { '/tmp/siolib-1.3.5.tar.gz':
        source => 'puppet:///modules/scaleio_openstack/kilo/siolib-1.3.5.tar.gz'
      } ->
      package { ['python-pip']:
        ensure => present,
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
        onlyif => "test ${ensure} = present && patch -p 2 -i /tmp/2015.1.2.diff -d ${::nova_path} -b -f --dry-run",
        command => "patch -p 2 -i /tmp/2015.1.2.diff -d ${::nova_path} -b",
        path => '/bin:/usr/bin',
      } ->
      exec { 'nova un-patch':
        onlyif => "test ${ensure} = absent && patch -p 2 -i /tmp/2015.1.2.diff -d ${::nova_path} -b -R -f --dry-run",
        command => "patch -p 2 -i /tmp/2015.1.2.diff -d ${::nova_path} -b -R",
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

