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
	rm -f .sshkey.pem
	terraform output SshKey | tail -n +3 | head -n-3 | sed "s/^[ \t]*//" > .sshkey.pem
	chmod 400 .sshkey.pem

state:
	time terraform state list