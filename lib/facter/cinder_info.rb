require 'facter'

Facter.add(:cinder_path) do
  setcode "python -c 'import cinder; import os; path = os.path.dirname(cinder.__file__); print(path)' 2>/dev/null"
end
