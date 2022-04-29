locals {
	AgentAmiName = var.AgentAmiName
	AgentAmiOwner = var.AgentAmiOwner
	AgentControlCidr = var.AgentControlCidr
	AgentControlCidr1 = var.AgentControlCidr1
	AgentControlCidr2 = var.AgentControlCidr2
	AgentTestCidr = var.AgentTestCidr
	AgentTestCidr1 = var.AgentTestCidr1
	AgentTestCidr2 = var.AgentTestCidr2
	AllowedSubnet = var.AllowedSubnet
	ApplicationLBHTTPHealthChkPort = var.ApplicationLBHTTPHealthChkPort
	ApplicationLBHTTPListenerPort = var.ApplicationLBHTTPListenerPort
	ApplicationLBHTTPSHealthChkPort = var.ApplicationLBHTTPSHealthChkPort
	ApplicationLBHTTPSListenerPort = var.ApplicationLBHTTPSListenerPort
	ControllerAmiName = var.ControllerAmiName
	ControllerNetworkCidr1 = var.ControllerNetworkCidr1
	ControllerNetworkCidr2 = var.ControllerNetworkCidr2
	ControllerAmiOwner = var.ControllerAmiOwner
	FlowLogTrafficType = var.FlowLogTrafficType
	InstanceTypeForCyPerfAgent = var.InstanceTypeForCyPerfAgent
	InstanceTypeForCyPerfApp = var.InstanceTypeForCyPerfApp
	KeyNameForCyPerfAgent = var.KeyNameForCyPerfAgent
	KeyUsername = var.KeyUsername
	NetworkOutBytesPerMinute = var.NetworkOutBytesPerMinute
	Project = var.Project
	Region = data.aws_region.current.name
	RuleAction = var.RuleAction
	ScaleCapacityMax = var.ScaleCapacityMax
	ScaleCapacityMin = var.ScaleCapacityMin
	StackName = var.StackName
	StackPrefix = var.StackPrefix
	TagBehindApplicationLB = var.TagBehindApplicationLB
	TimeSleepDelay = var.TimeSleepDelay
	Username = var.CS_Owner_Email
	VpcCidr = var.VpcCidr
}

locals {
    agent_init_cli_behind_alb = <<-EOF
#!/bin/bash -xe
cd /opt/keysight/tiger/active/bin/
sh /opt/keysight/tiger/active/bin/Appsec_init ${aws_instance.CyPerfUI.private_ip} --behind-alb >> /var/log/Appsec_init.log
    EOF
	agent_init_cli = <<-EOF
#!/bin/bash -xe
cd /opt/keysight/tiger/active/bin/
sh /opt/keysight/tiger/active/bin/Appsec_init ${aws_instance.CyPerfUI.public_ip} >> /var/log/Appsec_init.log
    EOF
}

resource "aws_wafregional_sql_injection_match_set" wafrSQLiSet {
	name = "${local.StackPrefix}-detect-sqli"
	sql_injection_match_tuple {
		field_to_match {
			type = "URI"
		}
		text_transformation = "URL_DECODE"
	}
	sql_injection_match_tuple {
		field_to_match {
			type = "URI"
		}
		text_transformation = "HTML_ENTITY_DECODE"
	}
	sql_injection_match_tuple {
		field_to_match {
			type = "QUERY_STRING"
		}
		text_transformation = "URL_DECODE"
	}
	sql_injection_match_tuple {
		field_to_match {
			type = "QUERY_STRING"
		}
		text_transformation = "HTML_ENTITY_DECODE"
	}
	sql_injection_match_tuple {
		field_to_match {
			type = "BODY"
		}
		text_transformation = "URL_DECODE"
	}
	sql_injection_match_tuple {
		field_to_match {
			type = "BODY"
		}
		text_transformation = "HTML_ENTITY_DECODE"
	}
	sql_injection_match_tuple {
		field_to_match {
			type = "HEADER"
            data = "cookie"
		}
		text_transformation = "URL_DECODE"
	}
	sql_injection_match_tuple {
		field_to_match {
			type = "HEADER"
            data = "cookie"
		}
		text_transformation = "HTML_ENTITY_DECODE"
	}
}

resource "aws_wafregional_rule" "wafrSQLiRule" {
	metric_name = "${local.StackPrefix}mitigatesqli"
	name = "${local.StackPrefix}-mitigate-sqli"
	predicate {
		type = "SqlInjectionMatch"
		negated = false
        data_id = aws_wafregional_sql_injection_match_set.wafrSQLiSet.id
	}
	depends_on = [
		aws_wafregional_sql_injection_match_set.wafrSQLiSet
	]
}

