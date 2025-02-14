variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "availability_zone" {
  type    = string
  default = "us-west-2a"
}

variable "aws_main_cidr" {
  type = string
  default = "172.16.0.0/16"
  description = "AWS vpc cidr"
}

variable "aws_mgmt_cidr" {
  type = string
  default = "172.16.1.0/24"
  description = "AWS mgmt subnet"
}

variable "aws_cli_test_cidr" {
  type = string
  default = "172.16.3.0/16"
  description = "AWS client test subnet"
}

variable "aws_srv_test_cidr" {
  type = string
  default = "172.16.4.0/16"
  description = "AWS server test subnet"
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
  description = "Number of clients & servers each to be deployed"
}
