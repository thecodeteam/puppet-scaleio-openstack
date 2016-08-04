# Creation of flavors for ScaleIO.
#   Puppet expects that crenetials are available in /etc/nova/nova.conf.
#   It reads them via facts nova_username, nova_password, nova_tenant_name,
#   nova_auth_uri.
#   Sizes of all disks should be multiple of 8GB


define scaleio_openstack::flavor(
  $flavor_name,                   # name of flavor to be created, could be name:something if needed to remove/delete
                                  # flavor for edit purposes
  $ensure             = present,  #
  $storage_pool       = undef,    # name of storage pool to use for the flavor
  $id                 = 'auto',   # unique ID of the new flavor.
  $ram_size           = undef,    # memory size in MB
  $vcpus              = undef,    # number of vcpu
  $disk_size          = undef,    # disk size inGB
  $ephemeral_size     = undef,    # size of ephemeral disk in GB, default 0
  $swap_size          = undef,    # size of swap disk in GB, default 0
  $rxtx_factor        = undef,    # RX/TX factor (default 1)
  $is_public          = undef,    # make flavor accessible to the public True/False (default true)
  $provisioning       = 'thin',   # type of provisioning, 'thin' / 'thick'
) {
  $os_username = $::nova_username ? {
    undef   => [],
    default => ["OS_USERNAME=${::nova_username}"]
  }
  $os_password = $::nova_password ? {
    undef   => [],
    default => ["OS_PASSWORD=${::nova_password}"]
  }
  $os_tenant_name = $::nova_tenant_name ? {
    undef   => [],
    default => ["OS_TENANT_NAME=${::nova_tenant_name}"]
  }
  $os_project_name = $::nova_tenant_name ? {
    undef   => [],
    default => ["OS_PROJECT_NAME=${::nova_tenant_name}"]
  }
  $os_auth_uri = $::nova_auth_uri ? {
    undef   => [],
    default => ["OS_AUTH_URL=${::nova_auth_uri}"]
  }
  $environment = concat($os_username, concat($os_password, concat($os_tenant_name, concat($os_project_name, $os_auth_uri))))
  Exec {
    environment => $environment
  }
  $ephemeral_disk_opts = $ephemeral_size ? {
    undef     => '',
    default   => "--ephemeral ${ephemeral_size}"
  }
  $swap_disk_opts = $swap_size ? {
    undef     => '',
    default   => "--swap ${swap_size}"
  }
  $rxtx_factor_opts = $rxtx_factor ? {
    undef     => '',
    default   => "--rxtx-factor ${rxtx_factor}"
  }
  $is_public_opts = $is_public ? {
    undef     => '',
    default   => "--is-public ${is_public}"
  }
  $parsed_name = split($flavor_name, ':')
  if count($parsed_name) > 1 {
    $flavor_name = $parsed_name[0]
  }
  $flavor_opts = "${ephemeral_disk_opts} ${swap_disk_opts} ${rxtx_factor_opts} ${is_public_opts}"
  $check_cmd = "nova flavor-list | grep -q '${flavor_name}'"
  $flavor_resource_name = "ScaleIO nova flavor ${flavor_name} ${ensure}"
  if $ensure == present {
    exec {$flavor_resource_name:
      command => "nova flavor-create ${flavor_opts} ${flavor_name} ${id} ${ram_size} ${disk_size} ${vcpus}",
      path    => ['/usr/bin', '/bin'],
      unless  => $check_cmd,
    }
    $sp_opts = $storage_pool ? {
      undef   => '',
      default => "sio:sp_name=${storage_pool}"
    }
    $provisioning_opts = $provisioning ? {
      undef   => '',
      default => "sio:provisioning=${provisioning}"
    }
    $flavor_attributes = "${sp_opts} ${provisioning_opts}"
    if $flavor_attributes != ' ' {
      exec {"ScaleIO nova flavor ${flavor_name} attributes ${flavor_attributes}":
        command => "nova flavor-key '${flavor_name}' set ${flavor_attributes}",
        path    => ['/usr/bin', '/bin'],
        onlyif  => $check_cmd,
        require => Exec[$flavor_resource_name],
      }
    }
  } else {
    exec {$flavor_resource_name:
      command => "nova flavor-delete '${flavor_name}'",
      path    => ['/usr/bin', '/bin'],
      onlyif  => $check_cmd,
    }
  }
}
