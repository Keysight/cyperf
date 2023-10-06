# Terraform deployments

# Introduction

This is the Terraform approach for deploying a single agent in an existing infrastructure.
If the agent is not deployed in the same subnet with a controller proxy or a controller,
the user needs to ensure the communication between the agent management subnet and controller management subnet.

# Prerequisites

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
-var azure_agent_name="agent" \  
-var subscription_id="" \  
-var client_id="" \  
-var client_secret="" \  
-var tenant_id="" \  
-var resource_group_name="" \  
-var resource_group_location="" \  
-var virtual_network_name="" \  
-var mgmt_subnet="" \  
-var test_subnet="" \  
-var controller_ip="" \  
-var public_key="/Users/genitroi/Desktop/workspace/master/appsec-automation/appsec/resources/ssh_keys/id_rsa_ghost.pub"

### 2. Writing all the input variables in the terraform.tfvars before running terraform apply

In the same folder, create a file named terraform.tfvars.

The inside contents should look like this:

variable_1= "value\_1"

variable_2= "value\_2"

Using this method you can ensure that all further deployments will be done with the same combination of parameters.

**terraform apply** , will look inside the file and match all the variable with the ones found in the variable.tf

For this deployment, we recommend this method, due to the large number of parameters that need to be provided.

## Template Parameters

The following table lists the parameters for this deployment.

| **Parameter label (name)**                  | **Default**            | **Description**  |
| ----------------------- | ----------------- | ----- |
| azure_agent_name | Requires input | The Azure agent name. |
| subscription_id     | Requires input   | Specify the Azure subscription id.    |
| client_id       | Requires input   | Specify the Azure client id.   |
| client_secret     | Requires input     | Specify the Azure client secret.   |
| tenant_id       | Requires input    | Specify the Azure tenant id.   |
| resource_group_name     | Requires input   | Specify Azure resource group name. |
| resource_group_location     | Requires input   | Specify Azure resource group location. |
| virtual_network_name     | Requires input   | Virtual network name. |
| mgmt_subnet | Requires input    | Management subnet id |
| test_subnet | Requires input    | Test subnet id |
| controller_ip | Requires input    | Test subnet id |
| public_key       | Requires input    | Specify the Azure public key that will be used to auth into the vms. (*.pub)   |
| cyperf_version   | 0.2.5            | CyPerf release version. |
| agent_version   | keysight-cyperf-agent-2-5            | The  CyPerf agent image version. |
| azure_agent_machine_type   | Standard_F16s_v2   | The machine type used for deploying the CyPerf agent. |
| agent_role | azure-agent | This will act as a tag in controller UI and will enable assignment by tag|

## Destruction

The terraform destroy command will destroy the previous deployed infrastructure.
If the deployment was done using -var options, you will also need to provide the same set of parameters to the terraform destroy command

terraform destroy -var input\_variable=&quot;value&quot;

If you used **terraform apply** in conjunction with **.tfvars** file, you will not need to provide the parameters.

## AZ Login

For users who have configured the az CLI on their machine, you can use Terraform deployments only with the subscription id.
This means that the provider block, that can be found in the main.tf should look like this:

```terraform
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
//  client_id = var.client_id
//  client_secret = var.client_secret
//  tenant_id = var.tenant_id
}
```