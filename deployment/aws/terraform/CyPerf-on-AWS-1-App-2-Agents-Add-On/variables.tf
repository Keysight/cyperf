variable "AgentInstanceType" {
	default = "c5n.4xlarge"
	description = "Instance type of Agent VM"
	type = string
	validation {
		condition = contains([	"c5n.4xlarge", "c5n.9xlarge", "c5n.18xlarge"
							], var.AgentInstanceType)
		error_message = <<EOF
AgentInstanceType must be one of the following types:
	c5n.4xlarge, c5n.9xlarge, c5n.18xlarge
		EOF
	}
}

variable "ApiMaxRetries" {
	default = 1
	type = number
}

variable "AppInstanceType" {
	default = "m5.xlarge"
	description = "Instance type of App VM"
	type = string
	validation {
		condition = contains([	"t3.xlarge",
								"m5.xlarge"
							], var.AppInstanceType)
		error_message = <<EOF
AppInstanceType must be one of the following types:
	t3.xlarge
	m5.xlarge
		EOF
	}
}

variable "AwsAccessCredentialsAccessKey" {
	description = "Access key component of credentials used for programmatic calls to AWS."
	type = string
}

variable "AwsAccessCredentialsSecretKey" {
	description = "Secret access key component of credentials used for programmatic calls to AWS."
	type = string
}

variable "PrivateSubnetId" {
	description = "Subnet id assciated with the private subnet"
	type = string
}

variable "PrivateSecurityGroupId" {
	description = "Security Group Id associated with the private subnet."
	type = string
}

variable "PublicSubnetId" {
	description = "Subnet id assciated with the public subnet"
	type = string
}

variable "PublicSecurityGroupId" {
	description = "Security Group Id associated with the public subnet."
	type = string
}

variable "Region" {
	default = "us-east-1"
	type = string
}

variable "UserEmailTag" {
	description = "Email address tag of user creating the deployment"
	type = string
	validation {
		condition = length(var.UserEmailTag) >= 14
		error_message = "UserEmailTag minimum length must be >= 14."
	}
}

variable "UserLoginTag" {
	description = "Login ID tag of user creating the deployment"
	type = string
	validation {
		condition = length(var.UserLoginTag) >= 4
		error_message = "UserLoginTag minimum length must be >= 4."
	}
}

variable "UserProjectTag" {
	default = "cloud-ist"
	description = "Project tag of user creating the deployment"
	type = string
}