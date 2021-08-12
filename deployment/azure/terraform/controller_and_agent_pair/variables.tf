variable "azure_project_name" {
  type    = string
  description = "Project name"
}

variable "azure_owner_tag" {
  type    = string
  description = "Owner tag name"
}

variable "subscription_id" {
  type = string
  description = "Subscription id"
}

variable "client_id" {
  type = string
  description = "Client id"
}

variable "client_secret" {
  type = string
  description = "Client secret key"
}

variable "tenant_id" {
  type = string
  description = "Tenant id"
}

variable "public_key" {
  type = string
  description = "Path to the public key used to ssh into machine"
}

variable "controller_image" {
  type = string
  description = "Controller image path"
}

variable "agent_image" {
  type = string
  description = "Agent image path"
}

variable "azure_region_name" {
  type    = string
  default = "eastus"
}

variable "azure_admin_username" {
  type    = string
  default = "cyperf"
}

variable "azure_project_tag" {
  type    = string
  default = "keysight-azure-cyperf"
}

variable "azure_mdw_machine_type" {
  type    = string
  default = "Standard_F8s_v2"
}

variable "azure_agent_machine_type" {
  type    = string
  default = "Standard_F4s_v2"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-1-0-update1"
  description = "Image id for the cyperf controller machine"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-1-0-update1"
  description = "Image id for the cyperf agent machines"
}