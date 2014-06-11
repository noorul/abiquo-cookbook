# Cookbook Name:: abiquo
# Recipe:: install_remoteservices
#
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

package "dhclient" do
    ignore_failure true
    action :purge
end

include_recipe "java"
include_recipe "redisio::install"
include_recipe "redisio::enable"

%w{remote-services v2v sosreport-plugins}.each do |pkg|
    package "abiquo-#{pkg}" do
        action :install
    end
end

# The abiquo-release-ee package installs this repo. As we are in control
# of the created repos, we just delete it, to avoid having it conflict with
# the configured ones.
yum_repository "Abiquo-Base" do
    action :delete
end

selinux_state "SELinux Permissive" do
    action :permissive
end

include_recipe "iptables"
iptables_rule "firewall-tomcat"

service "rpcbind" do
    action [:enable, :start]
end

service "abiquo-tomcat" do
    start_command "service abiquo-tomcat jpda" if node['abiquo']['tomcat-jpda']
end
