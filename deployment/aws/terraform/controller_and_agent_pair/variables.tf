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
  description = "AWS region to be deployed"
  default = "us-east-2"
}

variable "availability_zone" {
  type    = string
  description = "AWS availability zone"
  default = "us-east-2a"
}

variable "aws_mdw_machine_type"{
  type = string
  default = "t2.xlarge"
  description = "MDW instance type"
}

variable "aws_agent_machine_type" {
  type = string
  default = "c4.2xlarge"
  description = "Agent machines instance type"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-1-6"
  description = "Image id for the cyperf controller"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-1-6"
  description = "Image id for the cyperf agent"
}
