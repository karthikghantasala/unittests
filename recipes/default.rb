#
# Cookbook Name:: aig_project
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
platform = node['platform']
raise "ERROR: Unsupported Operating system #{platform}. Please run this cookbook on RHEL/CENTOS and Ubuntu systems!!!" if node['platform'] == 'windows'

#raise "ERROR: Unsupported Operating system #{platform}. Please run this cookbook on RHEL/CENTOS and Ubuntu systems!!!" if node['platform'] == 'windows'


postgres_root_user = node['aig_project']['db_root_user']
postgres_root_passwd = node['aig_project']['db_root_passwd']

#installer = 'redhat'

installer = data_bag_item("install_type", node['platform'])

loc_pref = node['aig_project']['loc_choice']

group "aig_group" do
  append true
end

user "aig_user" do
  gid 'aig_group'
end

directory '/usr/downloads' do
		owner 'root'
		group 'root'
		mode '0755'
	action :create
	end

package 'Install HTTPD ' do
  case node['platform']
  when 'redhat', 'centos'
    package_name 'httpd'
  when 'ubuntu', 'debian'
    package_name 'apache2'
  end
end

package "postgresql"
package "postgresql-contrib"

template '/etc/postgre_db_credentials' do
  source 'postgre_db_credentials.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables(
    db_user: postgres_root_user,
	db_passwd: postgres_root_passwd
  )
end

# change postgres password
#execute "change postgres password" do
#  user "aig_user"
##  command "psql -c \"alter user postgres with password '#{node['aig_project']['db_root_password']}';\""
#end

case "#{loc_pref}"
    when 'locb', 'locc'
    remote_file "/usr/downloads/appbincustom.#{installer}" do
      source "https://#{loc_pref}.customeralpha.org/appbincustom.#{installer}"
      owner 'root'
      group 'root'
      mode '0755'
      action :create
   end
 when 'loca'
    remote_file "/usr/downloads/appbincustom.#{installer}" do
      source "https://customeralpha.org/appbincustom.#{installer}"
      owner 'root'
      group 'root'
      mode '0755'
      action :create
   end
end




