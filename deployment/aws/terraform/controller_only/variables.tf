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

variable "aws_allowed_cidr_ipv4"{
  type = list(string)
  default = ["0.0.0.0/0"]
  description = "List of IPv4 allowed to access the deployed machines"
}
variable "aws_allowed_cidr_ipv6"{
  type = list(string)
  default = ["::/0"]
  description = "List of IPv6 allowed to access the deployed machines"
}
variable "stack_type" {
  type = string
  default = "ipv4"
  description = "Possible options: ipv4 / ipv6 / dual-stack"
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "availability_zone" {
  type    = string
  default = "us-east-2a"
}

variable "aws_mdw_machine_type"{
  type = string
  default = "c5.2xlarge"
  description = "Controller instance type"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-3-0"
  description = "Version for the cyperf controller machine"
}

variable "cyperf_release" {
  type        = string
  default     = "3.0"
  description = "The version of the cyperf release"
}