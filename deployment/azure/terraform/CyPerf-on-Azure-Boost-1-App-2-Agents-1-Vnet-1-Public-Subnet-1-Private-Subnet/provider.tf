provider "azurerm" {
	client_id = local.ClientId
	client_secret = local.ClientSecret
	resource_provider_registrations = local.ResourceProviderRegistrations
	subscription_id = local.SubscriptionId
	tenant_id = local.TenantId
	features {
		resource_group {
			prevent_deletion_if_contains_resources = false
		}
	}
}