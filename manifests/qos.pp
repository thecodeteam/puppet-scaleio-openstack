class scaleio_openstack::volume_qos(
  $ensure       = present,
  $volume_names = undef,
  $qos_min_bws  = undef,   # array for each volume type
  $qos_max_bws  = undef, # array for each volume type

  # TODO: The following below parameters will be depricated in next version puppet-cinder and openstack
  $os_password    = undef,
  $os_tenant_name = 'admin',
  $os_username    = 'admin',
  $os_auth_url    = 'http://127.0.0.1:5000/v2.0/'
)
{
  define cinder_qos(
    $ensure = present,
    $volume_type_name = undef,
    $qos_min_bws = undef,
    $qos_max_bws = undef,
    $value_in_title = false,
    # TODO: The following below parameters will be depricated in next version puppet-cinder and openstack
    $os_password    = undef,
    $os_tenant_name = undef,
    $os_username    = undef,
    $os_auth_url    = undef,
  )
  {
    #TODO:    
  } # define cinder_qos

  $name_min_pairs_ = join(zip($volume_names, $qos_min_bws), ':')
  $name_min_pairs = split(regsubst("${name_min_pairs_}:", '(\w+):(\w+):', '\1:\2,', 'G'), ',')

  $name_min_max_pairs_ = join(zip($name_min_pairs, $qos_max_bws), ':')
  $qos = split(regsubst("${name_min_max_pairs_}:", '(\w+):(\w+):(\w+):', '\1:\2:\3,', 'G'), ',')
  
  cinder_qos {$qos:
    ensure => $ensure,
    value_in_title => true,
  }
}
