variable "aws_access_key" {
  type = string
  description = "AWS-cli access key"
}

variable "aws_secret_key" {
  type = string
  description = "AWS-cli secret key"
}

variable "aws_stack_name" {
  type = string
  description = "Stack name, prefix for all resources"
}

variable "aws_auth_key" {
  type = string
  description = "The key used to ssh into VMs"
}

variable "aws_allowed_cidr"{
  type = list(string)
  default = ["0.0.0.0/0"]
  description = "List of ip allowed to access the deployed machines"
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "availability_zone" {
  type    = string
  default = "us-east-2a"
}

variable "aws_broker_machine_type"{
  type = string
  default = "t2.medium"
  description = "MDW instance type"
}

variable "aws_agent_machine_type" {
  type = string
  default = "c5.2xlarge"
  description = "Agent machines instance type"
}

variable "broker_version" {
  type        = string
  default     = "keysight-cyperf-controller-proxy-3-0"
  description = "Version for the controller-proxy machine"
}

variable "broker_username" {
  type        = string
  default     = "admin"
  description = "Broker's authentication username"
  }
variable "broker_password" {
  type        = string
  default     = "CyPerf&Keysight#1"
  description = "Broker's authentication password"
}
variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-3-0"
  description = "Version for the cyperf agent machines"
}

variable "cyperf_release" {
  type        = string
  default     = "3.0"
  description = "The version of the cyperf release"
}