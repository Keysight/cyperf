data "azurerm_client_config" "current" { }

data "azurerm_subscription" "current" {}

data "azurerm_subscriptions" "available" {}

data "cloudinit_config" "init_cli" {
	gzip = false
	base64_encode = false
	part {
		content_type = "text/cloud-config"
		content = templatefile("cloud-init.yml", {
			AgentBlobSasUrl: local.AgentBlobSasUrl
			AgentPackageName: local.AgentPackageName
			AppEth0IpAddress: module.App.Instance.private_ip_address
		})
	}
}

data "http" "ip" {
	url = "https://ifconfig.me"
}