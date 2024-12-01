# CyPerf-on-AWS-1-App-2-Agents-Add-On

## Description
This deployment creates resources that will be attached to an existing network topology.

## Required Variables
```
terraform.required.auto.tfvars
```
You **MUST** uncomment all lines in this file and replace values to match your particular environment.  
Otherwise, Terraform will prompt the user to supply input arguents via cli.

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