resource "aws_wafregional_web_acl" "wafrOwaspACL" {
	metric_name = "${local.StackPrefix}owaspacl"
	name = "${local.StackPrefix}-owasp-acl"
	default_action {
        type = "ALLOW"
	}
	rule {
		action {
			type = local.RuleAction
		}
		priority = 40
		rule_id = aws_wafregional_rule.wafrSQLiRule.id
	}
	depends_on = [
		aws_wafregional_rule.wafrSQLiRule
	]
}

resource "aws_lb" "ApplicationElasticLB" {
	name = "${local.StackName}-ApplicationLB-HQ"
	internal = false
	security_groups = [
		aws_security_group.LoadBalancerSecurityGroup.id
	]
	subnets = [
		aws_subnet.ControllerManagementSubnet.id,
		aws_subnet.LoadBalancerPublicSubnet.id
	]
}

resource "aws_vpc_dhcp_options_association" "DhcpOptionsAssociationAlpha" {
	dhcp_options_id = aws_vpc_dhcp_options.VPCxDhcpOptionsAlpha.id
	vpc_id = aws_vpc.VPCAlpha.id
}

resource "aws_iam_instance_profile" "EC2InstanceProfileAlpha" {
	name = "${local.Project}_EC2InstanceProfile_ALPHA_${local.Region}"
	role = aws_iam_role.EC2IfaceRoleAlpha.name
}

resource "aws_iam_role_policy_attachment" "EC2IfacePolicyAttachmentAlpha" {
	role = aws_iam_role.EC2IfaceRoleAlpha.name
	policy_arn = aws_iam_policy.EC2IfacePolicyAlpha.arn
}

resource "aws_iam_role" "EC2IfaceRoleAlpha" {
 	name = "${local.Project}_EC2_IFACE_ROLE_ALPHA_${local.Region}"
	assume_role_policy = <<EOF
{
 	"Version": "2012-10-17",
	"Statement": [
	    {
	        "Action": "sts:AssumeRole",
	        "Principal": {
	            "Service": "ec2.amazonaws.com"
	        },
	        "Effect": "Allow"
		}
	]
}
EOF
	path = "/"
}

resource "aws_iam_policy" "EC2IfacePolicyAlpha" {
	name = "${local.Project}_EC2IfacePolicy_ALPHA_${local.Region}"
	description = "EC2IfacePolicyAlpha"
	policy = jsonencode({
		Version = "2012-10-17"
		Statement = [
			{
				Action = [
					"ec2:CreateNetworkInterface",
					"ec2:DescribeInstances",
					"ec2:ModifyNetworkInterfaceAttribute",
					"ec2:AttachNetworkInterface",
					"ec2:DescribeSubnets",
					"ec2:DescribeSecurityGroups",
					"ec2:DescribeTags"
				]
				Effect = "Allow",
				Resource = "*"
			}
		]
	})
}

resource "aws_default_security_group" "DefaultEgress1Alpha" {
	vpc_id = aws_vpc.VPCAlpha.id
	egress {
		protocol = -1
		self = true
		from_port = 0
		to_port = 0
	}
}

resource "aws_internet_gateway" "InternetGatewayAlpha" {
	vpc_id = aws_vpc.VPCAlpha.id
	tags = {
		Name = "${local.StackName}-InternetGateway-HQ"
		Project = local.Project
		Owner = local.Username
	}
}

resource "aws_launch_configuration" "LaunchConfiguration" {
	depends_on = [
		aws_instance.CyPerfUI,
		aws_iam_instance_profile.EC2InstanceProfileAlpha
	]
	root_block_device {
		volume_size = 8
		delete_on_termination = true
	}
	iam_instance_profile = aws_iam_instance_profile.EC2InstanceProfileAlpha.id
	image_id = data.aws_ami.AMI_AGENT.image_id
	instance_type = local.InstanceTypeForCyPerfAgent
	key_name = local.KeyNameForCyPerfAgent
	security_groups = [
		aws_security_group.MgmtInstanceSecurityGroup.id
	]
    user_data = local.agent_init_cli_behind_alb
}

resource "aws_lb_listener" "ListenerApplication" {
	default_action {
		target_group_arn = aws_lb_target_group.TargetGroupWebApplication.arn
		type = "forward"
	}
	load_balancer_arn = aws_lb.ApplicationElasticLB.arn
	port = local.ApplicationLBHTTPListenerPort
	protocol = "HTTP"
}

resource "aws_lb_listener" "ListenerSSL" {
	certificate_arn = aws_acm_certificate.cert.arn
	default_action {
		target_group_arn = aws_lb_target_group.TargetGroupWebApplicationHTTPS.arn
		type = "forward"
	}
	load_balancer_arn = aws_lb.ApplicationElasticLB.arn
	port = local.ApplicationLBHTTPSListenerPort
	protocol = "HTTPS"
	depends_on = [
		aws_lb_target_group.TargetGroupWebApplicationHTTPS,
		aws_lb.ApplicationElasticLB,
		aws_acm_certificate.cert
	]
}

