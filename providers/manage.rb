#
# Cookbook:: certificate
# Provider:: manage
#
# Copyright 2012, Eric G. Wolfe
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
#

action :create do
  if Chef::Config[:solo]
    Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
  else
  
    chef_name = new_resource.cn.sub('*', 'wildcard').gsub('.', '_')

    #ssl_item = Chef::EncryptedDataBagItem.load(new_resource.data_bag, chef_name)
    ssl_item = data_bag_item(new_resource.data_bag, chef_name)
    
    cert_directory_resource "certs"
    cert_directory_resource "private", :private => true
    
    cert_file_resource "certs/#{new_resource.cn}.pem",  ssl_item['cert']
    cert_file_resource "private/#{new_resource.cn}.key", ssl_item['key'], :private => true
    
    if not ssl_item['chain'].nil?
      cert_file_resource "certs/#{new_resource.cn}-bundle.pem", ssl_item['chain']
    end
  end
end

def cert_directory_resource(dir, options = {})
  r = directory ::File.join(new_resource.cert_path, dir) do
    owner new_resource.owner
    group new_resource.group
    mode(options[:private] ? 00750 : 00755)
    recursive true
    not_if { ::File.exist? ::File.join(new_resource.cert_path, dir) }
  end
  new_resource.updated_by_last_action(true) if r.updated_by_last_action?
end

def cert_file_resource(path, content, options = {})
  r = template ::File.join(new_resource.cert_path, path) do
    source "blank.erb"
    cookbook new_resource.cookbook
    owner new_resource.owner
    group new_resource.group
    mode(options[:private] ? 00640 : 00644)
    variables :file_content => content
    only_if { content }
  end
  new_resource.updated_by_last_action(true) if r.updated_by_last_action?
end
