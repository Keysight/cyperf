variable "gcp_owner_tag" {
  type    = string
  default = "<specify the gcp owner tag name>"
}

variable "gcp_project_name" {
  type    = string
  default = "<specify your project name>"
}

variable "gcp_project_tag" {
  type    = string
  default = "keysight-gcp-cyperf"
}

variable "GCP_CREDENTIALS" {
  type = string
  default = "<create gcp credentials file referring this link https://cloud.google.com/iam/docs/creating-managing-service-account-keys>"
}

variable "SSH_KEY_PATH" {
  type = string
  default = "<specify the gcp public ssh key file path>"
}

variable "SSH_USER" {
  type        = string
  default     = "cyperf"
  description = "SSH User"
}

variable "gcp_region_name" {
  type    = string
  default = "<specify your gcp region name for deployment>"
}

variable "gcp_zone_name" {
  type    = string
  default = "<specify your gcp zone name for deployment>"
}

# Specify the existing network infrastructure in which to deploy the instances
variable "gcp_mgmt_vpc_network_name" {
  type    = string
  default = "<specify the gcp management vpc network name for the existing infrastructure>"
}

variable "gcp_test_vpc_network_name" {
  type    = string
  default = "<specify the gcp test vpc network name for the existing infrastructure>"
}

variable "gcp_mgmt_subnet_name" {
  type    = string
  default = "<specify the gcp management subnet name for the existing infrastructure>"
}

variable "gcp_test_subnet_name" {
  type    = string
  default = "<specify the gcp test subnet name for the existing infrastructure>"
}

# Other constants like VM instance types and build versions
variable "gcp_broker_machine_type" {
  type    = string
  default = "n1-standard-2"
}

variable "gcp_agent_machine_type" {
  type    = string
  default = "c2-standard-16"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-1-0"
  description = "Image id for the cyperf agent machines"
}

variable "broker_image" {
  type        = string
  default     = "keysight-cyperf-controller-proxy-1-0"
  description = "Image id for the cyperf controller proxy machines"
}
