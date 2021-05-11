variable "GCP_PROJECT_NAME" {
  type    = string
  default = "kt-nas-cyperf-dev"
}

variable "GCP_REGION_NAME" {
  type    = string
  default = "us-east1"
}

variable "GCP_ZONE_NAME" {
  type    = string
  default = "us-east1-b"
}

variable "GCP_OWNER_TAG" {
  type    = string
  default = "b2b"
}

variable "GCP_PROJECT_TAG" {
  type    = string
  default = "open-ixia-gcp-cyperf"
}

variable "GCP_MGMT_FIREWALL_RULE_SOURCE_IP_RANGES" {
  type = list(string)
  default = [
    "1.1.1.1/32"
  ]
}

variable "GCP_MDW_MACHINE_TYPE" {
  type    = string
  default = "n1-standard-4"
}

variable "GCP_AGENT_MACHINE_TYPE" {
  type    = string
  default = "c2-standard-16"
}

variable "mdw_version" {
  type        = string
  default     = "1-0-488-master"
  description = "Image id for the MDW machine"
}

variable "agent_version" {
  type        = string
  default     = "1-0-206-master-tiger-1-0-3-170"
  description = "Image id for the agent machines"
}