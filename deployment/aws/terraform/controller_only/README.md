# Terraform deployments

# Introduction

This is the Terraform approach for CyPerf Application and CyPerf Agents in different cloud providers.

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

terraform apply --auto-approve\
-var aws_auth_key="id_rsa_ghost”\
-var aws_stack_name="test" \
-var aws_access_key="" \
-var aws_secret_key=""

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
| aws_access_key | Requires input | The AWS access key must be obtained using following specification https://docs.aws.amazon.com/powershell/latest/userguide/pstools-appendix-sign-up.html. |
| aws_secret_key  | Requires input | The AWS secret key must be obtained using following specification https://docs.aws.amazon.com/powershell/latest/userguide/pstools-appendix-sign-up.html. |
| aws_stack_name | Requires input |The AWS stack name. |
| aws_auth_key | Requires input | Specify the AWS SSH key name. |
| aws_allowed_cidr | ["0.0.0.0/0"] |List of ip allowed to access the deployed machines. |
| aws_region            | us-east-2   | The AWS region for deployment. |
| availability_zone      | us-east-2a       | The AWS availability zone for deployment. |
| aws_mdw_machine_type   | c4.2xlarge   | The machine type used for deploying the CyPerf controller. |
| mdw_version   | keysight-cyperf-controller-2-1           | The CyPerf controller image version. |
| mdw_product_code   | 8nmwoluc06w5z6vbutcwyueje           | The CyPerf controller marketplace product code. |

## Destruction

The terraform destroy command will destroy the previous deployed infrastructure.
If the deployment was done using -var options, you will also need to provide the same set of parameters to the terraform destroy command

terraform destroy -var input\_variable=&quot;value&quot;

If you used **terraform apply** in conjunction with **.tfvars** file, you will not need to provide the parameters.