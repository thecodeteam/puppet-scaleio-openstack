
class {'scaleio_openstack::volume_type':
  ensure              => present,
  protection_domains  => ['pd1', 'pd1', pd2, pd2],
  storage_pools       => ['sp1', 'sp2', sp1, sp2],
  provisioning        => ['thin', 'thick', 'thin', 'thick'],
  qos_min_bws         => undef,
  qos_max_bws         => undef,
}