resource "aws_security_group" "CyPerfUISecurityGroup" {
	description = "Allow restricted-access to launched Instances"
	egress {
		cidr_blocks = [ "0.0.0.0/0" ]
		description = "All Traffic"
		from_port = 0
		protocol = "-1"
		to_port = 0
	}
	ingress {
		description = "All Traffic"
		protocol = -1
		self = true
		from_port = 0
		to_port = 0
	}
	ingress {
		cidr_blocks = [ "0.0.0.0/0" ]
		description = "Custom TCP"
		from_port = 30422
		protocol = "tcp"
		to_port = 30422
	}
	ingress {
		cidr_blocks = [ local.AllowedSubnet ]
		description = "Custom TCP"
		from_port = 80
		protocol = "tcp"
		to_port = 80
	}
	ingress {
		cidr_blocks = [ local.AllowedSubnet ]
		description = "Custom TCP"
		from_port = 443
		protocol = "tcp"
		to_port = 443
	}
	ingress {
		cidr_blocks = [ local.AllowedSubnet ]
		description = "Custom TCP"
		from_port = 22
		protocol = "tcp"
		to_port = 22
	}
	ingress {
		cidr_blocks = [ local.VpcCidr ]
		description = "Custom TCP"
		from_port = 443
		protocol = "tcp"
		to_port = 443
	}
	tags = {
		Name = "${local.StackName}-CyPerfUISG-HQ"
		Project = local.Project
		Owner = local.Username
	}
	vpc_id = aws_vpc.VPCAlpha.id
}

resource "aws_security_group_rule" "MgmtIngress1" {
	type = "ingress"
	security_group_id = aws_security_group.CyPerfUISecurityGroup.id
	cidr_blocks = [ "${aws_instance.ClientAgentBravo.public_ip}/32" ]
	description = "All Traffic"
	from_port = 0
	protocol = "-1"
	to_port = 0
	depends_on = [
		aws_security_group.CyPerfUISecurityGroup,
		aws_instance.ClientAgentBravo
	]
}

resource "aws_security_group" "LoadBalancerSecurityGroup" {
	depends_on = [
		aws_security_group.MgmtInstanceSecurityGroup
	]
	description = "Allow restricted-access to launched Instances"
	egress {
		security_groups = [
			aws_security_group.MgmtInstanceSecurityGroup.id
		]
		description = "Custom TCP"
		from_port = 80
		protocol = "tcp"
		to_port = 80
	}
	egress {
		security_groups = [
			aws_security_group.MgmtInstanceSecurityGroup.id
		]
		description = "Custom TCP"
		from_port = "443"
		protocol = "tcp"
		to_port = "443"
	}
	ingress {
		cidr_blocks = [ "0.0.0.0/0" ]
		description = "Custom TCP"
		from_port = 80
		protocol = "tcp"
		to_port = 80
	}
	ingress {
		cidr_blocks = [ "0.0.0.0/0" ]
		description = "Custom TCP"
		from_port = 443
		protocol = "tcp"
		to_port = 443
	}
	tags = {
		Name = "${local.StackName}-LoadBalancerSG-HQ"
		Project = local.Project
		Owner = local.Username
	}
	vpc_id = aws_vpc.VPCAlpha.id
}

resource "aws_security_group" "MgmtInstanceSecurityGroup" {
	name = "${local.StackName}-MgmtInstanceSecurityGroup-HQ"
	description = "Allow restricted-access to launched Instances"
	egress {
		cidr_blocks = [ "0.0.0.0/0" ]
		description = "All Traffic"
		from_port = 0
		protocol = "-1"
		to_port = 0
	}
	ingress {
		cidr_blocks = [ local.VpcCidr ]
		description = "Custom TCP"
		from_port = 80
		protocol = "tcp"
		to_port = 80
	}
	ingress {
		cidr_blocks = [ local.VpcCidr ]
		description = "Custom TCP"
		from_port = 443
		protocol = "tcp"
		to_port = 443
	}
	ingress {
		cidr_blocks = [ local.VpcCidr ]
		description = "Custom TCP"
		from_port = 22
		protocol = "tcp"
		to_port = 22
	}
	tags = {
		Name = "${local.StackName}-CyPerfAgentSG-HQ"
		Project = local.Project
		Owner = local.Username
	}
	vpc_id = aws_vpc.VPCAlpha.id
}

resource "aws_nat_gateway" "Nat" {
	depends_on = [
		aws_internet_gateway.InternetGatewayAlpha,
		aws_eip.NatEip,
		aws_subnet.ControllerManagementSubnet
	]
	allocation_id = aws_eip.NatEip.allocation_id
	subnet_id = aws_subnet.ControllerManagementSubnet.id
	tags = {
		Name = "${local.StackName}-NatGateway-HQ"
		Project = local.Project
		Owner = local.Username
	}
}

