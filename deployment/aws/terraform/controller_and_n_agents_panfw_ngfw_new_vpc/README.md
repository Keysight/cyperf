# Terraform deployments

# Introduction

This Terraform sciprt deploy CyPerf Controller, CyPerf Agents and firewalls in aws cloud providers.

All the necessary resources will be created from scratch, including VPC, subnets, route table, Internet Gateway, PAN FW, NGFW etc.

# Prerequisites

- Latest version of Terraform installed. https://learn.hashicorp.com/tutorials/terraform/install-cli

- Credentials for each specific cloud provider need to pe provided.

# How to use:

## Initialization

The  **terraform init ** command is used to initialize a working directory containing Terraform configuration files. This is the first command that should be run after writing a new Terraform configuration or cloning an existing one from version control. It is safe to run this command multiple times.

This command is required the first time you use as template. It is not required to use it unless you modify the template.

## Deployment

A python script 'cyperf_e2e.py' will deploy entire topology using terraform and retrun CyPerf controller IP.

```python3 cyperf_e2e.py```

Note: Create terraform.tfvars and store aws cli credentials as described in the below example, before executing python script. 


The  **terraform apply**  command executes the actions proposed in a terraform template. All the default deployment variables may be changed.

### 1. Using the **-var** command

terraform apply -var input\_variable=&quot;value&quot;

The -var option must be applied multiple times to use all the required input parameters.

If no -var option is applied, upon running terraform apply, you will be asked for a value for each required variable.

#### Example

terraform apply --auto-approve\
-var aws_auth_key="name of the auth key in cloud”\
-var aws_stack_name="test" \
-var aws_access_key="key" \
-var aws_secret_key="key"


### 2. Writing all the input variables in the terraform.tfvars before running terraform apply

In the same folder, create a file named terraform.tfvars.

The inside contents should look like this:

variable_1= "value\_1"

variable_2= "value\_2"

Using this method you can ensure that all further deployments will be done with the same combination of parameters.

**terraform apply** , will look inside the file and match all the variable with the ones found in the variable.tf## Destruction

### 3. CyPerf terraform script for AWS 
 
This template deploys:

- One CyPerf Controller, in a public subnet.

- n no of CyPerf Client and Server Agents in same VPC, having two interfaces each. There is aws Network firewall and PAN Firewall between client and server agents. . All test traffic pass through firewalls.

### 4. exposed terraform variables 

"aws_region" - "specify aws region where to deploy"

"availability_zone" - "specify aws zone where to deploy"
 
"aws_main_cidr" - "client & firewall vpc cidr"

"aws_srv_cidr" - "server vpc cidr"

"aws_mgmt_cidr" - "client mgmt subnet cidr"

"aws_srv_mgmt_cidr" - "server mgmt subnet cidr"

"aws_cli_test_cidr" - "client test subnet cidr for aws nfw"

"aws_cli_test_cidr_pan" - "client test subnet cidr for pan fw"

"aws_srv_test_cidr" - "server test subnet cidr for aws nfw"

"aws_srv_test_cidr_pan" - "server test subnet cidr for pan fw"

"aws_firewall_cidr" - "firewall subnet cidr"

"aws_access_key" - "AWS-cli access key"

"aws_secret_key" - "AWS-cli secret key"

"aws_stack_name" - "Stack name, prefix for all resources"

"aws_owner" - "tag added to all resources"

"aws_auth_key" - "The key used to ssh into EC2s"

"aws_allowed_cidr" - "List of ip allowed to access the deployed machines"

"aws_mdw_machine_type" - "MDW instance type"

"aws_agent_machine_type" - "Agent machines instance type"

"clientagents" - "Number of clients to be deployed for aws fw"

"serveragents" - "Number of servers to be deployed for aws fw"

"clientagents_pan" - "Number of clients to be deployed for pan fw"

"serveragents_pan" - "Number of servers to be deployed pan fw"

"controller_username" - "Controller's authentication username"
  
"controller_password" - "Controller's authentication password"

"panfw_bootstrap_bucket" - "Bucket name for pan firewall bootstrap configuration"

Refer variables.tf for default values.

## 5. Destruction

The terraform destroy command will destroy the previous deployed infrastructure.
If the deployment was done using -var options, you will also need to provide the same set of parameters to the terraform destroy command

terraform destroy -var input\_variable=&quot;value&quot;

If you used **terraform apply** in conjunction with **.tfvars** file, you will not need to provide the parameters.

## 6. Workspaces

There are certain cases where multiple deployments are required using the same terraform template. To keep the previous deployments states intact, we recommend using the **workspace** feature of the terraform. This will help you to preserve the state of the previous deployments, allowing you to modify/destroy whenever you wish, while also enabling you to create multiple deployments of the same infrastructure.


**terraform workspace** has 5 main options

- **create {workspace_name}** will create a workspace
- **list** will list all the existing workspaces
- **select {workspace_name}** will select a workspace
- **show** will print the current selected workspace
- **delete {workspace_name}** will delete the selected workspace

For more information, please refer to the official terraform documentation:
https://www.terraform.io/docs/language/state/workspaces.html