class scaleio_openstack::glance (
  $ensure = present,    # could be present or absent
)
{
  notify {'Configure Glance to use ScaleIO cluster via Cinder': }

  if ! $::glance_path {
    warning('Glance is not installed on this node')
  }
  else {
    $version_str = split($::glance_version, '-')
    $version = $version_str[0]
    $version_array = split($version, '\.')

    if $version_array[0] >= '12' {
      notify { "Detected glance version ${version}": }

      scaleio_openstack::scaleio_filter_file { 'glance filter file':
        ensure  => $ensure,
        service => 'glance',
      }
    }
    else {
      fail("Version ${version} of python-glance isn't supported.")
    }
  }
}
