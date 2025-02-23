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
  default = "172.16.3.0/24"
  description = "AWS client test subnet"
}

variable "aws_cli_test_cidr_pan" {
  type = string
  default = "172.16.6.0/24"
  description = "AWS client test subnet"
}

variable "aws_srv_test_cidr" {
  type = string
  default = "172.16.4.0/24"
  description = "AWS server test subnet"
}

variable "aws_srv_test_cidr_pan" {
  type = string
  default = "172.16.7.0/24"
  description = "AWS server test subnet"
}

variable "aws_firewall_cidr" {
  type = string
  default = "172.16.5.0/24"
  description = "AWS firewall subnet"
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

variable "aws_panfw_machine_type"{
  type = string
  default = "c5.2xlarge"
  description = "panfw instance type"
}

variable "clientagents" {
  type = number
  default = 1
  description = "Number of clients to be deployed for awsfw"
}

variable "serveragents" {
  type = number
  default = 1
  description = "Number of servers to be deployed for awsfw"
}

variable "clientagents_pan" {
  type = number
  default = 1
  description = "Number of clients to be deployed for panfw"
}

variable "serveragents_pan" {
  type = number
  default = 1
  description = "Number of servers to be deployed for panfw"
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

variable "panfw_bootstrap_bucket" {
  type        = string
  default     = ""
  description = "Bucket name for pan firewall bootstrap configuration"
}
