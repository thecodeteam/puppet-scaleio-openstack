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
# Unit tests for scaleio_openstack::nova class
#

require 'spec_helper'

describe 'scaleio_openstack::nova', :type => :class  do

  describe 'nova is not installed on the node' do
    let (:facts) do
      {:nova_path => nil,}
    end
   
    it { should_not contain_file_from_source('scaleio driver for nova') }
    it { should_not contain_scaleio_filter_file('nova filter file') }
    it { should_not contain_service('nova-compute') }
  end

  describe 'nova is installed on the node' do
    let (:facts) do
      {:nova_path => '/some/fake/path',}
    end

    it { should contain_file_from_source('scaleio driver for nova').that_comes_before(['Scaleio_filter_file[nova filter file]']).with({
      :ensure           => :present,
      :dir              => '/some/fake/path',
      :file_name        => 'scaleiolibvirtdriver.py',
      :srv_dir          => 'juno/nova',
      })
    }

    it { should contain_scaleio_filter_file('nova filter file').that_notifies(['Service[nova-compute]']).with({
      :ensure           => :present,
      :service          => 'nova',
      })
    }

    it { should contain_service('nova-compute').with({
      :ensure           => :runing,
      })
    }

  end

end
