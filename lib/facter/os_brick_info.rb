require 'facter'

Facter.add(:os_brick_path) do
  setcode "python -c 'import os_brick; import os; path = os.path.dirname(os_brick.__file__); print(path)' 2>/dev/null"
end
