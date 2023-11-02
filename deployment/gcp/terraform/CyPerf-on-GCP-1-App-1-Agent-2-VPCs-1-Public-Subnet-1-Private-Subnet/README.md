# CyPerf-on-GCP-1-App-1-Agent-2-VPCs-1-Public-Subnet-1-Private-Subnet

## Description
This deployment creates a topology with two virtual private clouds, one having a single public facing subnet and the other having a single private subnet.

## Required Variables
```
terraform.required.auto.tfvars
```
You **MUST** uncomment all lines in this file and replace values to match your particular environment.  
Otherwise, Terraform will prompt the user to supply input arguents via cli.

## Optional Variables
```
terraform.optional.auto.tfvars
```
You **MAY** uncomment one or more lines as needed in this file and replace values to match your particular environment.

## Required Usage
```
terraform init
terraform apply -auto-approve
terraform destroy -auto-approve
```

## Optional Usage
```
terraform validate
terraform plan
terraform state list
terraform output
```