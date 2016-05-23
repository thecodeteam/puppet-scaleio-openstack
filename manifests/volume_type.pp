# Define for creation of volume types for ScaleIO
#
define scaleio_openstack::volume_type(
  $ensure             = present,  #
  $name,                          # name of volume type to be created
  $protection_domain  = undef,    # name of protection domain to tie with volume type
  $storage_pool       = undef,    # name of storage pool to tie with volume type
  $provisioning       = 'thick',  # type of provisioning, 'thin' / 'thick' 
) {
  $os_username = $::cinder_username ? {
    undef   => [],
    default => ["OS_USERNAME=${::cinder_username}"]
  }
  $os_password = $::cinder_password ? {
    undef   => [],
    default => ["OS_PASSWORD=${::cinder_password}"]
  }
  $os_tenant_name = $::cinder_tenant_name ? {
    undef   => [],
    default => ["OS_TENANT_NAME=${::cinder_tenant_name}"]
  }
  $os_auth_uri = $::cinder_auth_uri ? {
    undef   => [],
    default => ["OS_AUTH_URL=${::cinder_auth_uri}"]
  }
  $environment = concat($os_username, concat($os_password, concat($os_tenant_name, $os_auth_uri)))
  Exec {
    environment => $environment
  }
  $check_cmd = "cinder type-list | grep -q '${name}'"
  $volume_type_ensure_name = "ScaleIO Cinder Volume Type ${name} ${ensure}"
  if $ensure == present {
    exec {$volume_type_ensure_name:
      command     => "cinder type-create ${name}",
      path        => ['/usr/bin', '/bin'],
      unless      => $check_cmd,
    }
    $pd_opts = $protection_domain ? {
      undef   => '',
      default => "sio:pd_name=${protection_domain}"
    }
    $sp_opts = $storage_pool ? {
      undef   => '',
      default => "sio:sp_name=${storage_pool}"
    }
    $provisioning_opts = $provisioning ? {
      undef   => '',
      default => "sio:provisioning=${provisioning}"
    }
    $volume_type_opts = "${pd_opts} ${sp_opts} ${provisioning_opts}"
    if $volume_type_opts != '  ' {
      exec {"ScaleIO Cinder Volume Type ${name} Options ${volume_type_opts}":
        command => "cinder type-key '${name}' set ${volume_type_opts}",
        path    => ['/usr/bin', '/bin'],
        onlyif  => $check_cmd,
        require => Exec[$volume_type_ensure_name],
      }
    }
  } else {
    exec {$volume_type_ensure_name:
      command     => "cinder type-delete '${name}'",
      path        => ['/usr/bin', '/bin'],
      onlyif      => $check_cmd,
    }
  }
}
