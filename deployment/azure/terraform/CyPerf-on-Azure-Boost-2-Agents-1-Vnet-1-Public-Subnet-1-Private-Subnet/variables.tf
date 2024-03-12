variable "AgentVmSize" {
	default = "Experimental_Boost8"
	description = "Category, series and instance specifications associated with the Agent VM"
	type = string
	validation {
		condition = contains([	"Experimental_Boost4", "Experimental_Boost8", "Experimental_Boost32", "Experimental_Boost64", "Experimental_Boost192"
							], var.AgentVmSize)
		error_message = <<EOF
AgentVmSize must be one of the following sizes:
	Experimental_Boost4, Experimental_Boost8, Experimental_Boost32, Experimental_Boost64, Experimental_Boost192
		EOF
	}
}

variable "ClientId" {
	description = "Id of an application created in Azure Active Directory"
	sensitive = true
	type = string
}

variable "ClientSecret" {
	description = "Authentication value of an application created in Azure Active Directory"
	sensitive = true
	type = string
}

variable "PublicSecurityRuleSourceIpPrefixes" {
	description = "List of IP Addresses /32 or IP CIDR ranges connecting inbound to App"
	type = list(string)
}

variable "ResourceGroupLocation" {
	default = "South Central US"
	description = "Location of container metadata and control plane operations"
	type = string
}

variable "ResourceGroupName" {
	description = "Id of container that holds related resources that you want to manage together"
	type = string
}

variable "SubscriptionId" {
	description = "Id of subscription and underlying services used by the deployment"
	sensitive = true
	type = string
}

variable "TenantId" {
	description  = "Id of an Azure Active Directory instance where one subscription may have multiple tenants"
	sensitive = true
	type = string
}

variable "UserEmailTag" {
	description = "Email address tag of user creating the deployment"
	type = string
}

variable "UserLoginTag" {
	description = "Login ID tag of user creating the deployment"
	type = string
}

variable "UserProjectTag" {
	default = "cloud-ist"
	description = "Project tag of user creating the deployment"
	type = string
}