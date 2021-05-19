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

variable "gcp_region_name" {
  type    = string
  default = "<specify your gcp region name for deployment>"
}

variable "gcp_zone_name" {
  type    = string
  default = "<specify your gcp zone name for deployment>"
}