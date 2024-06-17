variable "AgentInstanceType" {
	default = "c5n.9xlarge"
	description = "Instance type of Agent VM"
	type = string
	validation {
		condition = contains([	"m3.xlarge", "m3.2xlarge",
								"m4.xlarge", "m4.2xlarge", "m4.4xlarge",
								"m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge", "m5.12xlarge",
								"m5n.large", "m5n.xlarge", "m5n.2xlarge", "m5n.4xlarge", "m5n.8xlarge",
								"c3.2xlarge", "c3.4xlarge", "c3.8xlarge",
								"c4.xlarge", "c4.2xlarge", "c4.4xlarge", "c4.8xlarge",
								"c5.xlarge", "c5.2xlarge", "c5.4xlarge", "c5.9xlarge", "c5.12xlarge",
								"c5n.xlarge", "c5n.2xlarge", "c5n.4xlarge", "c5n.9xlarge", "c5n.18xlarge",
								"c6in.2xlarge", "c6in.24xlarge"
							], var.AgentInstanceType)
		error_message = <<EOF
AgentInstanceType must be one of the following types:
	m3.xlarge, m3.2xlarge,
	m4.xlarge, m4.2xlarge, m4.4xlarge,
	m5.large, m5.xlarge, m5.2xlarge, m5.4xlarge, m5.12xlarge,
	m5n.large, m5n.xlarge, m5n.2xlarge, m5n.4xlarge, m5n.8xlarge,
	c3.2xlarge, c3.4xlarge, c3.8xlarge,
	c4.xlarge, c4.2xlarge, c4.4xlarge, c4.8xlarge,
	c5.xlarge, c5.2xlarge, c5.4xlarge, c5.9xlarge, c5.12xlarge,
	c5n.xlarge, c5n.2xlarge, c5n.4xlarge, c5n.9xlarge, c5n.18xlarge,
	c6in.2xlarge, c6in.24xlarge
		EOF
	}
}

variable "ApiMaxRetries" {
	default = 1
	type = number
}

variable "AppInstanceType" {
	default = "c5.2xlarge"
	description = "Instance type of App VM"
	type = string
	validation {
		condition = contains([	"m3.2xlarge",
								"m4.2xlarge", "m4.4xlarge",
								"m5.2xlarge", "m5.4xlarge", "m5.12xlarge",
								"c3.2xlarge", "c3.4xlarge", "c3.8xlarge",
								"c4.2xlarge", "c4.4xlarge", "c4.8xlarge",
								"c5.2xlarge", "c5.4xlarge", "c5.9xlarge", "c5.12xlarge",
								"c5n.2xlarge", "c5n.4xlarge", "c5n.9xlarge"
							], var.AppInstanceType)
		error_message = <<EOF
AppInstanceType must be one of the following types:
	m4.2xlarge, m4.4xlarge,
	m5.2xlarge, m5.4xlarge, m5.12xlarge,
	c3.2xlarge, c3.4xlarge, c3.8xlarge,
	c4.2xlarge, c4.4xlarge, c4.8xlarge,
	c5.2xlarge, c5.4xlarge, c5.9xlarge, c5.12xlarge,
	c5n.2xlarge, c5n.4xlarge, c5n.9xlarge
		EOF
	}
}

variable "InboundIPv4CidrBlocks" {
	description = "List of IP Addresses /32 or IP CIDR ranges connecting inbound to App"
	type = list(string)
}

variable "Private1SubnetAvailabilityZone" {
	default = "us-east-1a"
	type = string
}

variable "Private2SubnetAvailabilityZone" {
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