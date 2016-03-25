#
# Copyright (C) 2016 EMC
#
# Author: EMC
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for scaleio_openstack::cinder class
#

require 'spec_helper'

describe 'scaleio_openstack::cinder', :type => :class  do

  describe 'cinder is not installed on the node' do
    let (:facts) {
       :cinder_path     => nil,
       :cinder_version  => nil,
     }
   
    it { should_not contain_file_from_source('scaleio driver for nova') }
    it { should_not contain_scaleio_filter_file('nova filter file') }
    it { should_not contain_service('nova-compute') }
  end

  describe 'cinder unsupported version' do
    let (:facts) {
      :cinder_path      => '',
      :cinder_version   => '2014.1.1',
    }
    
    it { is_expected.to run.with_params().and_raise_error(Puppet::Error, /Version 2014.1.1 too small and isn't supported./) }
  end

  let :params {
    :gateway_user       => 'admin',
    :gateway_password   => 'password',
    :gateway_ip         => '1.2.3.4',
    :protection_domains => 'pd1',
    :storage_pools      => 'sp1',
    
  }

  describe 'cinder Juno is installed on the node' do
    let (:facts) {
      :cinder_path      => '/some/fake/path',
      :cinder_version   => '2014.2.2'
    }
    
    it { is_expected.to run.with_params().and_not_raise_error() }

    it { should contain_file_from_source('scaleio driver for cinder').with({
      :ensure           => :present,
      :dir              => '/some/fake/path/volume/drivers/emc',
      :file_name        => 'scaleio.py',
      :srv_dir          => 'juno/cinder',
      }).that_comes_before(['Scaleio_filter_file[cinder filter file]'])
    }

    it { should contain_scaleio_filter_file('nova filter file').with({
      :ensure           => :present,
      :service          => 'nova',
      }).that_notifies(['Service[nova-compute]'])
    }

    it { should contain_service('nova-compute').with({
      :ensure           => :runing,
      })
    }

  end

end
