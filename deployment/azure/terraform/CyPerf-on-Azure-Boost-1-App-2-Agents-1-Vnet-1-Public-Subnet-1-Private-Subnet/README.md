# CyPerf-on-Azure-Boost-1-App-2-Agents-1-Vnet-1-Public-Subnet-1-Private-Subnet

## Description
This deployment creates a topology with a single virtual network having a single public facing subnet and a single private subnet.

## Required Variables
```
terraform.required.auto.tfvars
```
You **MUST** uncomment all lines in this file and replace values to match your particular environment.  
Otherwise, Terraform will prompt the user to supply input arguents via cli.

## Optional Variables
```
terraform.azure.auto.tfvars
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