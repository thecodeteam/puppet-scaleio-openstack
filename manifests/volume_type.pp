class scaleio_openstack::volume_type(
  $ensure = present,
  $protection_domains = ['default'],
  $storage_pools = ['default'],
  $provisioning = ['thin'],
  $qos_min_bws = undef, # array for each volume type
  $qos_max_bws = undef, # array for each volume type
)
{
  # todo: refactore to remove this ugly code converting several arrays into array of strings 'v1:v2:v3:v4'
  $domain_pool_pairs = zip($protection_domains, $storage_pools)   
  $names = split(regsubst(join($domain_pool_pairs, ':'), '(\w+):(\w+):', 'sio_\1_\2,', 'G'), ',')
  $name_domain_pairs = split(regsubst(join(zip($names, $protection_domains), ':'), '(\w+):(\w+):', '\1:\2,', 'G'), ',')
  $name_domain_pool_pairs = split(regsubst(join(zip($name_domain_pairs, $storage_pools), ':'), '(\w+):(\w+):(\w+):', '\1:\2:\3,', 'G'), ',')
  $types = split(regsubst(join(zip($name_domain_pool_pairs, $provisioning), ':'), '(\w+):(\w+):(\w+):(\w+):', '\1:\2:\3:\4,', 'G'), ',')

  cinder_volume_type {$types:
    ensure => $ensure,
    value_in_title => true,
  }
  
  if $qos_min_bws or $qos_max_bws {
    
   $name_min_pairs = split(regsubst(join(zip($names, $qos_min_bws), ':'), '(\w+):(\w+):', '\1:\2,', 'G'), ',')
   $qos = split(regsubst(join(zip($name_min_pairs, $qos_max_bws), ':'), '(\w+):(\w+):(\w+):', '\1:\2:\3,', 'G'), ',')
    
    cinder_qos {$qos:
      ensure => $ensure,
      value_in_title => true,
    }
  }
}
