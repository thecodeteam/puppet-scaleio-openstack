require 'facter'

Facter.add(:nova_path) do
  setcode "python -c 'import nova; import os; path = os.path.dirname(nova.__file__); print(path)' 2>/dev/null"
end
