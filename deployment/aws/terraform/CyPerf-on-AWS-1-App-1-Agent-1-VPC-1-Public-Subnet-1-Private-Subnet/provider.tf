provider "aws" {
	access_key = var.AwsAccessCredentialsAccessKey
	secret_key = var.AwsAccessCredentialsSecretKey
	region = var.Region
	max_retries = var.ApiMaxRetries
}