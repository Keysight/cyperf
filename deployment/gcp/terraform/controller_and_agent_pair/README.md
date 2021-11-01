# Terraform deployments

# Introduction

This is the Terraform approach for CyPerf Controller and CyPerf Agents in different cloud providers.

All the necessary resources will be created from scratch, including VPC, subnets, route table, Internet Gateway, Nat-gateway etc.

# Prerequisites

1. Latest version of Terraform installed. https://learn.hashicorp.com/tutorials/terraform/install-cli

2. Credentials for each specific cloud provider need to pe provided.

3. Upload bellow files in the system where terraform installed. 
- [main.tf](main.tf)
- [variables.tf](variables.tf)

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
-var gcp_project_name="kt-nas-cyperf-dev" \
-var gcp_owner_tag="test"  \
-var gcp_ssh_key="/Users/genitroi/Desktop/workspace/master/appsec-automation/appsec/resources/ssh_keys/id_rsa_ghost.pub"  \
-var gcp_credential_file="/Users/genitroi/Desktop/workspace/master/appsec-automation/appsec/resources/credentials/gcp/kt-nas-cyperf-dev-5b29ff75f49a.json"

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
| gcp_owner_tag  | Requires input | The GCP owner tag name. |
| gcp_credential_file   | Requires input   | The GCP credentials json file must be created using the following specifications https://cloud.google.com/iam/docs/creating-managing-service-account-keys. |
| gcp_ssh_key | Requires input | The GCP public SSH key file path. |
| gcp_region_name      | us-east1       | The GCP region where the deployment will take place. |
| gcp_zone_name | us-east1-b | The GCP zone where the deployment will take place. |
| gcp_project_tag | keysight-gcp-cyperf |The GCP project tag name. |
| gcp_allowed_cidr | ["0.0.0.0/0"] |The GCP allowed CIDR. |
| gcp_mdw_machine_type    | n1-standard-4   | The machine type used for deploying the CyPerf controller.  |
| gcp_agent_machine_type   | c2-standard-16            | The machine type used for deploying the CyPerf agent. |
| mdw_version            | keysight-cyperf-controller-1-1   | The  CyPerf controller image version.    |
| agent_version       | keysight-cyperf-agent-1-1     | The CyPerf agent image version.   |

## Destruction

The terraform destroy command will destroy the previous deployed infrastructure.
If the deployment was done using -var options, you will also need to provide the same set of parameters to the terraform destroy command

terraform destroy -var input\_variable=&quot;value&quot;

If you used **terraform apply** in conjunction with **.tfvars** file, you will not need to provide the parameters.