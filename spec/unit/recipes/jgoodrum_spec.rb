#
# Cookbook:: aig_project
# Spec:: jgoodrum_spec
#
# maintainer:: Aig Cloud Team
# maintainer_email:: aigcloudautomations@aig.com
#
# Copyright:: 2017, Aig Cloud Team, All Rights Reserved.

require 'spec_helper'

describe 'aig_project::jgoodrum' do
  context 'Validate supported installations' do
    before do
      stub_data_bag_item('artifacts', 'custom_application').and_return(
        'loca' => {
          'rhel' => {
            'package' => 'https://customeralpha.org/appbincustom.rpm',
            'checksum' => '12345'
          },
          'debian' => {
            'package' => 'https://customeralpha.org/appbincustom.deb',
            'checksum' => '12345'
          }
        },
        'locb' => {
          'rhel' => {
            'package' => 'https://locb.customeralpha.org/appbincustom.rpm',
            'checksum' => '12345'
          },
          'debian' => {
            'package' => 'https://locb.customeralpha.org/appbincustom.deb',
            'checksum' => '12345'
          }
        },
        'locc' => {
          'rhel' => {
            'package' => 'https://locc.customeralpha.org/appbincustom.rpm',
            'checksum' => '12345'
          },
          'debian' => {
            'package' => 'https://locc.customeralpha.org/appbincustom.deb',
            'checksum' => '12345'
          }
        }
      )
    end
    platforms = {
      # 'redhat' => {
      #   'versions' => %w(6.8 7.2 7.3)
      # },
      # 'centos' => {
      #   'versions' => %w(6.8 7.2.1511 7.3.1611)
      # },
      'ubuntu' => {
        'versions' => %w(14.04 16.04)
      }
    }
    platforms.each do |platform, components|
      components['versions'].each do |version|
        context "On #{platform} #{version}" do
          context 'When all attributes are default' do
            before do
              Fauxhai.mock(platform: platform, version: version)
              # Node attributes
              node.normal['aig_project']['loc_choice'] = 'loca'
              node.normal['aig_project']['db_root_user'] = 'postgres'
              node.normal['aig_project']['db_root_passwd'] = '123'
            end
            let(:runner) do
              ChefSpec::SoloRunner.new(platform: platform, version: version)
            end
            let(:node) { runner.node }
            let(:chef_run) { runner.converge(described_recipe) }

            it 'converges successfully' do
              expect { chef_run }.to_not raise_error
              expect(chef_run).to create_directory('/usr/downloads').with(owner: 'root', mode: '0755')
              case node['platform_family']
              when 'rhel'
                expect(chef_run).to install_package('httpd')
              when 'debian'
                expect(chef_run).to install_package('apache2')
              end

              %w(postgresql postgresql-contrib).each do |pkg|
                expect(chef_run).to install_package(pkg)
              end

              expect(chef_run).to create_template('/etc/postgre_db_credentials').with(variables: { db_user: 'postgres', db_passwd: '123' } )

              case node['platform_family']
              when 'rhel'
                expect(chef_run).to create_remote_file('/usr/downloads/appbincustom.rpm').with(source: 'https://customeralpha.org/appbincustom.rpm')
                expect(chef_run).to install_package('appbincustom').with(source: '/usr/downloads/appbincustom.rpm')
              when 'debian'
                expect(chef_run).to create_remote_file('/usr/downloads/appbincustom.deb').with(source: 'https://customeralpha.org/appbincustom.deb')
                expect(chef_run).to install_package('appbincustom').with(source: '/usr/downloads/appbincustom.deb')
              end

            end

            it 'returns an error when db_root_user is not set' do
              node.normal['aig_project']['db_root_user'] = nil
              expect { chef_run }.to raise_error(ArgumentError, 'The postgres username and password must be supplied')
            end

            it 'returns an error when db_root_passwd is not set' do
              node.normal['aig_project']['db_root_passwd'] = nil
              expect { chef_run }.to raise_error(ArgumentError, 'The postgres username and password must be supplied')
            end

            it 'returns an error when data_bag (\'artifacts\',\'custom_application\') is not found' do
              stub_data_bag_item('artifacts', 'custom_application').and_return(nil)
              expect { chef_run }.to raise_error(ArgumentError, 'Unable to locate the DataBagItem("artifacts","custom_application")')
            end

            it 'returns an error when data_bag (\'artifacts\',\'custom_application\') is not found' do
              stub_data_bag_item('artifacts', 'custom_application').and_return(nil)
              expect { chef_run }.to raise_error(ArgumentError, 'Unable to locate the DataBagItem("artifacts","custom_application")')
            end

            # Location issues and tests
            it 'returns an error when chosen location is not found' do
              node.normal['aig_project']['loc_choice'] = nil
              expect { chef_run }.to raise_error(ArgumentError, 'The chosen location is not supported or the custom_application binary information not found.')
            end

            it 'returns an error when chosen location is not found' do
              node.normal['aig_project']['loc_choice'] = 'bad_location'
              expect { chef_run }.to raise_error(ArgumentError, 'The chosen location is not supported or the custom_application binary information not found.')
            end

            # Data bag details for OS and Location tests
            it 'returns an error when chosen location and platform_family is not included' do
              # We need to set the variable os_type to a value different than our current platform.
              case node['platform_family']
              when 'rhel'
                os_type = 'debian'
              when 'debian'
                os_type = 'rhel'
              end

              # We need to re-stub the databag with this new information.
              stub_data_bag_item('artifacts', 'custom_application').and_return(
                node['aig_project']['loc_choice'] => {
                  os_type => {
                    'package' => 'https://customeralpha.org/appbincustom.rpm',
                    'checksum' => '12345'
                  }
                }
              )
              expect { chef_run }.to raise_error(ArgumentError, 'The chosen location and OS type does not appear to have a supported binary path and was not found.')
            end
          end
        end
      end
    end
  end
  context 'Validate unsupported platforms' do
    platforms = {
      'windows' => {
        'versions' => %w(2012 2012r2)
      }
    }
    platforms.each do |platform, components|
      components['versions'].each do |version|
        context "On #{platform} #{version}" do
          context 'When all attributes are default' do
            before do
              Fauxhai.mock(platform: platform, version: version)
            end
            let(:chef_run) do
              ChefSpec::SoloRunner.new(platform: platform, version: version) do |node|
                # Node attributes
              end.converge(described_recipe)
            end

            it 'raises an exception' do
              expect { chef_run }.to raise_error(ArgumentError, "ERROR: Unsupported Operating system #{platform}. Please run this cookbook on RHEL/CENTOS and Ubuntu systems!!!")
            end
          end
        end
      end
    end
  end
end
