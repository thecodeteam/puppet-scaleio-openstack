# Class to configure glance to use ScaleIO for images (via Cinder backend).


# Helping define for internal use
define scaleio_openstack::glance_config(
  $config_file,
) {
  if $config_file and $config_file != '' {
    ini_subsetting { "${config_file}: stores":
      ensure               => 'present',
      path                 => $config_file,
      section              => 'glance_store',
      setting              => 'stores',
      subsetting           => 'glance.store.cinder.Store',
      subsetting_separator => ',',
    } ->
    ini_setting { "${config_file}: default_store":
      ensure  => 'present',
      path    => $config_file,
      section => 'glance_store',
      setting => 'default_store',
      value   => 'cinder',
    }
  }
}


class scaleio_openstack::glance (
  $ensure         = present,                          # could be present or absent
  $glance_config  = '/etc/glance/glance-api.conf',    # if empty or undef the config actions be skipped
  $glare_config   = '/etc/glance/glance-glare.conf',
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
      package { ['python-cinderclient',
                 'python-os-brick',
                 $::osfamily ? { 'Debian' => 'python-oslo.rootwrap', 'RedHat' => 'python-oslo-rootwrap'}]:
        ensure => 'present',
      } ->
      scaleio_openstack::scaleio_filter_file { 'glance filter file':
        ensure  => $ensure,
        service => 'glance',
      } ->
      scaleio_openstack::file_from_source { 'glance_rootwrap':
        ensure        => $ensure,
        dir           => '/etc/glance',
        file_name     => 'glance_rootwrap.conf',
        src_dir       => '.',
        dst_file_name => 'rootwrap.conf',
      } ->
      scaleio_openstack::file_from_source { 'glance_sudoers':
        ensure    => $ensure,
        dir       => '/etc/sudoers.d',
        file_name => 'glance_sudoers',
        src_dir   => '.',
      }

      $glance_config_provided = $glance_config and $glance_config != ''
      $glare_config_provided = $glare_config and $glare_config != ''
      if $glance_config_provided or $glare_config_provided {
        $glance_services = $::osfamily ? {
          'RedHat' => ['openstack-glance-api', 'openstack-glance-registry', 'openstack-glance-glare'],
          'Debian' => ['glance-api', 'glance-registry', 'glance-glare'],
        }
        glance_config { "glance config: ${glance_config}":
          config_file => $glance_config,
          require     => Scaleio_openstack::File_from_source['glance_sudoers'],
        } ->
        glance_config { "glare config: ${glare_config}":
          config_file => $glare_config,
        } ~>
        service { $glance_services:
          ensure => running,
          enable => true,
        }
      }
    } else {
      fail("Version ${version} of python-glance isn't supported.")
    }
  }
}
