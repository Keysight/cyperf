data "azurerm_client_config" "current" { }

data "azurerm_subscription" "current" {}

data "azurerm_subscriptions" "available" {}

data "http" "ip" {
	url = "https://ifconfig.me"
}