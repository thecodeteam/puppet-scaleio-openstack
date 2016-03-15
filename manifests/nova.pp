class scaleio_openstack::nova(
  $ensure                   = present,
)
{
  notify {"Configuring Compute node for ScaleIO integration": }

  file { 'scaleiolibvirtdriver.py':
    ensure => $ensure,
    path   => "${::nova_path}/virt/libvirt/scaleiolibvirtdriver.py",
    source => 'puppet:///files/scaleiolibvirtdriver.py',
  } ->

  scaleio_filter_file { 'nova':
    ensure => $ensure,
  } ->

  ini_subsetting { 'scaleio_nova_config':
    ensure               => $ensure,
    path                 => '/etc/nova/nova.conf',
    section              => 'libvirt',
    setting              => 'volume_drivers',
    subsetting           => 'scaleio=nova.virt.libvirt.scaleiolibvirtdriver.LibvirtScaleIOVolumeDriver',
    subsetting_separator => ',',
    notify               => Service[$nova::params::compute_service_name],
  }
}
