# Terraform deployments

# Introduction

This is the Terraform approach for CyPerf Controller and CyPerf Agents in different cloud providers.

All the necessary resources will be created from scratch, including VPC, subnets, route table, Internet Gateway, Nat-gateway etc.

This scenario, in particular, tackles a multi-cloud deployment, with an agent placed along with the controller in AZURE, and another placed in GCP with a controller proxy.

# Prerequisites

- Latest version of Terraform installed. https://learn.hashicorp.com/tutorials/terraform/install-cli

- Credentials for each specific cloud provider need to pe provided.

# How to use:

## Initialization

The  **terraform init ** command is used to initialize a working directory containing Terraform configuration files. This is the first command that should be run after writing a new Terraform configuration or cloning an existing one from version control. It is safe to run this command multiple times.

This command is required the first time you use a template. It is not required to use it unless you modify the template.

## Deployment

The  **terraform apply**  command executes the actions proposed in a terraform template. All the default deployment variables may be changed.

### 1. Using the **-var** command

terraform apply -var input\_variable=&quot;value&quot;

The -var option must be applied multiple times to use all the required input parameters.

If no -var option is applied, upon running terraform apply, you will be asked for a value for each required variable.

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
| gcp_project_name            | Requires input   | Specify the GCP project name. |
| gcp_credential_file   | Requires input   | The GCP credentials json file must be created using the following specifications https://cloud.google.com/iam/docs/creating-managing-service-account-keys. |
| azure_project_name     | Requires input   | Specify Azure project name. |
| deployment_name | Requires input | Prefix for all cloud resources. |
| subscription_id     | Requires input   | Specify the Azure subscription id.    |
| client_id       | Requires input   | Specify the Azure client id.   |
| client_secret     | Requires input     | Specify the Azure client secret.   |
| tenant_id       | Requires input    | Specify the Azure tenant id.   |
| public_key       | Requires input    | Specify the public key that will be used to auth into the vms.   |
| gcp_region_name      | us-east1       | The GCP region where the deployment will take place. |
| gcp_zone_name | us-east1-b | The GCP zone where the deployment will take place. |
| gcp_project_tag | keysight-gcp-cyperf |The GCP project tag name. |
| azure_region_name      | eastus       | The Azure region where the deployment will take place. |
| azure_admin_username  | cyperf | The Azure administrator username. |
| azure_project_tag | keysight-azure-cyperf |The Azure project tag name. |
| controller_image       | Requires input    | Specify the Azure controller VHD image |
| agent_image | Requires input    | Specify the Azure agent VHD image |
| mdw_version   | keysight-cyperf-controller-4-0            | The  CyPerf controller image version. |
| agent_version   | keysight-cyperf-agent-4-0           | The  CyPerf agent image version. |
| broker_image            | keysight-cyperf-controller-proxy-4-0   | The  CyPerf controller proxy image version.    |
| gcp_broker_machine_type   | n1-standard-2            | The machine type used for deploying the CyPerf controller proxy. |
| gcp_agent_machine_type   | c2-standard-4            | The machine type used for deploying the CyPerf agent. |
| azure_mdw_machine_type | Standard_F8s_v2 | The machine type used for deploying the CyPerf controller. |
| azure_agent_machine_type   | Standard_F4s_v2   | The machine type used for deploying the CyPerf agent. |


## Destruction

The terraform destroy command will destroy the previous deployed infrastructure.
If the deployment was done using -var options, you will also need to provide the same set of parameters to the terraform destroy command

terraform destroy -var input\_variable=&quot;value&quot;

If you used **terraform apply** in conjunction with **.tfvars** file, you will not need to provide the parameters.

## Configuring a B2B test in multicloud scenarios

![UI](configuration.png?raw=true "Test configuration")

When running a B2B test in multi-cloud you will need to specify the public test interface address of the server agent at the DUT section, to make it reachable for the client agent.
