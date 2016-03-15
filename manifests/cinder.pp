
class scaleio_openstack::cinder (
  $ensure = present,    # could be present or absent
  $gateway_ip,
  $gateway_port = 4443,
  $gateway_user = 'admin',
  $gateway_password,
  $protection_domains = ['default'],
  $storage_pools = ['default'],
  $verify_server_certeficate = 'False',
  $force_delete = 'True',
  $round_volume_capacity = 'True',
  $scaleio_cinder_config_file = '/etc/cinder/cinder_scaleio.config',
  $default_lvm_backend = 'lvmdriver',
)
{
    notify {'Configure Cinder to use ScaleIO cluster': }

    $services_to_notify = [
      'openstack-cinder-volume',
      'openstack-cinder-api',
      'openstack-cinder-scheduler',
      'openstack-nova-scheduler',
    ]    

    # TODO: refactory to remove dublication with the code from volume_type.pp
    $pools_list = regsubst(join(flatten(zip($protection_domains, $storage_pools)), ':'), '(\w+):(\w+):', '\1:\2,', 'G') 

    File {
      mode  => '0644',
      owner => 'root',
      group => 'root',
    }

    file {$scaleio_cinder_config_file:
      ensure  => $ensure,
      path    => $scaleio_cinder_config_file,
      content => template('cinder_scaleio.conf.erb'),
    }
    
    file {'scaleio.py':
      ensure => $ensure,
      path   => '/usr/lib/python2.6/site-packages/cinder/volume/drivers/emc/scaleio.py',
      source => 'puppet:///files/scaleio.py',
    }
  
    file {'scaleio.filters':
      ensure => $ensure,
      path   => '/usr/share/cinder/rootwrap/scaleio.filters',
      source => 'puppet:///files/scaleio.filters',
    }
    
    $backend = $ensure ? {
      absent  => $default_lvm_backend, 
      default => 'ScaleIO',
    } 
    
    cinder_config {
      'DEFAULT/enabled_backends':           value => $backend;
      'ScaleIO/volume_driver':              value => 'cinder.volume.drivers.emc.scaleio.ScaleIODriver', ensure => $ensure;
      'ScaleIO/cinder_scaleio_config_file': value => $scaleio_cinder_config_file, ensure => $ensure;
      'ScaleIO/volume_backend_name':        value => 'ScaleIO', ensure => $ensure;
    } ~>
    
    service { $services_to_notify:
      ensure => running,
    }            
 
} # class scaleio::cinder
