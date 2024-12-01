# Terraform deployments

# Introduction

This is the Terraform approach for CyPerf Controller and CyPerf Agents in different cloud providers.

All the necessary resources will be created from scratch, including VPC, subnets, route table, Internet Gateway, Nat-gateway etc.

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
-var azure_owner_tag="test" \  
-var azure_project_name="kt-nas-cyperf-dev" \  
-var subscription_id="" \  
-var client_id="" \  
-var client_secret="" \  
-var tenant_id="" \  
-var public_key="/Users/genitroi/Desktop/workspace/master/appsec-automation/appsec/resources/ssh_keys/id_rsa_ghost.pub"

### 2. Writing all the input variables in the terraform.tfvars before running terraform apply

In the same folder, create a file named terraform.tfvars.

The inside contents should look like this:

variable_1= "value\_1"

variable_2= "value\_2"

Using this method you can ensure that all further deployments will be done with the same combination of parameters.

**terraform apply** , will look inside the file and match all the variable with the ones found in the variable.tf
## Template Parameters

The following table lists the parameters for this deployment.

| **Parameter label (name)**                  | **Default**            | **Description**  |
| ----------------------- | ----------------- | ----- |
| azure_project_name     | Requires input   | Specify Azure project name. |
| azure_owner_tag | Requires input | The Azure owner tag name. |
| subscription_id     | Requires input   | Specify the Azure subscription id.    |
| client_id       | Requires input   | Specify the Azure client id.   |
| client_secret     | Requires input     | Specify the Azure client secret.   |
| tenant_id       | Requires input    | Specify the Azure tenant id.   |
| public_key       | Requires input    | Specify the Azure public key that will be used to auth into the vms.   |
| controller_image       | Requires input    | Specify the Azure controller VHD image |
| azure_allowed_cidr      | ["0.0.0.0/0"]       | Allowed IP ranges. Take into account also the ip ranges used in the management and test, subnets. |
| azure_region_name      | eastus       | The Azure region where the deployment will take place. |
| azure_admin_username  | cyperf | The Azure administrator username. |
| azure_project_tag | keysight-azure-cyperf |The Azure project tag name. |
| azure_mdw_machine_type | Standard_F8s_v2 | The machine type used for deploying the CyPerf controller. |
| mdw_name   | keysight-cyperf-controller-5-0            | Name for the cyperf controller machine. |

## Destruction

The terraform destroy command will destroy the previous deployed infrastructure.
If the deployment was done using -var options, you will also need to provide the same set of parameters to the terraform destroy command

terraform destroy -var input\_variable=&quot;value&quot;

If you used **terraform apply** in conjunction with **.tfvars** file, you will not need to provide the parameters.