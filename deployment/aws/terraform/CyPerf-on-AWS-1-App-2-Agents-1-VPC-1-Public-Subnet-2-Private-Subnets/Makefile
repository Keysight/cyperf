SHELL := /bin/bash

all: init apply

clean: state destroy

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