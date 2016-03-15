class scaleio_openstack::nova(
  $ensure = present,
) {

  notice("Configuring Compute node for ScaleIO integration")

  $services_to_notify = ['openstack-nova-compute',]

  File {
      mode  => '0644',
      owner => 'root',
      group => 'root',
  }

  file { 'scaleiolibvirtdriver.py':
    ensure => $ensure,
    path   => '/usr/lib/python2.6/site-packages/nova/virt/libvirt/scaleiolibvirtdriver.py',
    source => 'puppet:///files/scaleiolibvirtdriver.py',
  }

  file { 'scaleio.filters':
    ensure => $ensure,
    path   => '/usr/share/nova/rootwrap/scaleio.filters',
    source => 'puppet:///files/scaleio.filters',
  }

  ini_subsetting { 'scaleio_nova_config':
    ensure               => $ensure,
    path                 => '/etc/nova/nova.conf',
    section              => 'libvirt',
    setting              => 'volume_drivers',
    subsetting           => 'scaleio=nova.virt.libvirt.scaleiolibvirtdriver.LibvirtScaleIOVolumeDriver',
    notify               => Service[$services_to_notify],
  }
}
