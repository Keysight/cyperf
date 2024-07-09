provider "azurerm" {
	client_id = local.ClientId
	client_secret = local.ClientSecret
	skip_provider_registration = local.SkipProviderRegistration
	subscription_id = local.SubscriptionId
	tenant_id = local.TenantId
	features {
		resource_group {
			prevent_deletion_if_contains_resources = false
		}
	}
}