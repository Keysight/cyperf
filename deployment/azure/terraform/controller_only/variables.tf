variable "AZURE_PROJECT_NAME" {
  type    = string
  default = "kt-nas-cyperf-dev"
}

variable "AZURE_REGION_NAME" {
  type    = string
  default = "eastus"
}

variable "AZURE_OWNER_TAG" {
  type    = string
  default = "mdw-qa-b2b"
}

variable "AZURE_ADMIN_USERNAME" {
  type    = string
  default = "cyperf"
}

variable "AZURE_PROJECT_TAG" {
  type    = string
  default = "open-ixia-azure-cyperf"
}

variable "AZURE_MDW_MACHINE_TYPE" {
  type    = string
  default = "Standard_F8s_v2"
}

variable "mdw_version" {
  type        = string
  default     = "1-0-310-releasecyperfapr2021"
  description = "Image id for the MDW machine"
}

variable "subscription_id" {
  type = string
  default = "908fce0d-1b5e-475a-a419-2a30b8c01f6b"
}

variable "client_id" {
  type = string
  default = "5665dab6-ab61-4d87-a129-ea780b6123fd"
}

variable "client_secret" {
  type = string
  default = "-L6Hl-DuQSFeJViatPxgL5MmG6.1~--J7g"
}

variable "tenant_id" {
  type = string
  default = "63545f27-3232-4d74-a44d-cdd457063402"
}

