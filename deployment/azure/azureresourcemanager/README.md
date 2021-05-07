# About Cyperf Azure ARM Templates
## Introduction
Welcome to the GitHub repository for Keysight CyPerf ARM templates for deploying CyPerf with Azure portal.

To start using CyPerf's ARM templates, please refer the **README** files in each individual directory and decide on which template to start with from the below list. 

## Prerequisites
The prerequisites are:
- SSH Key pair for management access to CyPerf instances.
- For existing VNET deployment, an existing VNET, two existing subnets in that VNET (one for test and one for Management) and existing security groups for  CyPerf Application and CyPerf Agent.
- Copy CyPerf VHD images to users own storage account. 

### Specialized knowledge
Before you deploy this Custom ARM template, we recommend that you become familiar with the following AWS services:
- [Deploy resources from custom template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-portal#deploy-resources-from-custom-template)
- [ARM Template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview)
- [Azure Resource Groups](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal)
- [Azure Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview)
- [Azure Virtual Network ](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
- [Azure Virtual Machines](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal)
- [ssh-keygen](https://www.ssh.com/academy/ssh/keygen)

**Note:** If you are new to Azure, see [Getting Started with Azure](https://azure.microsoft.com/en-in/get-started/).

## Supported instance types 
The supported instance types are:
- For CyPerf Controller, supported instance type Standard_F8s_v2.
- For CyPerf Agents, supported instance type Standard_F4s_v2 and Standard_F16s_v2.


## Copy VHD images 
Azure images will be available at Keysight Azure Blob container **keysight-cyperf-1-0**.
For accessing VHD file refer to the URL link:

 [https://cyperf.blob.core.windows.net/keysight-cyperf-1-0/](https://cyperf.blob.core.windows.net/keysight-cyperf-1-0/)

User may download VHD images and upload those in their own container before using these ARM templates.
Alternatively, user may use following PowerShell command from Azure cloud shell to copy VHD images from Keysight Azure container to User’s Azure container.

### Keysight SAS token for Keysight storage account CyPerf
```
?sv=2020-02-10&ss=b&srt=co&sp=rl&se=2031-04-26T20:08:16Z&st=2021-04-26T12:08:16Z&spr=https&sig=%2Fr0ENUs2QXp3g0%2BdcGwAwcpNAf06aeI4W7WuEmQ6xP8%3D

```
### Pre-requisite for PowerShell command execution:
1.	User’s own Azure storage account name
2.	User’s own Azure container name.
3.	User’s own SAS key for their storage account.

### Execution of PowerShell command:
1.	Open PowerShell window from Azure portal 
2.	Execute:

```
# azcopy copy
"https://cyperf.blob.core.windows.net/keysight-cyperf-1-0/<Keysight SAS-token>"  "https://<User’s storage name where file need to be copied>.blob.core.windows.net/< User’s container name>/<SAS-token>" 
--recursive=true

```

**Note:** Please replace string placed in **<>** with proper value.

### List of Supported CyPerf ARM templates for Azure deployments 

The following is a list of the current supported CyPerf ARM templates. Click the links to view the README files which include the topology diagrams. 

### I. [controller_and_agent_pair](controller_and_agent_pair): 
 

This template deploys: 


- One CyPerf Controller, in a public subnet. 

- Two CyPerf Agents, both having two interfaces each. Both Agent interfaces are in a private subnet. 


Select **New VNET** to deploy a new VPC or **Existing VNET** to deploy in an already existing VPC.

### II. [controller_proxy_and_agent_pair](controller_proxy_and_agent_pair):


This template deploys: 


- One CyPerf Controller Proxy, in a public subnet. 

- Two CyPerf Agents, both having two interfaces each. Both Agent interfaces are in a private subnet. 


Select **New VNET** to deploy a new VET or **Existing VNET** to deploy in an already existing VNET. 

## Troubleshooting and Known Issues 

### Known Limitations

### Troubleshooting
[Common Azure deployment errors](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/common-deployment-errors)
