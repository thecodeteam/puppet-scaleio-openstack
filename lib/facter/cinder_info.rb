require 'facter'
require 'puppet'

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
