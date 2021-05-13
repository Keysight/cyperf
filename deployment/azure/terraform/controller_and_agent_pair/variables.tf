variable "AZURE_PROJECT_NAME" {
  type    = string
  default = "<specify your project name>"
}

variable "AZURE_REGION_NAME" {
  type    = string
  default = "eastus"
}

variable "AZURE_OWNER_TAG" {
  type    = string
  default = "<specify the azure owner tag name>"
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

variable "subscription_id" {
  type = string
  default = "<specify your subscription_id>"
}

variable "client_id" {
  type = string
  default = "<specify your client_id>"
}

variable "client_secret" {
  type = string
  default = "<specify your client_secrect>"
}

variable "tenant_id" {
  type = string
  default = "<specify your tenant_id>"
}

