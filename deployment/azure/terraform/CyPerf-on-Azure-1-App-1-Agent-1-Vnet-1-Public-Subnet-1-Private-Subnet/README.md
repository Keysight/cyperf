# CyPerf-on-Azure-1-App-1-Agent-1-Vnet-1-Public-Subnet-1-Private-Subnet

## Description
This deployment creates a topology with a single virtual network having a single public facing subnet and a single private subnet.

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