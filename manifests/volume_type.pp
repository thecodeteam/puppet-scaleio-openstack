class scaleio_openstack::volume_type(
  $ensure = present,
  $protection_domains = ['default'],
  $storage_pools = ['default'],
  $provisioning = ['thin'],
  $qos_min_bws = undef, # array for each volume type
  $qos_max_bws = undef, # array for each volume type

  # TODO: The following below parameters will be depricated in next version puppet-cinder and openstack
  $os_password    = undef,
  $os_tenant_name = 'admin',
  $os_username    = 'admin',
  $os_auth_url    = 'http://127.0.0.1:5000/v2.0/'
)
{  
  define cinder_volume_type(
    $ensure = present,
    $protection_domain = undef,
    $storage_pool = undef,
    $provisioning_type = undef,
    $value_in_title = false, # in case of true parameters should be in name and title are in form of 'name:domain:pool:provisioning'
    # TODO: The following below parameters will be depricated in next version puppet-cinder and openstack
    $os_password    = undef,
    $os_tenant_name = undef,
    $os_username    = undef,
    $os_auth_url    = undef, 
  )
  {
    
    if $value_in_title {
      notify {"cinder_volume_type ${title}": }
      $values       = split($title, ':')
      $type_name    = $values[0]
      $domain       = $values[1]
      $pool         = $values[2]
      $provitioning = $values[3]
    } else {
      notify {"cinder_volume_type ${name}:${protection_domain}:${storage_pool}:${provisioning_type}": }
      $type_name    = $name
      $domain       = $protection_domain
      $pool         = $storage_pool
      $provitioning = $provisioning_type
    }

    Cinder::Type_set {
      type            => $type_name,
      os_password     => $os_password,
      os_tenant_name  => $os_tenant_name,
      os_username     => $os_username,
      os_auth_url     => $os_auth_url
    }
    
    cinder::type {$type_name:
      os_password     => $os_password,
      os_tenant_name  => $os_tenant_name,
      os_username     => $os_username,
      os_auth_url     => $os_auth_url
    } ->

    cinder::type_set { "Set domain ${domain} for ${type_name}":
      key   => 'sio:pd_name',
      value => $domain
    } ->

    cinder::type_set { "Set pool ${pool} for ${type_name}":
      key   => 'sio:sp_name',
      value => $pool
    } ->
    
    cinder::type_set { "Set provisioning ${provisioning} for ${type_name}":
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
    #TODO:    
  } # define cinder_qos

  # todo: refactore to remove this ugly code converting several arrays into array of strings 'v1:v2:v3:v4'
  $domain_pool_pairs = zip($protection_domains, $storage_pools)

  $names_ = join($domain_pool_pairs, ':')
  $names = split(regsubst("${names_}:", '(\w+):(\w+):', 'sio_\1_\2,', 'G'), ',')

  $name_domain_pairs_ = join(zip($names, $protection_domains), ':')
  $name_domain_pairs = split(regsubst("${name_domain_pairs_}:", '(\w+):(\w+):', '\1:\2,', 'G'), ',')

  $name_domain_pool_pairs_ = join(zip($name_domain_pairs, $storage_pools), ':')
  $name_domain_pool_pairs = split(regsubst("${name_domain_pool_pairs_}:", '(\w+):(\w+):(\w+):', '\1:\2:\3,', 'G'), ',')

  $types_ = join(zip($name_domain_pool_pairs, $provisioning), ':')
  $types = split(regsubst("${types_}:", '(\w+):(\w+):(\w+):(\w+):', '\1:\2:\3:\4,', 'G'), ',')

  class {'cinder::client': } ->

  cinder_volume_type {$types:
    ensure          => $ensure,
    value_in_title  => true,
    os_password     => $os_password,
    os_tenant_name  => $os_tenant_name,
    os_username     => $os_username,
    os_auth_url     => $os_auth_url,
  }
  
  if $qos_min_bws or $qos_max_bws {
    
   $name_min_pairs = split(regsubst(join(zip($names, $qos_min_bws), ':'), '(\w+):(\w+):', '\1:\2,', 'G'), ',')
   $qos_ = join(zip($name_min_pairs, $qos_max_bws), ':')
   $qos = split(regsubst("${qos_}:", '(\w+):(\w+):(\w+):', '\1:\2:\3,', 'G'), ',')
    
    cinder_qos {$qos:
      ensure => $ensure,
      value_in_title => true,
    }
  }
}
