
class {'scaleio_openstack::volume_type':
  ensure              => present,
  protection_domains  => ['pd1', 'pd1', pd2, pd2],
  storage_pools       => ['sp1', 'sp2', sp1, sp2],
  provisioning        => ['thin', 'thick', 'thin', 'thick'],
  os_password         => 'admin',
  os_tenant_name      => 'services',
  os_username         => 'admin',
  os_auth_url         => 'http://127.0.0.1:5000/v2.0/'
}
