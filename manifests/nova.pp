class scaleio_openstack::nova(
  $ensure = present,
)
{
  notify {'Configuring Compute node for ScaleIO integration': }

  include nova::params

  if ! $::nova_path {
    fail('Nova is not installed on this node')
  }

  file_from_source { 'scaleiolibvirtdriver.py':
    path   => "${::nova_path}/virt/libvirt",
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
  } ~>
  
  service { $nova::params::compute_service_name:
    ensure => running,
  }
}
