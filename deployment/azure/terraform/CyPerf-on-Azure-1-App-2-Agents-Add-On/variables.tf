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

variable "PrivateSubnetName" {
	description = "Subnet name assciated with the private subnet"
	type = string
}

variable "PublicSecurityRuleSourceIpPrefix" {
	type = string
}

variable "PublicSubnetName" {
	description = "Subnet name assciated with the public subnet"
	type = string
}

variable "ResourceGroupLocation" {
	default = "East US"
	type = string
}

variable "ResourceGroupName" {
	type = string
}

variable "SubscriptionId" {
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
	type = string
}

variable "VnetName" {
	description = "Vnet name assciated with the virtual network"
	type = string
}