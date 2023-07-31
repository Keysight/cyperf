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

variable "InboundIPv4CidrBlock" {
	description = "IP Address /32 or IP CIDR range connecting inbound to App"
	type = string
	validation {
		condition = length(var.InboundIPv4CidrBlock) >= 9 && length(var.InboundIPv4CidrBlock) <= 18 && can(regex("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})", var.InboundIPv4CidrBlock))
		error_message = "InboundIPv4CidrBlock must be a valid IP CIDR range of the form x.x.x.x/x."
	}
}

variable "PrivateSubnetAvailabilityZone" {
	default = "us-east-1a"
	type = string
}

variable "PublicSubnetAvailabilityZone" {
	default = "us-east-1a"
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