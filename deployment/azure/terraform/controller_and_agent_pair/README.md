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

The -var option can be applied multiple times in order to use multiple parameters.

## Template Parameters

The following table lists the parameters for this deployment.

| **Parameter label (name)**                  | **Default**            | **Description**  |
| ----------------------- | ----------------- | ----- |
| AZURE_PROJECT_NAME     | Requires input   | Specify Azure project name. |
| AZURE_REGION_NAME      | eastus       | The Azure region where the deployment will take place. |
| AZURE_OWNER_TAG | Requires input | The Azure owner tag name. |
| AZURE_ADMIN_USERNAME  | cyperf | The Azure administrator username. |
| AZURE_PROJECT_TAG | keysight-gcp-cyperf |The Azure project tag name. |
| AZURE_MDW_MACHINE_TYPE | Standard_F8s_v2 | The machine type used for deploying the CyPerf controller. |
| AZURE_AGENT_MACHINE_TYPE   | Standard_F16s_v2   | The machine type used for deploying the CyPerf agent. |
| mdw_version   | keysight-cyperf-controller-1-0            | The  CyPerf controller image version. |
| agent_version   | keysight-cyperf-agent-1-0            | The  CyPerf agent image version. |
| subscription_id     | Requires input   | Specify the Azure subscription id.    |
| client_id       | Requires input   | Specify the Azure client id.   |
| client_secret     | Requires input     | Specify the Azure client secret.   |
| tenant_id       | Requires input    | Specify the Azure tenant id.   |

## Destruction

The terraform destroy command will destroy the previous deployed infrastructure.