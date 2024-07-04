# About CyPerf Azure ARM Templates
## Introduction
Welcome to the GitHub repository for Keysight CyPerf ARM templates for deploying CyPerf with Azure portal.

To start using CyPerf's ARM templates, please refer the **README** files in each individual directory and decide on which template to start with from the below list. 

## Prerequisites
The prerequisites are:
- SSH Key pair for management access to CyPerf instances.
- For existing VNET deployment, an existing VNET, two existing subnets in that VNET (one for test and one for Management) and existing security groups for CyPerf Controller and CyPerf Agent.
- Copy CyPerf VHD images to users own storage account. 

### Specialized knowledge
Before you deploy this Custom ARM template, we recommend that you become familiar with the following Azure services:
- [Deploy resources from custom template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-portal#deploy-resources-from-custom-template)
- [ARM Template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview)
- [Azure Resource Groups](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal)
- [Azure Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview)
- [Azure Virtual Network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
- [Azure Virtual Machines](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal)
- [ssh-keygen](https://www.ssh.com/academy/ssh/keygen)

**Note:** If you are new to Azure, see [Getting Started with Azure](https://azure.microsoft.com/en-in/get-started/).

## Supported instance types 
The supported instance types are:
- For CyPerf Controller, supported instance type Standard_F8s_v2.
- For CyPerf Agents, supported instance type Standard_F4s_v2 and Standard_F16s_v2.


## Copy VHD images 
Azure images will be available at Keysight Azure Blob container **keysight-cyperf-4-0**.
For accessing VHD file refer to the URL link:

 - [https://cyperf.blob.core.windows.net/keysight-cyperf-4-0/keysight-cyperf-controller-4-0.vhd](https://cyperf.blob.core.windows.net/keysight-cyperf-4-0/keysight-cyperf-controller-4-0.vhd)
 - [https://cyperf.blob.core.windows.net/keysight-cyperf-4-0/keysight-cyperf-agent-4-0.vhd](https://cyperf.blob.core.windows.net/keysight-cyperf-4-0/keysight-cyperf-agent-4-0.vhd)
 - [https://cyperf.blob.core.windows.net/keysight-cyperf-4-0/keysight-cyperf-controller-proxy-4-0.vhd](https://cyperf.blob.core.windows.net/keysight-cyperf-4-0/keysight-cyperf-controller-proxy-4-0.vhd)

User may download VHD images and upload those in their own container before using these ARM templates.
Alternatively, user may use following PowerShell command from Azure cloud shell to copy VHD images from Keysight Azure container to User’s Azure container.

### Keysight SAS token for Keysight storage account CyPerf
```
?sv=2022-11-02&ss=bf&srt=sco&sp=rtfx&se=2027-03-03T00:15:52Z&st=2023-09-01T15:15:52Z&spr=https,http&sig=Arrk0YOcgswuUyE4jteX7I%2FU5Q7NPz%2FaY7922KMAsWA%3D
```

### Pre-requisite for PowerShell command execution:
1.	User’s own Azure storage account name
2.	User’s own Azure container name.
3.	User’s own SAS key for their storage container. Make sure SAS key is generated at container level with read and write permission.

### Execution of PowerShell command:
1.	Open PowerShell window from Azure portal 
2.	Execute:

```
# azcopy copy 

# CyPerf Agent copy
azcopy copy 'https://cyperf.blob.core.windows.net/keysight-cyperf-4-0/keysight-cyperf-agent-4-0.vhd?sv=2022-11-02&ss=bf&srt=sco&sp=rtfx&se=2027-03-03T00:15:52Z&st=2023-09-01T15:15:52Z&spr=https,http&sig=Arrk0YOcgswuUyE4jteX7I%2FU5Q7NPz%2FaY7922KMAsWA%3D' 'https://<User’s storage name where file need to be copied>.blob.core.windows.net/< User’s container name>/<SAS-token>’

# CyPerf Controller copy
azcopy copy 'https://cyperf.blob.core.windows.net/keysight-cyperf-4-0/keysight-cyperf-controller-4-0.vhd?sv=2022-11-02&ss=bf&srt=sco&sp=rtfx&se=2027-03-03T00:15:52Z&st=2023-09-01T15:15:52Z&spr=https,http&sig=Arrk0YOcgswuUyE4jteX7I%2FU5Q7NPz%2FaY7922KMAsWA%3D' 'https://<User’s storage name where file need to be copied>.blob.core.windows.net/< User’s container name>/<SAS-token>’

# CyPerf Controller-proxy copy
azcopy copy 'https://cyperf.blob.core.windows.net/keysight-cyperf-4-0/keysight-cyperf-controller-proxy-4-0.vhd?sv=2022-11-02&ss=bf&srt=sco&sp=rtfx&se=2027-03-03T00:15:52Z&st=2023-09-01T15:15:52Z&spr=https,http&sig=Arrk0YOcgswuUyE4jteX7I%2FU5Q7NPz%2FaY7922KMAsWA%3D' 'https://<User’s storage name where file need to be copied>.blob.core.windows.net/< User’s container name>/<SAS-token>’

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
