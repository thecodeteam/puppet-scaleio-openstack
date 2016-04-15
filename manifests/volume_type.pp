# Define for creation of volume types for ScaleIO
#
define scaleio_openstack::volume_type(
  $name,                        # name of volume type to be created
  $protectio_domain,            # name of protection domain to tie with volume type
  $storage_pool,                # name of storage pool to tie with volume type
  $ensure           = present,  #
  $os_user          = undef,    # OpenStack user name
  $os_password      = undef,    # OpenStack user password
  $os_tenant        = undef,    # OpenStack tenant name
  $os_auth_url      = undef,    # OpenStack auth URL
  $env_file         = undef,    # environment file with all OS required parameters,
                                # use either this option or os_xx parameters 
) {
  $source_opts = $env_file ? {
    undef     => '',
    default   => "source ${env_file} ; "
  }
  if $os_user and $os_password and $os_tenant and $os_auth_url {
    Exec {
      environment => [
        "OS_USERNAME=${os_user}",
        "OS_PASSWORD=${os_password}",
        "OS_AUTH_URL=${os_auth_url}",
        "OS_TENANT_NAME=${os_tenant}",
      ]
    }
  }  
  if $ensure == present {
    exec {"ScaleIO Cinder Volume Type ${name} ${ensure}, pd: ${protectio_domain}, sp: ${storage_pool}":
      command     => "bash -c '${source_opts} cinder type-create ${name}'",
      path        => ['/usr/bin', '/bin'],
      unless      => "bash -c '${source_opts} cinder type-list | grep -q \"${name}\"'",
    } ->
    exec {"Properties for ScaleIO Cinder Volume Type ${name}, pd: ${protectio_domain}, sp: ${storage_pool}":
      command => "bash -c '${source_opts} cinder type-key ${name} set sio:pd_name=${protectio_domain} sio:provisioning=thin sio:sp_name=${storage_pool}'",
      path    => ['/usr/bin', '/bin'],
      onlyif  => "bash -c '${source_opts} cinder type-list | grep -q \"${name}\"'",
    }    
  } else {
    exec {"ScaleIO Cinder Volume Type ${name} ${ensure}":
      command     => "bash -c '${source_opts} cinder type-delete ${name}'",
      path        => ['/usr/bin', '/bin'],
      onlyif      => "bash -c '${source_opts} cinder type-list | grep -q \"${name}\"'",
    }
  }
}
