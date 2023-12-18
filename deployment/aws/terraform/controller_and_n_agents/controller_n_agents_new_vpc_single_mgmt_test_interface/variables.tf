variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "availability_zone" {
  type    = string
  default = "us-west-2a"
}

variable "aws_access_key" {
  type = string
  default = "xxxxxxxxxxxx"
  description = "AWS-cli access key"
}

variable "aws_secret_key" {
  type = string
  default = "xxxxxxxxxxx"
  description = "AWS-cli secret key"
}

variable "aws_stack_name" {
  type = string
  default = "cyperftest"
  description = "Stack name, prefix for all resources"
}

variable "aws_owner" {
  type = string
  default = "default"
  description = "Stack name, prefix for all resources"
}

variable "aws_auth_key" {
  type = string
  default = "secret key"
  description = "The key used to ssh into VMs"
}

variable "aws_allowed_cidr"{
  type = list(string)
  default = ["0.0.0.0/0"]
  description = "List of ip allowed to access the deployed machines"
}

variable "aws_mdw_machine_type"{
  type = string
  default = "c5.2xlarge"
  description = "MDW instance type"
}

variable "aws_agent_machine_type" {
  type = string
  default = "c5.2xlarge"
  description = "Agent machines instance type"
}

variable "agents" {
  type = number
  default = 2
  description = "Number of clients to be deployed"
}

variable "agents_tag_name" {
  type = string
  default = "cyperf-agent"
  description = "tag name of deployed agent"
}

variable "agents_tag_value" {
  type = string
  default = "cyperf-agent-tag"
  description = "tag value of deployed agent"
}