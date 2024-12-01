locals {
	AgentVmSize = var.AgentVmSize
	Agent1InstanceId = "agent1"
	Agent2Eth0IpAddress = "192.168.10.11"
	Agent2Eth1IpAddresses = [ "192.168.2.12" ]
	Agent2InstanceId = "agent2"
	AppTag = "cyperf"
	AppVmSize = var.AppVmSize
	ClientId = var.ClientId
	ClientSecret = var.ClientSecret
	Preamble = "${local.UserLoginTag}-${local.UserProjectTag}-${local.AppTag}"
	PublicSecurityRuleSourceIpPrefixes = var.PublicSecurityRuleSourceIpPrefixes == null ? [ "${data.http.ip.response_body}/32" ] : var.PublicSecurityRuleSourceIpPrefixes
	ResourceGroupLocation = var.ResourceGroupLocation
	ResourceGroupName = var.ResourceGroupName == null ? "${local.Preamble}-resource-group" : var.ResourceGroupName
	ResourceProviderRegistrations = var.ResourceProviderRegistrations
	SshKeyAlgorithm = "RSA"
	SshKeyName = "${local.Preamble}-ssh-key"
	SshKeyRsaBits = "4096"
	SubscriptionId = var.SubscriptionId
	TenantId = var.TenantId
	UserEmailTag = var.UserEmailTag == null ? data.azurerm_client_config.current.client_id : var.UserEmailTag
	UserLoginTag = var.UserLoginTag == null ? "terraform" : var.UserLoginTag
	UserProjectTag = var.UserProjectTag == null ? random_id.RandomId.id : var.UserProjectTag
	Vnet1InstanceId = "vnet1"
	Vnet1PeeringName = "${local.Preamble}-${local.Vnet1InstanceId}-peering"
	Vnet2AddressPrefix = "192.168.0.0/16"
	Vnet2InstanceId = "vnet2"
	Vnet2PeeringName = "${local.Preamble}-${local.Vnet2InstanceId}-peering"
	Vnet2PrivateSubnetPrefix = "192.168.2.0/24"
	Vnet2PublicSubnetPrefix = "192.168.10.0/24"
}