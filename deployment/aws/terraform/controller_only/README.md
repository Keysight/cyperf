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

terraform apply -var=&quot;aws\_auth\_key=my_rsa_key&quot;

The -var option must be applied multiple times to use all the required input parameters.

## Template Parameters

The following table lists the parameters for this deployment.

| **Parameter label (name)**                  | **Default**            | **Description**  |
| ----------------------- | ----------------- | ----- |
| aws_region            | us-east-2   | The AWS region for deployment. |
| availability_zone      | us-east-2a       | The AWS availability zone for deployment. |
| aws_access_key | Requires input | The AWS access key must be obtained using following specification https://docs.aws.amazon.com/powershell/latest/userguide/pstools-appendix-sign-up.html. |
| aws_secret_key  | Requires input | The AWS secret key must be obtained using following specification https://docs.aws.amazon.com/powershell/latest/userguide/pstools-appendix-sign-up.html. |
| aws_stack_name | Requires input |The AWS stack name. |
| aws_auth_key | Requires input | Specify the AWS SSH key name. |
| aws_mdw_machine_type   | t2.xlarge   | The machine type used for deploying the CyPerf controller. |
| mdw_version   | keysight-cyperf-controller-1-0           | The CyPerf controller image version. |

## Destruction

The terraform destroy command will destroy the previous deployed infrastructure.