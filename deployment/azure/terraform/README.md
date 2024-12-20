# Terraform deployments

## Introduction

This is the Terraform approach for CyPerf Controller and CyPerf Agents in different cloud providers.

All the necessary resources will be created from scratch, including VPC, subnets, route table, Internet Gateway, Nat-gateway etc.

## Prerequisites

- Latest version of Terraform installed. https://learn.hashicorp.com/tutorials/terraform/install-cli

- Credentials for each specific cloud provider need to pe provided.

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

## Authentication parameters

You will need to provide 4 parameters in order to create those deployments:

1. subscription_id
2. client_id
3. client_secret
4. tenant_id

You can get those by following the Azure Active Directory (Azure AD) guide provided in the following link:

https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal

Check with your IT department for Registered App provisioning.