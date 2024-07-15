# CyPerf-on-AWS-1-App-2-Agents-1-VPC-1-Public-Subnet-1-Private-Subnet

## Description
This deployment creates a topology with a single virtual private cloud having a single public facing subnet and a single private subnet.

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