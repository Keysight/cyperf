variable "GCP_PROJECT_NAME" {
  type    = string
  default = "<specify your project name>"
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
  default = "keysight-gcp-cyperf"
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
  default     = "keysight-cyperf-controller-1-0"
  description = "Image id for the cyperf controller machine"
}

variable "agent_version" {
  type        = string
  default     = "keysight-cyperf-agent-1-0"
  description = "Image id for the cyperf agent machines"
}
