variable "AgentVmSize" {
	default = "Standard_F8s_v2"
	description = "Category, series and instance specifications associated with the Agent VM"
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

variable "PrivateSubnetName" {
	description = "Subnet name assciated with the private subnet"
	type = string
}

variable "PublicSubnetName" {
	description = "Subnet name assciated with the public subnet"
	type = string
}

variable "ResourceGroupLocation" {
	default = "East US"
	description = "Location of container metadata and control plane operations"
	type = string
}

variable "ResourceGroupName" {
	description = "Id of container that holds related resources that you want to manage together"
	type = string
}

variable "SkipProviderRegistration" {
	default = false
	description = "Indicates whether or not to ignore registration of Azure Resource Providers due to insuffiencient permissions"
	type = bool
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
	description = "Project tag of user creating the deployment"
	type = string
}

variable "VnetName" {
	description = "Vnet name assciated with the virtual network"
	type = string
}