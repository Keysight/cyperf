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

variable "aws_mdw_machine_type"{
  type = string
  default = "c5.2xlarge"
  description = "Controller instance type"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-2-1"
  description = "Version for the cyperf controller machine"
}

variable "mdw_product_code" {
  type        = string
  default     = "8nmwoluc06w5z6vbutcwyueje"
  description = "Product code from the AWS Marketplace for the cyperf controller"
}