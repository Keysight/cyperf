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
  default = "broker-agents-ox"
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

variable "GCP_BROKER_MACHINE_TYPE" {
  type    = string
  default = "n1-standard-2"
}

variable "GCP_AGENT_MACHINE_TYPE" {
  type    = string
  default = "c2-standard-4"
}

variable "agent_version" {
  type        = string
  default     = "1-0-206-master-tiger-1-0-3-170"
  description = "Image id for the agent machines"
}

variable "broker_image" {
  type        = string
  default     = "cyperf-broker-1-0-0-12"
  description = "Image id for the agent machines"
}

variable "network_name" {
  type = string
  default = "load-balancer-net"
  description = "Load balancer network name"
}

variable "ssl_certificate"{
  type = string
  default = "projects/kt-nas-cyperf-dev/global/sslCertificates/cyper-https-lb"
  description = "SSL certificate for https load balancers"
}
