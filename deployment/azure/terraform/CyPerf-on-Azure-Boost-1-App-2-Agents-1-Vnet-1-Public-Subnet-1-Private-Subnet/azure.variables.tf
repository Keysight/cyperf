variable "ClientId" {
	default = null
	description = "Id of an application created in Azure Active Directory"
	sensitive = true
	type = string
}

variable "ClientSecret" {
	default = null
	description = "Authentication value of an application created in Azure Active Directory"
	sensitive = true
	type = string
}

variable "ResourceProviderRegistrations" {
	default = "core"
	description = "Indicates whether or not to ignore registration of Azure Resource Providers due to insuffiencient permissions"
	type = string
}

variable "SubscriptionId" {
	default = null
	description = "Id of subscription and underlying services used by the deployment"
	sensitive = true
	type = string
}

variable "TenantId" {
	default = null
	description  = "Id of an Azure Active Directory instance where one subscription may have multiple tenants"
	sensitive = true
	type = string
}