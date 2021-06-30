# Terraform deployments

## Introduction

<<<<<<< HEAD
<<<<<<< HEAD
This is the Terraform approach for Cyperf Controller and Cyperf Agents in different cloud providers.
=======
This is the Terraform approach for CyPerf Application and CyPerf Agents in different cloud providers.
>>>>>>> 637ab90... Azure documentation changes for CyPerf 1.0-update1 release. Other small typo fixes.
=======
This is the Terraform approach for CyPerf Controller and CyPerf Agents in different cloud providers.
>>>>>>> 62ec55a... Updated CyPerf naming and other small typos in the readme files.

All the necessary resources will be created from scratch, including VPC, subnets, route table, Internet Gateway, Nat-gateway etc.

## Prerequisites

- Latest version of Terraform installed. https://learn.hashicorp.com/tutorials/terraform/install-cli

- Credentials for each specific cloud provider need to pe provided.

### Specialized knowledge
Before you deploy this Custom ARM template, we recommend that you become familiar with the following Azure services:
- [Create a custom image from a VHD file](https://docs.microsoft.com/en-us/azure/devtest-labs/devtest-lab-create-template)
- [ssh-keygen](https://www.ssh.com/academy/ssh/keygen)

**Note:** If you are new to Azure, see [Getting Started with Azure](https://azure.microsoft.com/en-in/get-started/).

## Copy VHD images 
Azure images will be available at Keysight Azure Blob container **keysight-cyperf-1-0-update1**.
For accessing VHD file refer to the URL link:

 - [https://cyperf.blob.core.windows.net/keysight-cyperf-1-0-update1/keysight-cyperf-controller-1-0-update1.vhd](https://cyperf.blob.core.windows.net/keysight-cyperf-1-0-update1/keysight-cyperf-controller-1-0-update1.vhd)
 - [https://cyperf.blob.core.windows.net/keysight-cyperf-1-0-update1/keysight-cyperf-agent-1-0-update1.vhd](https://cyperf.blob.core.windows.net/keysight-cyperf-1-0-update1/keysight-cyperf-agent-1-0-update1.vhd)
 - [https://cyperf.blob.core.windows.net/keysight-cyperf-1-0/keysight-cyperf-controller-proxy-1-0.vhd](https://cyperf.blob.core.windows.net/keysight-cyperf-1-0/keysight-cyperf-controller-proxy-1-0.vhd)

User may download VHD images and upload those in their own container before using these ARM templates.
Alternatively, user may use following PowerShell command from Azure cloud shell to copy VHD images from Keysight Azure container to User’s Azure container.

### Keysight SAS token for Keysight storage account CyPerf
```
?sv=2020-02-10&ss=bfqt&srt=sc&sp=rtfx&se=2023-10-22T19:51:35Z&st=2021-06-30T11:51:35Z&spr=https&sig=yLEthD8rYXuH0lSwP6mgB0w2Q4KQ1VLbvRTdnrNrt34%3D
```
### Keysight SAS token for Keysight container account CyPerf
```
sp=r&st=2021-06-30T11:54:22Z&se=2023-10-22T19:54:22Z&spr=https&sv=2020-02-10&sr=c&sig=5p0g90N8%2BYqjcZ88eVCbmE4ILSckbdjlauDh1%2BlSsoU%3D
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
"https://cyperf.blob.core.windows.net/keysight-cyperf-1-0-update1/<Keysight SAS-token>"  "https://<User’s storage name where file need to be copied>.blob.core.windows.net/< User’s container name>/<SAS-token>" 
--recursive=true

```

**Note:** Please replace string placed in **<>** with proper value.

# How to use:

## Initialization

The  **terraform init ** command is used to initialize a working directory containing Terraform configuration files. This is the first command that should be run after writing a new Terraform configuration or cloning an existing one from version control. It is safe to run this command multiple times.

This command is required the first time you use as template. It is not required to use it unless you modify the template.

## Deployment

The  **terraform apply**  command executes the actions proposed in a terraform template. All the default deployment variables may be changed.

### 1. Using the **-var** command

terraform apply -var input\_variable=&quot;value&quot;

The -var option must be applied multiple times to use all the required input parameters.

If no -var option is applied, upon running terraform apply, you will be asked for a value for each required variable.

#### Example

terraform apply --auto-approve \
-var azure_owner_tag="deployment_name" \
-var azure_project_name="project_name \
-var subscription_id="id" \
-var client_id="id " \
-var client_secret="secret" \
-var tenant_id="id" \
-var public_key="path/to/public/key" \
-var controller_image="path/to/azure/image/” \
-var agent_image="path/to/azure/image/”

### 2. Writing all the input variables in the terraform.tfvars before running terraform apply

In the same folder, create a file named terraform.tfvars.

The inside contents should look like this:

variable_1= "value\_1"

variable_2= "value\_2"

Using this method you can ensure that all further deployments will be done with the same combination of parameters.

**terraform apply** , will look inside the file and match all the variable with the ones found in the variable.tf

### List of Supported CyPerf terraform scripts for AZURE 

The following is a list of the current supported CyPerf terraform scripts. Click the links to view the README files.

### I. [Controller and Agent Pair](controller_and_agent_pair):
 

This template deploys:

- One CyPerf Controller, in a public subnet.

- Two CyPerf Agents, both having two interfaces each. Both Agent interfaces are in a Private subnet. 

### II. [Controller Proxy and Agent Pair](controller_proxy_and_agent_pair):


This template deploys:

- One CyPerf Controller Proxy, in a public subnet.

- Two CyPerf Agents, both having two interfaces each. Both Agent interfaces are in a Private subnet. 

### III. [Controller Only](controller_only):


This template deploys:

- One CyPerf Controller, in a public subnet.

## Destruction

The terraform destroy command will destroy the previous deployed infrastructure.
If the deployment was done using -var options, you will also need to provide the same set of parameters to the terraform destroy command

terraform destroy -var input\_variable=&quot;value&quot;

If you used **terraform apply** in conjunction with **.tfvars** file, you will not need to provide the parameters.

## Workspaces

There are certain cases where multiple deployments are required using the same terraform template. To keep the previous deployments states intact, we recommend using the **workspace** feature of the terraform. This will help you to preserve the state of the previous deployments, allowing you to modify/destroy whenever you wish, while also enabling you to create multiple deployments of the same infrastructure.


**terraform workspace** has 5 main options

- **create {workspace_name}** will create a workspace
- **list** will list all the existing workspaces
- **select {workspace_name}** will select a workspace
- **show** will print the current selected workspace
- **delete {workspace_name}** will delete the selected workspace

For more information, please refer to the official terraform documentation:
https://www.terraform.io/docs/language/state/workspaces.html