# CyPerf-on-Azure-1-App-2-Agents-2-Vnets-1-Public-Subnet-1-Private-Subnet

## Description
This deployment creates a topology with two virtual networks, both having a single public facing subnet and a single private subnet each.

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