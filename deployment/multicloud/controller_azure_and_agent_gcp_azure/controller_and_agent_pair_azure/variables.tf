variable "AZURE_OWNER_TAG" {
  type    = string
  default = "<specify the azure owner tag name>"
}

variable "AZURE_PROJECT_NAME" {
  type    = string
  default = "<specify your project name>"
}

variable "AZURE_PROJECT_TAG" {
  type    = string
  default = "keysight-azure-cyperf"
}

variable "AZURE_ADMIN_USERNAME" {
  type    = string
  default = "cyperf"
}

variable "AZURE_REGION_NAME" {
  type    = string
  default = "<specify your azure region name for deployment>"
}

# Specify the existing network infrastructure in which to deploy the instances
variable "DEST_AZURE_OWNER_TAG" {
  type    = string
  default = "<specify your azure owner tag name for the existing infrastructure>"
}

variable "VIRTUAL_NETWORK_NAME" {
  type    = string
  default = "<specify your azure virtual netowrk name for the existing infrastructure>"
}

variable "MANAGEMENT_SUBNET_NAME" {
  type    = string
  default = "<specify the azure management subnet name for the existing infrastructure>"
}

variable "TEST_SUBNET_NAME" {
  type    = string
  # Change default to the TEST SUBNET inside the TEST VPC of the user/lab
  default = "<specify the azure test subnet name for the existing infrastructure>"
}

variable "AZURE_MDW_MACHINE_TYPE" {
  type    = string
  default = "Standard_F8s_v2"
}

variable "AZURE_AGENT_MACHINE_TYPE" {
  type    = string
  default = "Standard_F16s_v2"
}

variable "AGENT_BLOB_URI" {
  type    = string
  default = "<specify the vhd url for the agent machine>"
  description = "vhd url for the agent machine"
}

variable "MDW_BLOB_URI" {
  type    = string
  default = "<specify the vhd url for the cyperf controller machine>"
  description = "vhd url for the cyperf controller machine"
}

variable "mdw_version" {
  type        = string
  default     = "keysight-cyperf-controller-1-1"
  description = "Image id for the cypef controller machine"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-1-1"
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

variable "ssh_public_key_path" {
  type = string
  default = "<specify your ssh public key file path>"
}

variable "ssh_private_key_path" {
  type = string
  default = "<specify your ssh private key file path>"
}