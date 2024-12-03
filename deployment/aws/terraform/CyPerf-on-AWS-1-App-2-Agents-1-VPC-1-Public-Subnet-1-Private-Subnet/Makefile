SHELL := /bin/bash

all: install init apply

clean: install state destroy

install:
ifeq ($(shell grep "^ID=" /etc/*elease | cut -d "=" -f 2| sed -e 's/^"//' -e 's/"$$//' 2> /dev/null), amzn)
ifeq ($(shell command -v terraform 2> /dev/null),)
	sudo yum install -y yum-utils
	sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
	sudo yum -y install terraform
endif

init:
	time terraform init

validate:
	time terraform validate

plan:
	time terraform plan

apply:
	time terraform apply -auto-approve

destroy:
	time terraform destroy -auto-approve

output:
	time terraform output AppEth0ElasticIp

state:
	time terraform state list