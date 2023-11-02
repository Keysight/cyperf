provider "azurerm" {
	subscription_id = var.SubscriptionId
	features {
		resource_group {
			prevent_deletion_if_contains_resources = false
		}
	}
}