variable "AgentVmSize" {
	default = "Standard_F8s_v2"
	type = string
	validation {
		condition = contains([	"Standard_F4s_v2",	"Standard_F8s_v2",	"Standard_F16s_v2",	"Standard_F64s_v2"
							], var.AgentVmSize)
		error_message = <<EOF
AgentVmSize must be one of the following sizes:
	Standard_F4s_v2, Standard_F8s_v2, Standard_F16s_v2, Standard_F64s_v2
		EOF
	}
}

variable "AppVmSize" {
	default = "Standard_F8s_v2"
	type = string
	validation {
		condition = contains([	"Standard_F8s_v2",	"Standard_F16s_v2"
							], var.AppVmSize)
		error_message = <<EOF
AppVmSize must be one of the following sizes:
	Standard_F8s_v2, "Standard_F16s_v2"
		EOF
	}
}

variable "ClientId" {
	default = null
	sensitive = true
	type = string
}

variable "ClientSecret" {
	default = null
	sensitive = true
	type = string
}

variable "PublicSecurityRuleSourceIpPrefixes" {
	default = null
	description = "List of IP Addresses /32 or IP CIDR ranges connecting inbound to App"
	type = list(string)
}

variable "ResourceGroupLocation" {
	default = "East US"
	type = string
}

variable "ResourceGroupName" {
	default = null
	type = string
}

variable "SkipProviderRegistration" {
	default = false
	description = "Indicates whether or not to ignore registration of Azure Resource Providers due to insuffiencient permissions"
	type = bool
}

variable "SubscriptionId" {
	default = null
	sensitive = true
	type = string
}

variable "TenantId" {
	default = null
	sensitive = true
	type = string
}

variable "UserEmailTag" {
	default = null
	description = "Email address tag of user creating the deployment"
	type = string
}

variable "UserLoginTag" {
	default = null
	description = "Login ID tag of user creating the deployment"
	type = string
}

variable "UserProjectTag" {
	default = null
	type = string
}