resource "aws_eip" "NatEip" {
	vpc = true
	depends_on = [
		aws_internet_gateway.InternetGatewayAlpha
	]
}

resource "aws_route" "NatRoute" {
	depends_on = [
		aws_nat_gateway.Nat,
		aws_route_table.PrivateRouteTable,
		aws_subnet.ControllerManagementSubnet
	]
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = aws_nat_gateway.Nat.id
	route_table_id = aws_route_table.PrivateRouteTable.id
}

resource "aws_instance" "CyPerfUI" {
	depends_on = [
		aws_network_interface.mdweth0,
		aws_iam_instance_profile.EC2InstanceProfileAlpha
	]
	root_block_device {
		volume_size = 100
		delete_on_termination = true
	}
	iam_instance_profile = aws_iam_instance_profile.EC2InstanceProfileAlpha.id
	ami = data.aws_ami.AMI_APP.image_id
	instance_type = local.InstanceTypeForCyPerfApp
	key_name = local.KeyNameForCyPerfAgent
	network_interface {
		device_index = 0
		network_interface_id = aws_network_interface.mdweth0.id
	}
	tags = {
		Name = "${local.StackName}-Controller"
		Project = local.Project
		Owner = local.Username
		ci-key-username = local.KeyUsername
	}
}

resource "aws_instance" "ClientAgentAlpha" {
	depends_on = [
		aws_network_interface.clieth0,
		aws_instance.CyPerfUI,
		aws_iam_instance_profile.EC2InstanceProfileAlpha
	]
	root_block_device {
		volume_size = 8
		delete_on_termination = true
	}
	iam_instance_profile = aws_iam_instance_profile.EC2InstanceProfileAlpha.id
	ami = data.aws_ami.AMI_AGENT.image_id
	instance_type = local.InstanceTypeForCyPerfAgent
	key_name = local.KeyNameForCyPerfAgent
	network_interface {
		device_index = 0
		network_interface_id = aws_network_interface.clieth0.id
	}
    user_data = local.agent_init_cli_behind_alb
	tags = {
		Name = "${local.StackName}-Client-HQ"
		Project = local.Project
		Owner = local.Username
		ci-key-username = local.KeyUsername
	}
}

resource "aws_route_table" "PrivateRouteTable" {
	tags = {
		Name = "${local.StackName}-PrivateRouteTable-HQ"
	}
	vpc_id = aws_vpc.VPCAlpha.id
}

resource "aws_route_table_association" "AgentTestSubnetRouteTable1" {
	depends_on = [
		aws_route_table.PrivateRouteTable,
		aws_subnet.AgentTestSubnet1
	]
	route_table_id = aws_route_table.PrivateRouteTable.id
	subnet_id = aws_subnet.AgentTestSubnet1.id
}

resource "aws_route_table_association" "AgentTestSubnetRouteTable2"  {
	depends_on = [
		aws_route_table.PrivateRouteTable,
		aws_subnet.AgentTestSubnet2
	]
	route_table_id = aws_route_table.PrivateRouteTable.id
	subnet_id = aws_subnet.AgentTestSubnet2.id
}

resource "aws_route_table_association" "AgentControlSubnetRouteTable1" {
	depends_on = [
		aws_route_table.PrivateRouteTable,
		aws_subnet.AgentControlSubnet1
	]
	route_table_id = aws_route_table.PrivateRouteTable.id
	subnet_id = aws_subnet.AgentControlSubnet1.id
}

resource "aws_route_table_association" "AgentControlSubnetRouteTable2" {
	depends_on = [
		aws_route_table.PrivateRouteTable,
		aws_subnet.AgentControlSubnet2
	]
	route_table_id = aws_route_table.PrivateRouteTable.id
	subnet_id = aws_subnet.AgentControlSubnet2.id
}

resource "aws_route_table" "PublicRouteTableAlpha" {
	tags = {
		Name = "${local.StackName}-PublicRouteTable-HQ"
	}
	vpc_id = aws_vpc.VPCAlpha.id
}

resource "aws_route_table_association" "ControllerManagementSubnetRouteTable" {
	depends_on = [
		aws_route_table.PublicRouteTableAlpha,
		aws_subnet.ControllerManagementSubnet
	]
	route_table_id = aws_route_table.PublicRouteTableAlpha.id
	subnet_id = aws_subnet.ControllerManagementSubnet.id
}

resource "aws_route_table_association" "LoadBalancerPublicSubnetRouteTable" {
	depends_on = [
		aws_route_table.PublicRouteTableAlpha,
		aws_subnet.LoadBalancerPublicSubnet
	]
	route_table_id = aws_route_table.PublicRouteTableAlpha.id
	subnet_id = aws_subnet.LoadBalancerPublicSubnet.id
}

resource "aws_route" "RouteToInternetAlpha" {
	depends_on = [
		aws_internet_gateway.InternetGatewayAlpha
	]
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.InternetGatewayAlpha.id
	route_table_id = aws_route_table.PublicRouteTableAlpha.id
}

