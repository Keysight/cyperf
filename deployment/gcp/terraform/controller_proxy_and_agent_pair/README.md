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

terraform apply -var=&quot;GCP_CREDENTIALS_FILE=gcp-credentials.json&quot;

The -var option must be applied multiple times to use all the required input parameters.

## Template Parameters

The following table lists the parameters for this deployment.

| **Parameter label (name)**                  | **Default**            | **Description**  |
| ----------------------- | ----------------- | ----- |
| GCP_PROJECT_NAME            | Requires input   | Specify the GCP project name. |
| GCP_REGION_NAME      | us-east1       | The GCP region where the deployment will take place. |
| GCP_ZONE_NAME | us-east1-b | The GCP zone where the deployment will take place. |
| GCP_OWNER_TAG  | Requires input | The GCP owner tag name. |
| GCP_PROJECT_TAG | keysight-gcp-cyperf |The GCP project tag name. |
| GCP_SSH_KEY | Requires input | The GCP public SSH key file path. |
| GCP_CREDENTIALS_FILE   | Requires input   | The GCP credentials json file must be created using the following specifications https://cloud.google.com/iam/docs/creating-managing-service-account-keys. |
| GCP_BROKER_MACHINE_TYPE   | n1-standard-2            | The machine type used for deploying the CyPerf controller proxy. |
| GCP_AGENT_MACHINE_TYPE   | c2-standard-16            | The machine type used for deploying the CyPerf agent. |
| broker_image            | keysight-cyperf-controller-proxy-1-0   | The  CyPerf controller proxy image version.    |
| agent_version       | keysight-cyperf-agent-1-0     | The CyPerf agent image version.   |
| network_name       | load-balancer-net     | The Load Balancer network name.   |
| ssl_certificate       | Requires input    | SSL certificate for https load balancers.   |


## Destruction

The terraform destroy command will destroy the previous deployed infrastructure.