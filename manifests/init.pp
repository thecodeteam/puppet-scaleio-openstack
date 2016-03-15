class scaleio_openstack
{
  define cinder_volume_type(
    $ensure = present,
    $name = undef,
    $protection_domain = undef,
    $storage_pool = undef,
    $provisioning_type = undef,
    $value_in_title = false, # in case of true parameters should be in title in form of 'name:domain:pool:provisioning'
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
    
    $check_cmd = "bash -c 'source /root/openrc; cinder type-list |grep -q \" ${name} \"'"

    
    Exec {
      path    => ['/usr/bin', '/bin'],
    }
    
    if $ensure == present {
      exec { "Create Cinder volume type \'${name}\'":
        command => "bash -c 'source /root/openrc; cinder type-create ${name}'",
        unless  => $check_cmd,
     } ->
     exec { "Create Cinder volume type extra specs for ${name}":
        command => "bash -c 'source /root/openrc; cinder type-key ${name} set sio:pd_name=${domain} sio:provisioning=${provisioning} sio:sp_name=${pool}'",
      }    
    } else {
      exec { "Delete Cinder volume type \'${name}\'":
        command => "bash -c 'source /root/openrc; cinder type-delete ${name}'",
        onlyif  => $check_cmd,
     }
    }
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

    #TODO
  } # define cinder_qos
 
} # class scaleio
