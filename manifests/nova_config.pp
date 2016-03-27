define nova_config(
  $ensure              = undef,
  $gateway_user        = undef,
  $gateway_password    = undef,
  $gateway_ip          = undef,
  $gateway_port        = undef,
  $protection_domains  = undef,
  $storage_pools       = undef,
) {
  ini_setting { 'scaleio_nova_compute_config use_cow_images':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'DEFAULT',
    setting => 'use_cow_images',
    value   => 'False',
  } ->
  ini_setting { 'scaleio_nova_compute_config force_raw_images':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'DEFAULT',
    setting => 'force_raw_images',
    value   => 'False',
  } ->
  ini_setting { 'scaleio_nova_compute_config images_type':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'libvirt',
    setting => 'images_type',
    value   => 'sio',
  } ->
  ini_setting { 'scaleio_nova_compute_config rest_server_ip':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    setting => 'rest_server_ip',
    value   => $gateway_ip,
  } ->
  ini_setting { 'scaleio_nova_compute_config rest_server_port':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    setting => 'rest_server_port',
    value   => $gateway_port,
  } ->
  ini_setting { 'scaleio_nova_compute_config rest_server_username':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    setting => 'rest_server_username',
    value   => $gateway_user,
  } ->
  ini_setting { 'scaleio_nova_compute_config rest_server_password':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    setting => 'rest_server_password',
    value   => $gateway_password,
  } ->
  ini_setting { 'scaleio_nova_compute_config protection_domain_name':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    # TODO: domain or domains?
    setting => 'protection_domain_name',
    value   => $protection_domains,
  } ->
  ini_setting { 'scaleio_nova_compute_config storage_pool_name':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    # TODO: pool or pools?
    setting => 'storage_pool_name',
    value   => $storage_pools,
  } ->
  ini_setting { 'scaleio_nova_compute_config default_sdcguid':
    ensure  => $ensure,
    path    => '/etc/nova/nova-compute.conf',
    section => 'scaleio',
    setting => 'default_sdcguid',
    value   => $::sdc_guid,
  }
}
