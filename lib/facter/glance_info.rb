require 'facter'
require 'json'
require 'puppet'
require 'puppet/util/inifile'


Facter.add(:glance_path) do
  setcode "python -c 'import glance; import os; path = os.path.dirname(glance.__file__); print(path)' 2>/dev/null"
end

Facter.add(:glance_version) do
  setcode do
    pkg = Puppet::Type.type(:package).new(:name => "python-glance")
    version = pkg.retrieve[pkg.property(:ensure)].to_s
    if version =~ /:/ then
      version = version.split(':')[1]
    end
    version
  end
end
