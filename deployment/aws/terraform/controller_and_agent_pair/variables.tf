variable "aws_access_key" {
  type        = string
  description = "AWS-cli access key"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS-cli secret key"
}

variable "aws_stack_name" {
  type        = string
  description = "Stack name, prefix for all resources"
}

variable "aws_auth_key" {
  type        = string
  description = "The key used to ssh into VMs"
}

variable "aws_allowed_cidr_ipv4" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of IPV4 allowed to access the deployed machines"
}
variable "aws_allowed_cidr_ipv6" {
  type        = list(string)
  default     = ["::/0"]
  description = "List of IPv6 allowed to access the deployed machines"
}
variable "stack_type" {
  type        = string
  default     = "ipv4"
  description = "Possible options: ipv4 / ipv6 / dual-stack"
}

variable "aws_region" {
  type        = string
  description = "AWS region to be deployed"
  default     = "us-east-2"
}

variable "availability_zone" {
  type        = string
  description = "AWS availability zone"
  default     = "us-east-2a"
}

variable "aws_mdw_machine_type" {
  type        = string
  default     = "c5.2xlarge"
  description = "MDW instance type"
}

variable "aws_agent_machine_type" {
  type        = string
  default     = "c5.2xlarge"
  description = "Agent machines instance type"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-5-0"
  description = "Version for the cyperf controller"
}

variable "controller_username" {
  type        = string
  default     = "admin"
  description = "Controller's authentication username"
}

variable "controller_password" {
  type        = string
  default     = "CyPerf&Keysight#1"
  description = "Controller's authentication password"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-5-0"
  description = "Version for the cyperf agent"
}

variable "cyperf_release" {
  type        = string
  default     = "6.0"
  description = "The version of the cyperf release"
}