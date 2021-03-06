# Cookbook Name:: abiquo
# Recipe:: setup_remoteservices
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

mount node['abiquo']['nfs']['mountpoint'] do
    device node['abiquo']['nfs']['location']
    fstype "nfs"
    action [:enable, :mount]
    not_if { node['abiquo']['nfs']['location'].nil? }
end

# Define the service with a custom name so we can subscribe just to the "restart" action
# otherwise the "wait_for_webapp" resource will be notified too early (when tomcat is stopped)
# and enqueued before the restart action is triggered
service "abiquo-tomcat-start" do
    service_name "abiquo-tomcat"
end

template "/opt/abiquo/tomcat/conf/server.xml" do
    source "server.xml.erb"
    owner "root"
    group "root"
    action :create
    notifies :start, "service[abiquo-tomcat-start]"
end

template "/opt/abiquo/config/abiquo.properties" do
    source "abiquo-rs.properties.erb"
    owner "root"
    group "root"
    action :create
    variables :properties => node['abiquo']['properties']
    notifies :start, "service[abiquo-tomcat-start]"
end

abiquo_wait_for_webapp "virtualfactory" do
    host "localhost"
    port node['abiquo']['tomcat']['http-port']
    retries 3   # Retry if Tomcat is still not started
    retry_delay 5
    action :nothing
    subscribes :wait, "service[abiquo-tomcat-start]"
    only_if { node['abiquo']['tomcat']['wait-for-webapps'] }
end
