


class {'scaleio_openstack::cinder':
  ensure              => present,
  gateway_ip          => '192.168.56.10',
  gateway_port        => 4443,
  gateway_user        => 'admin',
  gateway_password    => 'qwe123QWE',
  protection_domains  => ['pd1', 'pd1', pd2, pd2],
  storage_pools       => ['sp1', 'sp2', sp1, sp2],
}
