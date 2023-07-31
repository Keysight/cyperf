output "Agent1Eth0PublicIpAddress" {
	value = {
		"fqdn" : module.Agent1.Eth0PublicIpAddress.fqdn
		"ip_address" : module.Agent1.Eth0PublicIpAddress.ip_address
	}
}

output "Agent2Eth0PublicIpAddress" {
	value = {
		"fqdn" : module.Agent2.Eth0PublicIpAddress.fqdn
		"ip_address" : module.Agent2.Eth0PublicIpAddress.ip_address
	}
}

output "AppEth0PublicIpAddress" {
	value = {
		"fqdn" : module.App.Eth0PublicIpAddress.fqdn
		"ip_address" : module.App.Eth0PublicIpAddress.ip_address
	}
}

output "ResourceGroup" {
	value = {
		"location" : azurerm_resource_group.ResourceGroup.location
		"name" : azurerm_resource_group.ResourceGroup.name
	}
}

output "SshKey" {
	sensitive = true
	value = {
		"private_key_openssh" : tls_private_key.SshKey.private_key_openssh
		"private_key_pem" : tls_private_key.SshKey.private_key_pem
		"public_key_openssh" : tls_private_key.SshKey.public_key_openssh
		"public_key_pem" : tls_private_key.SshKey.public_key_pem
	}
}

output "Subscription" {
	sensitive   = true
	value = {
		"display_name" : data.azurerm_subscription.current.display_name
		"subscription_id" : data.azurerm_subscription.current.subscription_id
	}
}

output "Subscriptions" {
	sensitive   = true
	value = {
		"available.display_name" : data.azurerm_subscriptions.available.subscriptions[*].display_name
		"available.subscription_id" : data.azurerm_subscriptions.available.subscriptions[*].subscription_id
	}
}