# aig_project Cookbook

"Customer Alpha" needs a CHEF cookbook. 

The cookbook must deploy a three-tier web application (their options are Apache, Postgres, and Custom application binary).  
These applications must run on any chosen platform (they can select from Redhat, Centos, and Ubuntu).  
Apache and Postgres can be installed using the 'package' Chef Resource.  
There is also an additional custom binary (located at https://customeralpha.org/appbincustom).  
The binary must be chosen based on their location requirements, by using a data_bag item to download the installer (rpm for Redhat and deb for Ubuntu). 
There should be a template file into which the postgres database user and password will be added (in clear text).  
This recipe must fail, and provide a clearly understood exception, if they attempt to run it against a Windows System.
Customer Alpha environment details:
·         "LocA" is what they call their primary datacenter.
·         "LocB" "LocC" are various cloud locations or alternate datacenters.
·         "LocA" should use https://customeralpha.org/appbincustom
·         Non-LocA should use (LocB) https://locb.customeralpha.org/appbincustom or (LocC) https://locc.customeralpha.org/appbincustom
·         Customer should have the option of also using "LocB", "LocC" - as alternative locations for platform deployment.

## Requirements

This cookbook as per the original requirements, needs a parameter to be passed for the location preference (to download custom package from a user preferred location). It can be passed either from kitchen attribute (for testing) or in a role json or env json files (for real usage). 

This parameter is reffered by a variable #{loc_pref} in the recipe to decide on which site to go to for the file download.

## Data bags

A data bag needs to be created for the values for determinig installer type ( redhat - rpm or ubuntu - deb ). This databag items are reffered in the recipe.

knife data bag create installer_info
knife data bag create installer_info installer_type.json

installer_type.json

{
  "id": "install_type",
  "redhat": "rpm",
  "ubuntu": "deb"
}

e.g.
### Platforms

- Linux or Ubuntu , but not windows



### Cookbooks

- aig_project 

## Attributes

default['aig_project']['loc_choice'] = ''
default['aig_project']['db_root_user'] = 'postgres'
default['aig_project']['db_root_passwd'] = 'qaz123wsx'

e.g.
### aig_project::default

TODO: Write usage instructions for each cookbook.

e.g.
Just include `aig_project` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[aig_project]"
  ]
}
```