resource "aws_subnet" "AgentTestSubnet1" {
	availability_zone = data.aws_availability_zones.available.names[0]
	cidr_block = local.AgentTestCidr1
	tags = {
		Name = "${local.StackName}-AgentTestSubnet1-HQ"
		Project = local.Project
		Owner = local.Username
	}
	vpc_id = aws_vpc.VPCAlpha.id
}

resource "aws_subnet" "AgentTestSubnet2" {
	availability_zone = data.aws_availability_zones.available.names[1]
	cidr_block = local.AgentTestCidr2
	tags = {
		Name = "${local.StackName}-AgentTestSubnet2-HQ"
		Project = local.Project
		Owner = local.Username
	}
	vpc_id = aws_vpc.VPCAlpha.id
}

resource "aws_subnet" "AgentControlSubnet1" {
	availability_zone = data.aws_availability_zones.available.names[0]
	cidr_block = local.AgentControlCidr1
	tags = {
		Name = "${local.StackName}-AgentControlMessageBrokerSubnet1-HQ"
		Project = local.Project
		Owner = local.Username
	}
	vpc_id = aws_vpc.VPCAlpha.id
}

resource "aws_subnet" "AgentControlSubnet2" {
	availability_zone = data.aws_availability_zones.available.names[1]
	cidr_block = local.AgentControlCidr2
	tags = {
		Name = "${local.StackName}-AgentControlMessageBrokerSubnet2-HQ"
		Project = local.Project
		Owner = local.Username
	}
	vpc_id = aws_vpc.VPCAlpha.id
}

resource "aws_subnet" "ControllerManagementSubnet" {
	availability_zone = data.aws_availability_zones.available.names[0]
	cidr_block = local.ControllerNetworkCidr1
	map_public_ip_on_launch = true
	tags = {
		Name = "${local.StackName}-ControllerManagementSubnet-HQ"
		Project = local.Project
		Owner = local.Username
	}
	vpc_id = aws_vpc.VPCAlpha.id
}

resource "aws_subnet" "LoadBalancerPublicSubnet" {
	availability_zone = data.aws_availability_zones.available.names[1]
	cidr_block = local.ControllerNetworkCidr2
	map_public_ip_on_launch = true
	tags = {
		Name = "${local.StackName}-LoadBalancerPublicSubnet-HQ"
		Project = local.Project
		Owner = local.Username
	}
	vpc_id = aws_vpc.VPCAlpha.id
}

resource "aws_lb_target_group" "TargetGroupWebApplication" {
	health_check {
		interval = 6
		path = "/CyPerfHTTPHealthCheck"
		port = local.ApplicationLBHTTPHealthChkPort
		protocol = "HTTP"
		timeout = 5
		healthy_threshold = 2
		matcher = "200"
		unhealthy_threshold = 3
	}
	name = "${local.StackName}-TG-AppLB-HQ"
	port = local.ApplicationLBHTTPListenerPort
	protocol = "HTTP"
	vpc_id = aws_vpc.VPCAlpha.id
	stickiness {
		type = "lb_cookie"
		enabled = false
		cookie_duration = 120
	}
}

resource "aws_lb_target_group" "TargetGroupWebApplicationHTTPS" {
	health_check {
		interval = 6
		path = "/CyPerfHTTPSHealthCheck"
		port = local.ApplicationLBHTTPSHealthChkPort
		protocol = "HTTPS"
		timeout = 5
		healthy_threshold = 2
		matcher = "200"
		unhealthy_threshold = 3
	}
	name = "${local.StackName}-TG-HTTPSAppLB-HQ"
	port = local.ApplicationLBHTTPSListenerPort
	protocol = "HTTPS"
	vpc_id = aws_vpc.VPCAlpha.id
	stickiness {
		type = "lb_cookie"
		enabled = false
		cookie_duration = 120
	}
}

resource "aws_vpc" "VPCAlpha" {
	cidr_block = local.VpcCidr
	enable_dns_hostnames = true
	enable_dns_support = true
	tags = {
		Name = "${local.StackName}-VPC-HQ"
		Project = local.Project
		Owner = local.Username
	}
}

resource "aws_vpc_dhcp_options" "VPCxDhcpOptionsAlpha" {
	domain_name = "VPCxDhcpOptionsAlpha"
	domain_name_servers = [
		"8.8.8.8",
		"8.8.4.4",
		"AmazonProvidedDNS"
	]
	tags = {
		Name = "CyPerfVPCx"
		Project = local.Project
		Owner = local.Username
	}
}

resource "aws_iam_role" "VPCFlowLogAccessRoleAlpha" {
	name = "${local.Project}_VPC_FLOW_LOG_ACCESS_ROLE_ALPHA_${local.Region}"
	assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": "sts:AssumeRole",
			"Principal": {
				"Service": "vpc-flow-logs.amazonaws.com"
			},
			"Effect": "Allow"
		}
	]
}
EOF
	permissions_boundary = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
	path = "/"
}

