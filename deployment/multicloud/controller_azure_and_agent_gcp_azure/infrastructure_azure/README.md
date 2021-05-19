# Terraform deployments

# Introduction

This is the Terraform approach for Cyperf Application and Cyperf Agents in different cloud providers.

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

terraform apply -var=&quot;client\_secret=11111111-0000-0000-0000-11111111111&quot;

The -var option must be applied multiple times to use all the required input parameters.

## Template Parameters

The following table lists the parameters for this deployment.

| **Parameter label (name)**                  | **Default**            | **Description**  |
| ----------------------- | ----------------- | ----- |
| azure_owner_tag | Requires input | The Azure owner tag name. |
| azure_project_name     | Requires input   | Specify Azure project name. |
| azure_project_tag | keysight-azure-cyperf |The Azure project tag name. |
| azure_region_name      | Requires input       | The Azure region where the deployment will take place. |
| subscription_id     | Requires input   | Specify the Azure subscription id.    |
| client_id       | Requires input   | Specify the Azure client id.   |
| client_secret     | Requires input     | Specify the Azure client secret.   |
| tenant_id       | Requires input    | Specify the Azure tenant id.   |

## Destruction

The terraform destroy command will destroy the previous deployed infrastructure.
If the deployment was done using -var options, you will also need to provide the same set of parameters to the terraform destroy command

terraform destroy -var input\_variable=&quot;value&quot;

If you used **terraform apply** in conjunction with **.tfvars** file, you will not need to provide the parameters.