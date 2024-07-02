variable "azure_project_name" {
  type        = string
  description = "Project name"
}

variable "azure_owner_tag" {
  type        = string
  description = "Owner tag name"
}

variable "subscription_id" {
  type        = string
  description = "Subscription id"
}

variable "client_id" {
  type        = string
  description = "Client id"
}

variable "client_secret" {
  type        = string
  description = "Client secret key"
}

variable "tenant_id" {
  type        = string
  description = "Tenant id"
}

variable "public_key" {
  type        = string
  description = "Path to the public key used to ssh into machine"
}

variable "azure_region_name" {
  type    = string
  default = "centralus"
}

variable "azure_admin_username" {
  type    = string
  default = "cyperf"
}

variable "azure_project_tag" {
  type    = string
  default = "keysight-azure-cyperf"
}

variable "azure_allowed_cidr_ipv4" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of allowed IPv4 ranges on the machines"
}
variable "azure_allowed_cidr_ipv6" {
  type    = list(string)
  default = ["::/0"]
}
variable "stack_type" {
  type        = string
  default     = "ipv4"
  description = "Possible options: ipv4 / ipv6 / dual-stack"
}
variable "azure_mdw_machine_type" {
  type    = string
  default = "Standard_F8s_v2"
}

variable "cyperf_version" {
  type        = string
  default     = "0.3.0"
  description = "CyPerf release version"
}

variable "mdw_name" {
  type        = string
  default     = "keysight-cyperf-controller-3-0"
  description = "Name for the cyperf controller machine"
}
