# About CyPerf Azure ARM Templates
## Introduction
Welcome to the GitHub repository for Keysight CyPerf ARM templates for deploying CyPerf with Azure portal.

To start using CyPerf's ARM templates, please refer the **README** files in each individual directory and decide on which template to start with from the below list. 

## Prerequisites
The prerequisites are:
- SSH Key pair for management access to CyPerf instances.
- For existing VNET deployment, an existing VNET, two existing subnets in that VNET (one for test and one for Management) and existing security groups for CyPerf Controller and CyPerf Agent.
- User should have atlest Contributor IAM role. This is Azure BuiltInRole.

Note:
    JSON format for Contributor role

    {
        "id": "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c",
        "properties": {
            "roleName": "Contributor",
            "description": "Grants full access to manage all resources, but does not allow you to assign roles in Azure RBAC, manage assignments in Azure Blueprints, or share image galleries.",
            "assignableScopes": [
                "/"
            ],
            "permissions": [
                {
                    "actions": [
                        "*"
                    ],
                    "notActions": [
                        "Microsoft.Authorization/*/Delete",
                        "Microsoft.Authorization/*/Write",
                        "Microsoft.Authorization/elevateAccess/Action",
                        "Microsoft.Blueprint/blueprintAssignments/write",
                        "Microsoft.Blueprint/blueprintAssignments/delete",
                        "Microsoft.Compute/galleries/share/action"
                    ],
                    "dataActions": [],
                    "notDataActions": []
                }
            ]
        }
    }   

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
