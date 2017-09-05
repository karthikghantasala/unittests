#
# Cookbook Name:: aig_project
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

raise ArgumentError,"ERROR: Unsupported Operating system #{node['platform'] }. Please run this cookbook on RHEL/CENTOS and Ubuntu systems!!!" if node['platform_family'] == 'windows'

postgres_root_user = node['aig_project']['db_root_user']
postgres_root_passwd = node['aig_project']['db_root_passwd']

raise ArgumentError, 'The postgres username and password must be supplied' if postgres_root_user.nil? || postgres_root_passwd.nil?

begin
  custom_application = data_bag_item('artifacts', 'custom_application')
  raise if custom_application.nil?
rescue
  custom_application = {} # This is a good stop gap in case we can't find the bag_item and prevents other unforseen errors
  raise ArgumentError, "Unable to locate the DataBagItem(\"artifacts\",\"custom_application\")"
end

loc_pref = node['aig_project']['loc_choice']
raise ArgumentError, 'The chosen location is not supported or the custom_application binary information not found.' if custom_application[loc_pref].nil? || loc_pref.nil?

# We will assign this variable a value to shorten the repeated writing.  This will first look in the item to see if there is a 
# child key for the current platform family.
location_bag_item = custom_application[loc_pref][node['platform_family']]
raise ArgumentError, 'The chosen location and OS type does not appear to have a supported binary path and was not found.' if location_bag_item.nil?

directory '/usr/downloads' do
	owner 'root'
	group 'root'
	mode '0755'
	action :create
end

# Install the Apache application
package 'Install HTTPD ' do
  case node['platform']
  when 'redhat', 'centos'
    package_name 'httpd'
  when 'ubuntu', 'debian'
    package_name 'apache2'
  end
end

# Install the required Postgres information.
package "postgresql"
package "postgresql-contrib"

# Setup the Template for postgres credentials
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

# Here we could probably add the steps to create the postgres database and add the user 
# but we will skip this as it isn't required for the challenge.

# Determine the binary name by looking at the complete URI.  The file extension and name exists in this
# path so we can infer the downloaded file name and extention by splitting the slashes (/) and selecting
# the last item in the array [-1]
binary_name = (location_bag_item['package']).split('/')[-1]

# From here, we can download the binary and use the 
remote_file "/usr/downloads/#{binary_name}" do
  source location_bag_item['package']
  checksum location_bag_item['checksum']
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# The package will be installed as the base name.  So we need to strip the extension.  The below call will
# do this without the need of knowing what type of extenion it is.
package ::File.basename(binary_name, '.*') do
  source "/usr/downloads/#{binary_name}"
  action :install
end
