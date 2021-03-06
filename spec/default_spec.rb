# Copyright 2014, Abiquo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe 'abiquo::default' do
    let(:chef_run) { ChefSpec::SoloRunner.new }

    %w(monolithic remoteservices kvm).each do |profile|
        it "includes the recipes for the #{profile} profile" do
            chef_run.node.set['abiquo']['profile'] = profile
            stub_command('/usr/sbin/httpd -t').and_return(true) if profile == 'monolithic'
            chef_run.converge(described_recipe)

            expect(chef_run).to include_recipe('abiquo::repository')
            expect(chef_run).to include_recipe("abiquo::install_#{profile}")
            expect(chef_run).to include_recipe("abiquo::setup_#{profile}")
        end
    end
end
