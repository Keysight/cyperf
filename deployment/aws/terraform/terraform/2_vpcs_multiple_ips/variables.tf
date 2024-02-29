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

variable "aws_broker_machine_type"{
  type = string
  default = "t2.medium"
  description = "MDW instance type"
}

variable "ip_number"{
  type = number
  default = 4
  description = "Number of test IPs per agent"
}

variable "agent_number"{
  type = number
  default = 2
  description = "Number of agents deployed per vpc"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-2-6"
  description = "Version for the cyperf controller machine"
}

variable "mdw_product_code" {
  type        = string
  default     = "8nmwoluc06w5z6vbutcwyueje"
  description = "Product code from the AWS Marketplace for the cyperf controller"
}

variable "broker_version" {
  type        = string
  default     = "keysight-cyperf-controller-proxy-2-6"
  description = "Version for the controller-proxy machine"
}

variable "broker_product_code" {
  type        = string
  default     = "3fezxyt55evlaoi1pkcqtonsj"
  description = "Product code from the AWS Marketplace for the controller-proxy machine"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-2-6"
  description = "Version for the cyperf agent"
}

variable "agent_product_code" {
  type        = string
  default     = "zskzjts7t5crpmiic5drkq0j"
  description = "Product code from the AWS Marketplace for the cyperf agent"
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
