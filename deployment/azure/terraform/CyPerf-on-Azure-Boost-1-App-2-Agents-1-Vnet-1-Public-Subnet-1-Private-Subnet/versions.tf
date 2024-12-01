terraform {
	required_version = ">= 1.5.7"
	required_providers {
		azurerm = {
			source  = "hashicorp/azurerm"
			version = ">= 4.10.0"
		}
	}
}