resource "aws_cloudwatch_log_group" "VpcFlowLogGroupAlpha" {
	name = "${local.Project}_VPC_FLOW_LOG_GROUP_ALPHA_${local.Region}"
}

resource "aws_flow_log" "KeyVpcFlowLogAlpha" {
	log_destination =  aws_cloudwatch_log_group.VpcFlowLogGroupAlpha.arn
	iam_role_arn = aws_iam_role.VPCFlowLogAccessRoleAlpha.arn
	vpc_id = aws_vpc.VPCAlpha.id
	traffic_type = local.FlowLogTrafficType
}

resource "aws_network_interface" "mdweth0" {
	description = "MDW eth0"
	security_groups = [
		aws_security_group.CyPerfUISecurityGroup.id
	]
	source_dest_check = true
	subnet_id = aws_subnet.ControllerManagementSubnet.id
	tags = {
		Name = "${local.StackName}-MB-Interface-HQ"
		Project = local.Project
		Owner = local.Username
	}
}

resource "aws_network_interface" "clieth0" {
	description = "Client Agent eth0"
	security_groups = [
		aws_security_group.MgmtInstanceSecurityGroup.id
	]
	source_dest_check = true
	subnet_id = aws_subnet.AgentTestSubnet1.id
	tags = {
		Name = "${local.StackName}-CA-Interface-HQ"
		Project = local.Project
		Owner = local.Username
	}
}

resource "aws_autoscaling_group" "AutoscalingGroupALB" {
	default_cooldown = 60
	desired_capacity = local.ScaleCapacityMin
	health_check_type = "EC2"
	launch_configuration = aws_launch_configuration.LaunchConfiguration.id
	max_size = local.ScaleCapacityMax
	min_size = local.ScaleCapacityMin
	tag {
		key = "Name"
		propagate_at_launch = true
		value = "${local.StackName}-${local.TagBehindApplicationLB}-HQ"
	}
	tag {
		key = "TagName"
		propagate_at_launch = true
		value = local.TagBehindApplicationLB
	}
	tag {
		key = "Project"
		propagate_at_launch = true
		value = local.Project
	}
	tag {
		key = "Owner"
		propagate_at_launch = true
 		value = local.Username
	}
	tag {
		key = "ci-key-username"
		propagate_at_launch = true
		value = local.KeyUsername
	}
	target_group_arns = [
		aws_lb_target_group.TargetGroupWebApplication.arn,
		aws_lb_target_group.TargetGroupWebApplicationHTTPS.arn
	]
	vpc_zone_identifier = [
		aws_subnet.AgentTestSubnet1.id,
		aws_subnet.AgentTestSubnet2.id
	]
}

resource "aws_autoscaling_policy" "AutoscalingPolicyALB" {
	name = "${local.Project}-AutoscalingPolicyALB"
	autoscaling_group_name = aws_autoscaling_group.AutoscalingGroupALB.name
	policy_type = "TargetTrackingScaling"
	target_tracking_configuration {
		predefined_metric_specification {
			predefined_metric_type = "ASGAverageNetworkOut"
        }
		target_value = local.NetworkOutBytesPerMinute
	}
}

resource "time_sleep" "delay" {
	create_duration = local.TimeSleepDelay
	depends_on = [
		aws_lb_listener.ListenerSSL
	]
}

resource "aws_wafregional_web_acl_association" "MyWebACLAssociation" {
	resource_arn = aws_lb.ApplicationElasticLB.arn
	web_acl_id = aws_wafregional_web_acl.wafrOwaspACL.id
	depends_on = [
		time_sleep.delay,
		aws_lb.ApplicationElasticLB,
		aws_wafregional_web_acl.wafrOwaspACL
	]
}

resource "aws_autoscaling_lifecycle_hook" "myLifecycleHook" {
	name = "${local.Project}-myLifecycleHook"
	autoscaling_group_name = aws_autoscaling_group.AutoscalingGroupALB.name
	lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
	heartbeat_timeout = 180
	default_result = "CONTINUE"
}

resource "aws_vpc_dhcp_options_association" "DhcpOptionsAssociationBravo" {
	dhcp_options_id = aws_vpc_dhcp_options.VPCxDhcpOptionsBravo.id
	vpc_id = aws_vpc.VPCBravo.id
}

resource "aws_iam_instance_profile" "EC2InstanceProfileBravo" {
	name = "${local.Project}_EC2InstanceProfile_BRAVO_${local.Region}"
	role = aws_iam_role.EC2IfaceRoleBravo.name
}

resource "aws_iam_role_policy_attachment" "EC2IfacePolicyAttachmentBravo" {
	role = aws_iam_role.EC2IfaceRoleBravo.name
	policy_arn = aws_iam_policy.EC2IfacePolicyBravo.arn
}

