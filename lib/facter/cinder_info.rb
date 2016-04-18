require 'facter'
require 'json'
require 'puppet'
require 'puppet/util/inifile'


Facter.add(:cinder_path) do
  setcode "python -c 'import cinder; import os; path = os.path.dirname(cinder.__file__); print(path)' 2>/dev/null"
end

Facter.add(:cinder_version) do
  setcode do
    pkg = Puppet::Type.type(:package).new(:name => "python-cinder")
    $version = pkg.retrieve[pkg.property(:ensure)]
    if $version =~ /:/ then
      $version = $version.split(':')[1]
    end
    $version
  end
end

if Facter.value(:cinder_version)
  cinder_props = {
    'cinder_username'       => 'admin_user',
    'cinder_password'       => 'admin_password',
    'cinder_tenant_name'    => 'admin_tenant_name',
  }
  cinder_config_file = '/etc/cinder/cinder.conf'
  if File.exist?(cinder_config_file)
    config = Puppet::Util::IniConfig::File.new
    config.read(cinder_config_file)
    section = config['keystone_authtoken']
    if section
      cinder_props.each do |key, value|
        Facter.add(key) do
          setcode do
            section[value]
          end
        end
      end
      Facter.add(:cinder_auth_uri) do
        setcode do
          uri = nil
          if section['auth_uri']
            uri = section['auth_uri']
          elsif section['identity_uri']
            uri = section['identity_uri']
          else
            uri = "%s://%s:%s" % [section['auth_protocol'], section['auth_host'], section['auth_port']]
          end
          api_version = section['auth_version']
          if not api_version
            resp  = Facter::Util::Resolution.exec( "curl -k --basic --connect-timeout 10 %s" % uri)
            if resp
              spec = JSON.parse(resp)
              if spec and spec['versions'] and spec['versions']['values']
                version = 'v2.0'
                spec['versions']['values'].each do |val|
                  if version == val['id']
                    version = val['id']
                    uri = val['links'][0]['href'] unless val['links'].count() == 0
                  end
                end
              end
            end
          else
            uri = "%s/%s" % [uri, api_version]
          end
          uri
        end
      end
    end
  end
end
