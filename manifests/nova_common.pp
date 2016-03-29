define scaleio_openstack::nova_common(
  $ensure              = undef,
  $gateway_user        = undef,
  $gateway_password    = undef,
  $gateway_ip          = undef,
  $gateway_port        = undef,
  $protection_domains  = undef,
  $storage_pools       = undef,
  $openstack_version   = undef,
  $siolib_file         = undef,
  $nova_patch          = undef,
) {
  file { "/tmp/${siolib_file}":
    source => "puppet:///modules/scaleio_openstack/${openstack_version}/${siolib_file}"
  } ->
  package { ['python-pip']:
    ensure => present,
  } ->
  package { 'siolib':
    ensure => $ensure,
    provider => 'pip',
    source => "file:///tmp/${siolib_file}"
  } ->

  scaleio_filter_file { 'nova filter file':
    ensure  => $ensure,
    service => 'nova'
  } ->

  file { "/tmp/${nova_patch}":
    source => "puppet:///modules/scaleio_openstack/${openstack_version}/nova/${nova_patch}"
  } ->
  exec { 'nova patch':
    onlyif => "test ${ensure} = present && patch -p 2 -i /tmp/${nova_patch} -d ${::nova_path} -b -f --dry-run",
    command => "patch -p 2 -i /tmp/${nova_patch} -d ${::nova_path} -b",
    path => '/bin:/usr/bin',
  } ->
  exec { 'nova un-patch':
    onlyif => "test ${ensure} = absent && patch -p 2 -i /tmp/${nova_patch} -d ${::nova_path} -b -R -f --dry-run",
    command => "patch -p 2 -i /tmp/${nova_patch} -d ${::nova_path} -b -R",
    path => '/bin:/usr/bin',
  } ->

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
