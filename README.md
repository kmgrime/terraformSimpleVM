# terraformSimpleVM

A simple deployment of a linux vm in Azure

## Description
Deploys a network with a subnet and a ubuntu 16.04 LTS VM on top.

## Deployment
### Includes
- prefix
- resource group
- network
- subnet
- nic
- pip
- nsg
- vm
- output

### Info
- Remember to change the username and password in main.tf before deployment.

- It may take up to 5-10minutes before the image is fully deployed so that you can log in with ssh.

- Further documentation can be found on (https://registry.terraform.io/)  **Easier to google with the term ex: terraform azure vm**