resource "aws_iam_role" "EC2IfaceRoleBravo" {
 	name = "${local.Project}_EC2_IFACE_ROLE_BRAVO_${local.Region}"
	assume_role_policy = <<EOF
{
 	"Version": "2012-10-17",
	"Statement": [
	    {
	        "Action": "sts:AssumeRole",
	        "Principal": {
	            "Service": "ec2.amazonaws.com"
	        },
	        "Effect": "Allow"
		}
	]
}
EOF
	path = "/"
}

resource "aws_iam_policy" "EC2IfacePolicyBravo" {
	name = "${local.Project}_EC2IfacePolicy_BRAVO_${local.Region}"
	description = "EC2IfacePolicy"
	policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": [
				"ec2:CreateNetworkInterface",
				"ec2:DescribeInstances",
				"ec2:ModifyNetworkInterfaceAttribute",
				"ec2:AttachNetworkInterface",
				"ec2:DescribeSubnets",
				"ec2:DescribeSecurityGroups",
				"ec2:DescribeTags"
			],
			"Effect": "Allow",
			"Resource": "*"
		}
	]
}
EOF
}

resource "aws_default_security_group" "DefaultEgress1Bravo" {
	vpc_id = aws_vpc.VPCBravo.id
	egress {
		protocol = -1
		self = true
		from_port = 0
		to_port = 0
	}
}

resource "aws_internet_gateway" "InternetGatewayBravo" {
	vpc_id = aws_vpc.VPCBravo.id
	tags = {
		Name = "${local.StackName}-InternetGateway-Branch"
		Project = local.Project
		Owner = local.Username
	}
}

resource "aws_security_group" "AgentSecurityGroup" {
	description = "Allow restricted-access to launched Instances"
	egress {
		cidr_blocks = [ "0.0.0.0/0" ]
		description = "All Traffic"
		from_port = 0
		protocol = "-1"
		to_port = 0
	}
	ingress {
		cidr_blocks = [ local.VpcCidr ]
		description = "Custom TCP"
		from_port = 80
		protocol = "tcp"
		to_port = 80
	}
	ingress {
		cidr_blocks = [ local.VpcCidr ]
		description = "Custom TCP"
		from_port = 443
		protocol = "tcp"
		to_port = 443
	}
	ingress {
		cidr_blocks = [ "0.0.0.0/0" ]
		description = "Custom TCP"
		from_port = 80
		protocol = "tcp"
		to_port = 80
	}
	ingress {
		cidr_blocks = [ "0.0.0.0/0" ]
		description = "Custom TCP"
		from_port = 443
		protocol = "tcp"
		to_port = 443
	}
	ingress {
		cidr_blocks = [ local.VpcCidr ]
		description = "Custom TCP"
		from_port = 22
		protocol = "tcp"
		to_port = 22
	}
	ingress {
		cidr_blocks = [ local.AllowedSubnet ]
		description = "Custom TCP"
		from_port = 22
		protocol = "tcp"
		to_port = 22
	}
	ingress {
		cidr_blocks = [ "${aws_instance.CyPerfUI.public_ip}/32" ]
		description = "All Traffic"
		from_port = 0
		protocol = "-1"
		to_port = 0
	}
	tags = {
		Name = "${local.StackName}-CyPerfAgentSG-Branch"
		Project = local.Project
		Owner = local.Username
	}
	vpc_id = aws_vpc.VPCBravo.id
}

resource "aws_instance" "ClientAgentBravo" {
	depends_on = [
		aws_network_interface.agenteth0,
		aws_network_interface.agenteth1,
		aws_iam_instance_profile.EC2InstanceProfileBravo
	]
	root_block_device {
		volume_size = 8
		delete_on_termination = true
	}
	iam_instance_profile = aws_iam_instance_profile.EC2InstanceProfileBravo.id
	ami = data.aws_ami.AMI_AGENT.image_id
	instance_type = local.InstanceTypeForCyPerfAgent
	key_name = local.KeyNameForCyPerfAgent
	network_interface {
		device_index = 0
		network_interface_id = aws_network_interface.agenteth0.id
	}
	network_interface {
		device_index = 1
		network_interface_id = aws_network_interface.agenteth1.id
	}
    user_data = local.agent_init_cli
	tags = {
		Name = "${local.StackName}-Client-Branch"
		Project = local.Project
		Owner = local.Username
		ci-key-username = local.KeyUsername
	}
}

resource "aws_route_table_association" "AgentControlSubnetRouteTable" {
	depends_on = [
		aws_subnet.AgentControlSubnet
	]
	route_table_id = aws_route_table.PublicRouteTableBravo.id
	subnet_id = aws_subnet.AgentControlSubnet.id
}

