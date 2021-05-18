variable "AZURE_PROJECT_NAME" {
  type    = string
  description = "Project name"
}

variable "AZURE_OWNER_TAG" {
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

variable "AZURE_REGION_NAME" {
  type    = string
  default = "eastus"
}

variable "AZURE_ADMIN_USERNAME" {
  type    = string
  default = "cyperf"
}

variable "AZURE_PROJECT_TAG" {
  type    = string
  default = "keysight-azure-cyperf"
}

variable "AZURE_MDW_MACHINE_TYPE" {
  type    = string
  default = "Standard_F8s_v2"
}

variable "AZURE_AGENT_MACHINE_TYPE" {
  type    = string
  default = "Standard_F16s_v2"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-1-0"
  description = "Image id for the cyperf controller machine"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-1-0"
  description = "Image id for the cyperf agent machines"
}