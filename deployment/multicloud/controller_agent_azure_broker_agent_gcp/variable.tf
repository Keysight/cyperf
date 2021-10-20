variable "azure_project_name" {
  type    = string
  description = "Project name"
}

variable "gcp_project_name" {
  type    = string
  description ="Project name"
}

variable "deployment_name" {
  type  = string
  description = "Prefix for all clouds"
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

variable "gcp_credential_file" {
  type = string
  description = "GCP credentials file referring this link https://cloud.google.com/iam/docs/creating-managing-service-account-keys"
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

variable "gcp_region_name" {
  type    = string
  default = "us-east1"
}

variable "gcp_zone_name" {
  type    = string
  default = "us-east1-b"
}


variable "azure_project_tag" {
  type    = string
  default = "keysight-azure-cyperf"
}

variable "gcp_project_tag" {
  type    = string
  default = "keysight-gcp-cyperf"
}

variable "azure_mdw_machine_type" {
  type    = string
  default = "Standard_F8s_v2"
}

variable "azure_agent_machine_type" {
  type    = string
  default = "Standard_F4s_v2"
}

variable "gcp_broker_machine_type" {
  type    = string
  default = "n1-standard-2"
}

variable "gcp_agent_machine_type" {
  type    = string
  default = "c2-standard-4"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-1-1"
  description = "Image id for the cyperf controller machine"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-1-1"
  description = "Image id for the cyperf agent machines"
}

variable "broker_image" {
  type        = string
  default     = "keysight-cyperf-controller-proxy-1-1"
  description = "Image id for the cyperf controller proxy machines"
}
