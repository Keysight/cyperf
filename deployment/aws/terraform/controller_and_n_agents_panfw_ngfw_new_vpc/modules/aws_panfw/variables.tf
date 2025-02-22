variable "resource_group" {
  type    = object({
    security_group = string,
    management_subnet = string,
    client_subnet = string,
    server_subnet = string,
    bootstrap_profile = string
  })
  description = "AWS resource group where you want to deploy in"
}

variable "aws_stack_name" {
  type = string
  description = "Stack name, prefix for all resources"
}

variable "aws_owner" {
  type = string
  description = "Stack name, prefix for all resources"
}

variable "aws_auth_key" {
  type = string
  description = "The key used to ssh into VMs"
}

variable "aws_panfw_machine_type"{
  type = string
  description = "PANFW instance type"
}

variable "panfw_version" {
  type        = string
  default     = "PA-VM-AWS-10.2.10-h12"
  description = "Version for the pan fw"
}

variable "panfw_product_code" {
  type        = string
  default     = "e9yfvyj3uag5uo5j2hjikv74n"
  description = "Product code from the AWS Marketplace for the PAN FW"
}