resource "aws_route_table_association" "AgentTestSubnetRouteTable" {
	depends_on = [
		aws_subnet.AgentTestSubnet
	]
	route_table_id = aws_route_table.PublicRouteTableBravo.id
	subnet_id = aws_subnet.AgentTestSubnet.id
}

resource "aws_route_table" "PublicRouteTableBravo" {
	tags = {
		Name = "${local.StackName}-PublicRouteTable-Branch"
	}
	vpc_id = aws_vpc.VPCBravo.id
}

resource "aws_route" "RouteToInternetBravo" {
	depends_on = [
		aws_internet_gateway.InternetGatewayBravo
	]
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.InternetGatewayBravo.id
	route_table_id = aws_route_table.PublicRouteTableBravo.id
}

resource "aws_subnet" "AgentControlSubnet" {
	availability_zone = data.aws_availability_zones.available.names[2]
	cidr_block = local.AgentControlCidr
	tags = {
		Name = "${local.StackName}-AgentControlSubnet-Branch"
		Project = local.Project
		Owner = local.Username
	}
	vpc_id = aws_vpc.VPCBravo.id
}

resource "aws_subnet" "AgentTestSubnet" {
	availability_zone = data.aws_availability_zones.available.names[2]
	cidr_block = local.AgentTestCidr
	tags = {
		Name = "${local.StackName}-AgentTestSubnet-Branch"
		Project = local.Project
		Owner = local.Username
	}
	vpc_id = aws_vpc.VPCBravo.id
}

resource "aws_vpc" "VPCBravo" {
	cidr_block = local.VpcCidr
	enable_dns_hostnames = true
	enable_dns_support = true
	tags = {
		Name = "${local.StackName}-VPC-Branch"
		Project = local.Project
		Owner = local.Username
	}
}

resource "aws_vpc_dhcp_options" "VPCxDhcpOptionsBravo" {
	domain_name = "VPCxDhcpOptionsBravo"
	domain_name_servers = [
		"8.8.8.8",
		"8.8.4.4",
		"AmazonProvidedDNS"
	]
	tags = {
		Name = "CyPerfVPCx"
		Project = local.Project
		Owner = local.Username
	}
}

resource "aws_iam_role" "VPCFlowLogAccessRoleBravo" {
	name = "${local.Project}_VPC_FLOW_LOG_ACCESS_ROLE_BRAVO_${local.Region}"
	assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": "sts:AssumeRole",
			"Principal": {
				"Service": "vpc-flow-logs.amazonaws.com"
			},
			"Effect": "Allow"
		}
	]
}
EOF
	permissions_boundary = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
	path = "/"
}

resource "aws_cloudwatch_log_group" "VpcFlowLogGroupBravo" {
	name = "${local.Project}_VPC_FLOW_LOG_GROUP_BRAVO_${local.Region}"
}

resource "aws_flow_log" "KeyVpcFlowLogBravo" {
	log_destination =  aws_cloudwatch_log_group.VpcFlowLogGroupBravo.arn
	iam_role_arn = aws_iam_role.VPCFlowLogAccessRoleBravo.arn
	vpc_id = aws_vpc.VPCBravo.id
	traffic_type = local.FlowLogTrafficType
}

resource "aws_eip" "AgentControlAddress" {
	vpc = true
	network_interface = aws_network_interface.agenteth0.id
}

resource "aws_eip" "AgentTestAddress"  {
	vpc = true
	network_interface = aws_network_interface.agenteth1.id
}

resource "aws_network_interface" "agenteth0" {
	description = "Client Agent eth0/ens4"
	security_groups = [
		aws_security_group.AgentSecurityGroup.id
	]
	source_dest_check = true
	subnet_id = aws_subnet.AgentControlSubnet.id

	tags = {
		Name = "${local.StackName}-CA-Interface-Branch"
		Project = local.Project
		Owner = local.Username
	}
}
		
resource "aws_network_interface" "agenteth1" {
	description = "Client Agent eth1/ens5"
	security_groups = [
		aws_security_group.AgentSecurityGroup.id
	]
	source_dest_check = true
	subnet_id = aws_subnet.AgentTestSubnet.id

	tags = {
		Name = "${local.StackName}-CA-Interface-Branch"
		Project = local.Project
		Owner = local.Username
	}
}

resource "tls_private_key" "example" {
	algorithm = "RSA"
	rsa_bits  = 4096
}

resource "tls_self_signed_cert" "example" {
	key_algorithm   = "RSA"
	private_key_pem = tls_private_key.example.private_key_pem

	subject {
		common_name  = "example.com"
		organization = "ACME Examples, Inc"
	}

	validity_period_hours = 12

	allowed_uses = [
		"key_encipherment",
		"digital_signature",
		"server_auth"
	]
}

resource "aws_acm_certificate" "cert" {
	private_key = tls_private_key.example.private_key_pem
	certificate_body = tls_self_signed_cert.example.cert_pem
}