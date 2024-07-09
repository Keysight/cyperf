locals {
	AgentBlobSasUrl = var.AgentBlobSasUrl
	AgentPackageName = regex("tiger.*\\.deb", local.AgentBlobSasUrl)
	AgentVmSize = var.AgentVmSize
	Agent1InstanceId = "agent1"
	Agent2Eth0IpAddress = "10.0.10.12"
	Agent2Eth1IpAddresses = [ "10.0.2.22" ]
	Agent2InstanceId = "agent2"
	AppTag = "ubuntu"
	AppVersion = "2204-lts"
	AppVmSize = var.AppVmSize
	ClientId = var.ClientId
	ClientSecret = var.ClientSecret
	Preamble = "${local.UserLoginTag}-${local.AppTag}-${local.AppVersion}"
	PublicSecurityRuleSourceIpPrefixes = var.PublicSecurityRuleSourceIpPrefixes == null ? [ "${data.http.ip.response_body}/32" ] : var.PublicSecurityRuleSourceIpPrefixes
	ResourceGroupLocation = var.ResourceGroupLocation
	ResourceGroupName = var.ResourceGroupName == null ? "${local.Preamble}-resource-group" : var.ResourceGroupName
	SkipProviderRegistration = var.SkipProviderRegistration
	SshKeyAlgorithm = "RSA"
	SshKeyName = "${local.Preamble}-ssh-key"
	SshKeyRsaBits = "4096"
	SubscriptionId = var.SubscriptionId
	TenantId = var.TenantId
	UserEmailTag = var.UserEmailTag == null ? data.azurerm_client_config.current.client_id : var.UserEmailTag
	UserLoginTag = var.UserLoginTag == null ? "terraform" : var.UserLoginTag
	UserProjectTag = var.UserProjectTag == null ? random_id.RandomId.id : var.UserProjectTag
}