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

terraform apply -var=&quot;GCP_CREDENTIALS=gcp-credentials.json&quot;

The -var option can be applied multiple times in order to use multiple parameters.

## Topology
The multi-cloud topology deployed for this scenario is: 
- CyPerf controller in Azure
- CyPerf controller proxy in GCP
- Agents in Azure (x2), Agents in GCP (x2) 

Notes: 
1) If network infrastructure is already available in GCP and Azure only the following terraform deployments are needed:
- controller_and_agent_pair_azure
- controller_and_agent_pair_gcp
2) Otherwise, the following terraform deployments are also required to be run as pre-requisites:
- infrastructure_azure
- infrastructure_gcp

## Destruction

The terraform destroy command will destroy the previous deployed infrastructure.