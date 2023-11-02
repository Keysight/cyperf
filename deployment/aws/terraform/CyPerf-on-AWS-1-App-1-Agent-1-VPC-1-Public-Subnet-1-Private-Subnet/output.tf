output "AgentAmi" {
	value = {
		"image_id" : module.Agent1.Ami.image_id
		"name" : module.Agent1.Ami.name
		"owner_id" : module.Agent1.Ami.owner_id
	}
}

output "AppAmi" {
	value = {
		"image_id" : module.App.Ami.image_id
		"name" : module.App.Ami.name
		"owner_id" : module.App.Ami.owner_id
	}
}

output "AppEth0ElasticIp" {
	value = {
		"public_dns" : module.App.Eth0ElasticIp.public_dns
		"public_ip" : module.App.Eth0ElasticIp.public_ip
	}
}

output "AvailabilityZones" {
	value = {
		"available.names" : data.aws_availability_zones.available.names
	}
}