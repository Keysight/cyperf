locals {
	AgentMachineType = var.AgentMachineType
	Agent1InstanceId = "agent1"
	Agent2Eth0PrivateIpAddress = "10.0.10.12"
	Agent2Eth1PrivateIpAddress = "10.0.3.15"
	Agent2Eth1PrivateIpAliases = "/28"
	Agent2InstanceId = "agent2"
	AppMachineType = var.AppMachineType
	AppTag = "cyperf"
	Preamble = "${local.UserLoginTag}-${local.UserProjectTag}-${local.AppTag}-${local.Agent2InstanceId}"
	Private1VpcNetworkPeerName = "${local.Preamble}-test1-vpc-peer"
	Private2VpcNetworkPeerName = "${local.Preamble}-test2-vpc-peer"
	PublicFirewallRuleSourceIpRanges = var.PublicFirewallRuleSourceIpRanges == null ? [ "${data.http.ip.response_body}/32" ] : var.PublicFirewallRuleSourceIpRanges
	UserEmailTag = var.UserEmailTag == null ? data.google_client_openid_userinfo.current.email : var.UserEmailTag
	UserLoginTag = var.UserLoginTag == null ? "terraform" : var.UserLoginTag
	UserProjectTag = var.UserProjectTag == null ? lower(random_id.RandomId.id) : var.UserProjectTag
}