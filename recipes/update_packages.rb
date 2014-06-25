# Cookbook Name:: abiquo
# Recipe:: update_packages
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

Chef::Recipe.send(:include, Abiquo::Packages)

installed_packages.each do |pkg|
    package pkg do
        action :upgrade
    end

    # The abiquo-release-ee package installs this repo. As we are in control
    # of the created repos, we just delete it, to avoid having it conflict with
    # the configured ones.
    yum_repository "Abiquo-Base" do
        action :delete
        only_if { pkg.eql? "abiquo-release-ee" }
    end
end