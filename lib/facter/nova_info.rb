require 'facter'
require 'json'
require 'puppet'
require 'puppet/util/inifile'


Facter.add(:nova_path) do
  setcode "python -c 'import nova; import os; path = os.path.dirname(nova.__file__); print(path)' 2>/dev/null"
end

Facter.add(:nova_version) do
  setcode do
    pkg = Puppet::Type.type(:package).new(:name => "python-nova")
    version = pkg.retrieve[pkg.property(:ensure)].to_s
    if version =~ /:/ then
      version = version.split(':')[1]
    end
    version
  end
end

if Facter.value(:nova_version)
  nova_props = {
    'nova_username'       => 'admin_user',
    'nova_password'       => 'admin_password',
    'nova_tenant_name'    => 'admin_tenant_name',
  }
  nova_config_file = '/etc/nova/nova.conf'
  if File.exist?(nova_config_file)
    nova_props.each do |key, value|
      Facter.add(key) do
        setcode do
          config = Puppet::Util::IniConfig::File.new
          config.read(nova_config_file)
          section = config['keystone_authtoken']
          section[value].strip()
        end
      end
    end
    Facter.add(:nova_auth_uri) do
      setcode do
        config = Puppet::Util::IniConfig::File.new
        config.read(nova_config_file)
        section = config['keystone_authtoken']
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
        uri.strip()
      end
    end
  end
end
