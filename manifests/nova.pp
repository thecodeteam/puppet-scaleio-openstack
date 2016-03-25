class scaleio_openstack::nova(
  $ensure = present,
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
      ini_setting { 'scaleio_nova_config':
        ensure  => $ensure,
        path    => '/etc/nova/nova-compute.conf',
        section => 'DEFAULT',
        setting => 'compute_driver',
        value   => 'nova.virt.libvirt.drivers.emc.driver.EMCLibvirtDriver',
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
