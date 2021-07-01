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
  default = "t2.xlarge"
  description = "MDW instance type"
}

variable "aws_agent_machine_type" {
  type = string
  default = "c4.2xlarge"
  description = "Agent machines instance type"
}

variable "broker_version" {
  type        = string
  default     = "keysight-cyperf-controller-proxy-1-0"
  description = "Image id for the controller-proxy machine"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-1-0-update1"
  description = "Image id for the cyperf agent machines"
}
