# CyPerf-on-AWS-1-App-2-Agents-1-VPC-1-Public-Subnet-2-Private-Subnets

## Description
This deployment creates a topology with a single virtual private cloud having a single public facing subnet and two private subnets.

## Optional Variables
```
terraform.aws.auto.tfvars
terraform.optional.auto.tfvars
```
You **MAY** uncomment one or more lines as needed in these files and replace values to match your particular environment.

## Required Usage
```
make all
make clean
```

## Optional Usage
```
make validate
make plan
make state
make output
```