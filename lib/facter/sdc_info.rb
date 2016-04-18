require 'facter'

Facter.add(:sdc_guid) do
  setcode "/bin/emc/scaleio/drv_cfg --query_guid"
end
