class scaleio_openstack
{
  define cinder_volume_type(
    $ensure = present,
    $name = undef,
    $protection_domain = undef,
    $storage_pool = undef,
    $provisioning_type = undef,
    $value_in_title = false, # in case of true parameters should be in title in form of 'name:domain:pool:provisioning'
   
    # TODO: The following below parameters will be depricated in next version puppet-cinder and openstack
    $os_password    = undef,
    $os_tenant_name = 'admin',
    $os_username    = 'admin',
    $os_auth_url    = 'http://127.0.0.1:5000/v2.0/'    
  )
  {
    
    if $value_in_title {
      notify {"cinder_volume_type ${title}": }
      $values = split($title, ':')
      $name = $value[0]
      $domain = $values[1]
      $pool = $values[2]
      $provitioning = $values[3]
    } else {
      notify {"cinder_volume_type ${title} => ${name}:${protection_domain}:${storage_pool}:${provisioning_type}": }
      $name = $name
      $domain = $protection_domain
      $pool = $storage_pool
      $provitioning = $provisioning_type
    }
    
    Cinder::Type {
      os_password     => $os_password,
      os_tenant_name  => $os_tenant_name,
      os_username     => $os_username,
      os_auth_url     => $os_auth_url
    }

    Cinder::Type_set {
      os_password     => $os_password,
      os_tenant_name  => $os_tenant_name,
      os_username     => $os_username,
      os_auth_url     => $os_auth_url
    }

    cinder::type {$name:
      set_value => "${domain}",
      set_key   => 'sio:pd_name'
    }

    cinder::type_set { "Set pool for ${name}":
      type  => $name,
      key   => 'sio:sp_name',
      value => $pool
    }
    
    cinder::type_set { "Set pool for ${provisioning}":
      type  => $name,
      key   => 'sio:provisioning',
      value => $provisioning
    }
    
    #TODO: implement absent after it appear in cinder or workaround here via cinder cli
    #...
    
  } # define cinder_volume_type
 
  define cinder_qos(
    $ensure = present,
    $volume_type_name,
    $qos_min_bws,
    $qos_max_bws,
    $value_in_title = false,
  )
  {
    Exec {
      path    => ['/usr/bin', '/bin'],
    }

    #TODO:
    
  } # define cinder_qos
 
} # class scaleio
