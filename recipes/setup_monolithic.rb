# Cookbook Name:: abiquo
# Recipe:: setup_monolithic
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

abiquo_nfs node['abiquo']['nfs']['mountpoint'] do
    share node['abiquo']['nfs']['location']
    oldshare "10.60.1.72:/opt/vm_repository"
    action :configure
    not_if { node['abiquo']['nfs']['location'].nil? }
end

include_recipe "abiquo::database" if node['abiquo']['installdb']

ruby_block "configure-ui" do
    block do
        # Chef search_file_replace_line is not working. Update the json manually
        uiconfigfile = "/var/www/html/ui/config/client-config.json"
        uiconfig = JSON.parse(File.read(uiconfigfile));
        uiconfig['config.endpoint'] = "https://#{node['fqdn']}/api"
        File.write(uiconfigfile, JSON.pretty_generate(uiconfig))
    end
    action :create
end

# Define the service with a custom name so we can subscribe just to the "restart" action
# otherwise the "wait_for_webapp" resource will be notified too early (when tomcat is stopped)
# and enqueued before the restart action is triggered
service "abiquo-tomcat-restart" do
    service_name "abiquo-tomcat"
    provider Chef::Provider::Service::RedhatNoStatus
    supports :restart => true
    pattern "tomcat"
    start_command "service abiquo-tomcat jpda" if node['abiquo']['tomcat-jpda']
end

template "/opt/abiquo/tomcat/conf/server.xml" do
    source "server.xml.erb"
    owner "root"
    group "root"
    action :create
    notifies :restart, "service[abiquo-tomcat-restart]"
end

template "/opt/abiquo/config/abiquo.properties" do
    source "abiquo-monolithic.properties.erb"
    owner "root"
    group "root"
    action :create
    variables lazy { { :apilocation => "https://#{node['fqdn']}/api" } }
    notifies :restart, "service[abiquo-tomcat-restart]"
end

abiquo_wait_for_webapp "api" do
    host "localhost"
    port node['abiquo']['tomcat-http-port']
    retries 3   # Retry if Tomcat is still not started
    retry_delay 5
    action :nothing
    subscribes :wait, "service[abiquo-tomcat-restart]"
    only_if { node['abiquo']['wait-for-webapps'] }
end
