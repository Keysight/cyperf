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

variable "AgentBlobSasUrl" {
	description = "Shared Access Signature URL path to Agent installation package"
	sensitive = true
	type = string
}

variable "AppVmSize" {
	default = "Standard_F8s_v2"
	description = "Category, series and instance specifications associated with the App VM"
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

variable "PublicSecurityRuleSourceIpPrefixes" {
	default = null
	description = "List of IP Addresses /32 or IP CIDR ranges connecting inbound to App"
	type = list(string)
}

variable "ResourceGroupLocation" {
	default = "South Central US"
	description = "Location of container metadata and control plane operations"
	type = string
}

variable "ResourceGroupName" {
	default = null
	description = "Id of container that holds related resources that you want to manage together"
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