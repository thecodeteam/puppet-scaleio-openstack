class scaleio_openstack::nova(
  $ensure                   = present,
  $scaleio_filter_file_path = '/usr/share/nova/rootwrap'
)
{

  notice("Configuring Compute node for ScaleIO integration")

  File {
      mode  => '0644',
      owner => 'root',
      group => 'root',
  }

  file { 'scaleiolibvirtdriver.py':
    ensure => $ensure,
    path   => "${::nova_path}/virt/libvirt/scaleiolibvirtdriver.py",
    source => 'puppet:///files/scaleiolibvirtdriver.py',
  } ->

  file { 'scaleio.filters':
    ensure => $ensure,
    path   => "${scaleio_filter_file_path}/scaleio.filters",
    source => 'puppet:///files/scaleio.filters',
  } ->

  ini_subsetting {'Ensure rootwrap path is in nova config':
    ensure               => present,
    path                 => '/etc/nova/rootwrap.conf',
    section              => 'DEFAULT',
    setting              => 'filters_path',
    subsetting           => "${scaleio_filter_file_path}",
  } ->
    
  ini_subsetting { 'scaleio_nova_config':
    ensure               => $ensure,
    path                 => '/etc/nova/nova.conf',
    section              => 'libvirt',
    setting              => 'volume_drivers',
    subsetting           => 'scaleio=nova.virt.libvirt.scaleiolibvirtdriver.LibvirtScaleIOVolumeDriver',
    notify               => Service[$nova::params::compute_service_name],
  }
}
