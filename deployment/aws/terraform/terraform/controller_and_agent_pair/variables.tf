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
  default = "c5.2xlarge"
  description = "MDW instance type"
}

variable "aws_agent_machine_type" {
  type = string
  default = "c5.2xlarge"
  description = "Agent machines instance type"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-3-0"
  description = "Version for the cyperf controller"
}

variable "mdw_product_code" {
  type        = string
  default     = "8nmwoluc06w5z6vbutcwyueje"
  description = "Product code from the AWS Marketplace for the cyperf controller"
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
  default     = "keysight-cyperf-agent-3-0"
  description = "Version for the cyperf agent"
}

variable "agent_product_code" {
  type        = string
  default     = "zskzjts7t5crpmiic5drkq0j"
  description = "Product code from the AWS Marketplace the cyperf agent"
}
