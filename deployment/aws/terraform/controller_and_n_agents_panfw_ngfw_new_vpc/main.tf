provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.aws_region
}

locals{
    firewall_cidr = concat(var.aws_allowed_cidr,[var.aws_main_cidr])
    options_tag             = "MANUAL"
    project_tag             = "CyPerf"
    cli_agent_tag               = "clientagent"
    srv_agent_tag               = "serveragent"
    agent_init_cli = <<-EOF
        #! /bin/bash
        sudo sudo chmod 777 /var/log/
        sudo sh /opt/keysight/tiger/active/bin/Appsec_init ${module.mdw.mdw_detail.private_ip} --username "${var.controller_username}" --password "${var.controller_password}">> /var/log/Appsec_init.log
    EOF
}

resource "aws_vpc" "aws_main_vpc" {
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-main-vpc"
    }
    enable_dns_hostnames = true
    enable_dns_support = true
    cidr_block = var.aws_main_cidr
}


####### Subnets #######
resource "aws_subnet" "aws_management_subnet" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    cidr_block = var.aws_mgmt_cidr
    availability_zone = var.availability_zone
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-management-subnet"
    }
}


resource "aws_subnet" "aws_cli_test_subnet" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    availability_zone = var.availability_zone
    cidr_block = var.aws_cli_test_cidr
    tags = {
        Name = "${var.aws_stack_name}-cli-test-subnet"
    }
}

resource "aws_subnet" "aws_cli_test_subnet_pan" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    availability_zone = var.availability_zone
    cidr_block = var.aws_cli_test_cidr_pan
    tags = {
        Name = "${var.aws_stack_name}-cli-test-subnet-pan"
    }
}

resource "aws_subnet" "aws_srv_test_subnet" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    availability_zone = var.availability_zone
    cidr_block = var.aws_srv_test_cidr
    tags = {
        Name = "${var.aws_stack_name}-srv-test-subnet"
    }
}

resource "aws_subnet" "aws_srv_test_subnet_pan" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    availability_zone = var.availability_zone
    cidr_block = var.aws_srv_test_cidr_pan
    tags = {
        Name = "${var.aws_stack_name}-srv-test-subnet-pan"
    }
}

resource "aws_subnet" "aws_firewall_subnet" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    availability_zone = var.availability_zone
    cidr_block = var.aws_firewall_cidr
    tags = {
        Name = "${var.aws_stack_name}-firewall-subnet"
    }
}

####### Route Tables #######

resource "aws_route_table" "aws_public_rt" {
    vpc_id = aws_vpc.aws_main_vpc.id
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-public-rt"
    }        
}

resource "aws_route_table" "aws_ngfw_rt" {
    vpc_id = aws_vpc.aws_main_vpc.id
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-ngfw-rt"
    }        
}


resource "aws_route_table_association" "aws_mgmt_rt_association" {
    subnet_id      = aws_subnet.aws_management_subnet.id
    route_table_id = aws_route_table.aws_public_rt.id
}

resource "aws_route_table_association" "aws_firewall_rt_association" {
    subnet_id      = aws_subnet.aws_firewall_subnet.id
    route_table_id = aws_route_table.aws_ngfw_rt.id
}

resource "aws_route_table" "aws_private_rt" {
    vpc_id = aws_vpc.aws_main_vpc.id
    tags = {
        Name = "${var.aws_stack_name}-private-rt"
    }    
}

resource "aws_route_table" "aws_private_rt_srv" {
    vpc_id = aws_vpc.aws_main_vpc.id
    tags = {
        Name = "${var.aws_stack_name}-private-rt-srv"
    }    
}

resource "aws_route_table" "aws_igw_rt" {
    vpc_id = aws_vpc.aws_main_vpc.id
    tags = {
        Name = "${var.aws_stack_name}-igw-rt"
    }    
}

resource "aws_route_table_association" "aws_cli_test_rt_association" {
    subnet_id      = aws_subnet.aws_cli_test_subnet.id
    route_table_id = aws_route_table.aws_private_rt.id
}

resource "aws_route_table_association" "aws_srv_test_rt_association" {
    subnet_id      = aws_subnet.aws_srv_test_subnet.id
    route_table_id = aws_route_table.aws_private_rt_srv.id
}

resource "aws_route_table_association" "aws_cli_test_rt_association_pan" {
    subnet_id      = aws_subnet.aws_cli_test_subnet_pan.id
    route_table_id = aws_route_table.aws_private_rt.id
}

resource "aws_route_table_association" "aws_srv_test_rt_association_pan" {
    subnet_id      = aws_subnet.aws_srv_test_subnet_pan.id
    route_table_id = aws_route_table.aws_private_rt_srv.id
}

resource "aws_internet_gateway" "aws_internet_gateway" {
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-internet-gateway"
    }
    vpc_id = aws_vpc.aws_main_vpc.id  
}

resource "aws_route_table_association" "aws_igw_rt_association" {
    depends_on = [
      aws_internet_gateway.aws_internet_gateway
    ]
    gateway_id = aws_internet_gateway.aws_internet_gateway.id
    route_table_id = aws_route_table.aws_igw_rt.id
}

resource "aws_route" "aws_route_to_internet" {
    depends_on = [
      aws_route_table_association.aws_mgmt_rt_association
    ]
    route_table_id            = aws_route_table.aws_public_rt.id
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_internet_gateway.id
}

resource "aws_route" "aws_route_to_ngfw" {
    depends_on = [
      aws_route_table_association.aws_cli_test_rt_association,
      aws_route_table_association.aws_srv_test_rt_association
    ]
    route_table_id            = aws_route_table.aws_private_rt.id
    destination_cidr_block    = "172.16.4.0/24"
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.aws-ngfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.aws_firewall_subnet.id], 0)
}

resource "aws_route" "aws_route_to_ngfw1" {
    depends_on = [
      aws_route_table_association.aws_cli_test_rt_association,
      aws_route_table_association.aws_srv_test_rt_association
    ]
    route_table_id            = aws_route_table.aws_private_rt_srv.id
    destination_cidr_block    = "172.16.3.0/24"
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.aws-ngfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.aws_firewall_subnet.id], 0)
}

resource "aws_route" "aws_route_igw_to_agent1" {
    depends_on = [
      aws_route_table_association.aws_igw_rt_association
    ]
    route_table_id            = aws_route_table.aws_igw_rt.id
    destination_cidr_block    = "172.16.3.0/24"
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.aws-ngfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.aws_firewall_subnet.id], 0)
}

resource "aws_route" "aws_route_igw_to_agent2" {
    depends_on = [
      aws_route_table_association.aws_igw_rt_association
    ]
    route_table_id            = aws_route_table.aws_igw_rt.id
    destination_cidr_block    = "172.16.4.0/24"
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.aws-ngfw.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.aws_firewall_subnet.id], 0)
}

resource "aws_route" "aws_route_ngfw_to_igw" {
    depends_on = [
      aws_route_table_association.aws_firewall_rt_association
    ]
    route_table_id            = aws_route_table.aws_ngfw_rt.id
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id                = aws_internet_gateway.aws_internet_gateway.id
}

####### Security groups #######
resource "aws_security_group" "aws_agent_security_group" {
    name = "agent-security-group"
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-agent-security-group"
    }
    description = "Agent security group"
    vpc_id = aws_vpc.aws_main_vpc.id
}

resource "aws_security_group" "aws_cyperf_security_group" {
    name = "mdw-security-group"
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-cyperf-security-group"
    }
    description = "MDW security group"
    vpc_id = aws_vpc.aws_main_vpc.id
}

####### Firewall Rules #######
resource "aws_security_group_rule" "aws_cyperf_agent_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.firewall_cidr
  ipv6_cidr_blocks  = ["::/128"]
  security_group_id = aws_security_group.aws_agent_security_group.id
}
resource "aws_security_group_rule" "aws_cyperf_agent_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.aws_agent_security_group.id
}
resource "aws_security_group_rule" "aws_cyperf_ui_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.firewall_cidr
  ipv6_cidr_blocks  = ["::/128"]
  security_group_id = aws_security_group.aws_cyperf_security_group.id
}
resource "aws_security_group_rule" "aws_cyperf_ui_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.aws_cyperf_security_group.id
}

####### DHCP #######
resource "aws_vpc_dhcp_options" "aws_main_vpc_dhcp_options" {
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-dhcp-option"
    }
    domain_name_servers  = ["8.8.8.8",
                            "8.8.4.4",
                            "AmazonProvidedDNS" ]
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
    vpc_id          = aws_vpc.aws_main_vpc.id
    dhcp_options_id = aws_vpc_dhcp_options.aws_main_vpc_dhcp_options.id
}

######## Instance Profile #######
data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "inline_policy" {
  statement {
    actions   = ["ec2:CreateNetworkInterface", "ec2:DescribeInstances", "ec2:ModifyNetworkInterfaceAttribute", "ec2:AttachNetworkInterface", "ec2:DescribeSubnets", "ec2:DescribeSecurityGroups", "ec2:DescribeTags", "*"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "instance_iam_role" {
  name               = "${var.aws_stack_name}_instance_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}

resource  aws_iam_role_policy "instance_iam_role_policy" {
    name   = "${var.aws_stack_name}-policy"
    role   = aws_iam_role.instance_iam_role.name
    policy = data.aws_iam_policy_document.inline_policy.json
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.aws_stack_name}-instance_profile"
  role = aws_iam_role.instance_iam_role.name
}

resource "time_sleep" "wait_5_seconds" {
  depends_on = [aws_placement_group.aws_placement_group]
  destroy_duration = "5s"
}

resource "aws_placement_group" "aws_placement_group" {
    name     = "${var.aws_stack_name}-pg-cluster"
    strategy = "cluster"
}

######## pan fw Bootstrap role panrofile #######

data "aws_iam_policy_document" "bootstrap-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "bootstrap_inline_policy" {
  statement {
    actions   = ["s3:ListBucket", "s3:GetObject"]
    resources = ["arn:aws:s3:::${var.panfw_bootstrap_bucket}/*"]
  }
}
resource "aws_iam_role" "bootstrap_iam_role" {
  name               = "${var.aws_stack_name}_bootstrap_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.bootstrap-assume-role-policy.json
}

resource  aws_iam_role_policy bootstrap_iam_role_policy {
    name   = "${var.aws_stack_name}-bootstrap-policy"
    role   = aws_iam_role.bootstrap_iam_role.name
    policy = data.aws_iam_policy_document.bootstrap_inline_policy.json
}

resource "aws_iam_instance_profile" "bootstrap_profile" {
  name = "${var.aws_stack_name}-bootstrap_profile"
  role = aws_iam_role.bootstrap_iam_role.name
}

####### Controller #######
module "mdw" {
    depends_on = [aws_internet_gateway.aws_internet_gateway, time_sleep.wait_5_seconds]
    source = "./modules/aws_mdw"
    resource_group = {
        security_group = aws_security_group.aws_cyperf_security_group.id,
        management_subnet = aws_subnet.aws_management_subnet.id
    }
    aws_stack_name = var.aws_stack_name
    aws_owner = var.aws_owner
    aws_auth_key = var.aws_auth_key
    aws_mdw_machine_type = var.aws_mdw_machine_type
}

####### Agents for awsfw #######
module "clientagents" {
    depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
    count = var.clientagents
    source = "./modules/aws_agent"
    resource_group = {
        aws_agent_security_group = aws_security_group.aws_agent_security_group.id,
        aws_ControllerManagementSubnet = aws_subnet.aws_management_subnet.id,
        aws_AgentTestSubnet = aws_subnet.aws_cli_test_subnet.id,
        instance_profile = aws_iam_instance_profile.instance_profile.name
    }
    tags = {
        project_tag = local.project_tag,
        aws_owner   = var.aws_owner,
        options_tag = local.options_tag,
        cli_agent_tag = local.cli_agent_tag
    }
    aws_stack_name = var.aws_stack_name
    aws_auth_key   = var.aws_auth_key
    aws_agent_machine_type = var.aws_agent_machine_type
    agent_role = "client-awsfw"
    agent_init_cli = local.agent_init_cli
}

module "serveragents" {
    depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
    count = var.serveragents
    source = "./modules/aws_agent"
    resource_group = {
        aws_agent_security_group = aws_security_group.aws_agent_security_group.id,
        aws_ControllerManagementSubnet = aws_subnet.aws_management_subnet.id,
        aws_AgentTestSubnet = aws_subnet.aws_srv_test_subnet.id,
        instance_profile = aws_iam_instance_profile.instance_profile.name
    }
    tags = {
        project_tag = local.project_tag,
        aws_owner   = var.aws_owner,
        options_tag = local.options_tag,
        srv_agent_tag = local.srv_agent_tag
    }
    aws_stack_name = var.aws_stack_name
    aws_auth_key   = var.aws_auth_key
    aws_agent_machine_type = var.aws_agent_machine_type
    agent_role = "server-awsfw"
    agent_init_cli = local.agent_init_cli
}

####### Agents for panfw #######
module "clientagents-pan" {
    depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
    count = var.clientagents_pan
    source = "./modules/aws_agent"
    resource_group = {
        aws_agent_security_group = aws_security_group.aws_agent_security_group.id,
        aws_ControllerManagementSubnet = aws_subnet.aws_management_subnet.id,
        aws_AgentTestSubnet = aws_subnet.aws_cli_test_subnet_pan.id,
        instance_profile = aws_iam_instance_profile.instance_profile.name
    }
    tags = {
        project_tag = local.project_tag,
        aws_owner   = var.aws_owner,
        options_tag = local.options_tag,
        cli_agent_tag = local.cli_agent_tag
    }
    aws_stack_name = var.aws_stack_name
    aws_auth_key   = var.aws_auth_key
    aws_agent_machine_type = var.aws_agent_machine_type
    agent_role = "client-panfw"
    agent_init_cli = local.agent_init_cli
}

module "serveragents-pan" {
    depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
    count = var.serveragents_pan
    source = "./modules/aws_agent"
    resource_group = {
        aws_agent_security_group = aws_security_group.aws_agent_security_group.id,
        aws_ControllerManagementSubnet = aws_subnet.aws_management_subnet.id,
        aws_AgentTestSubnet = aws_subnet.aws_srv_test_subnet_pan.id,
        instance_profile = aws_iam_instance_profile.instance_profile.name
    }
    tags = {
        project_tag = local.project_tag,
        aws_owner   = var.aws_owner,
        options_tag = local.options_tag,
        srv_agent_tag = local.srv_agent_tag
    }
    aws_stack_name = var.aws_stack_name
    aws_auth_key   = var.aws_auth_key
    aws_agent_machine_type = var.aws_agent_machine_type
    agent_role = "server-panfw"
    agent_init_cli = local.agent_init_cli
}

##### AWS NGFW ####
resource "aws_networkfirewall_firewall" "aws-ngfw" {
  name              = "${var.aws_stack_name}-aws-ngfw"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.aws-ngfw.arn
  vpc_id            = aws_vpc.aws_main_vpc.id
  subnet_mapping {
    subnet_id = aws_subnet.aws_firewall_subnet.id
  }
}

resource "aws_networkfirewall_firewall_policy" "aws-ngfw" {
  name = "aws-ngfw-firewall-policy"
  firewall_policy {
      stateful_rule_group_reference {
        resource_arn = aws_networkfirewall_rule_group.aws-ngfw.arn
    }
    stateless_fragment_default_actions = ["aws:pass"]    
    stateless_default_actions = ["aws:forward_to_sfe"]
  }
}

resource "aws_networkfirewall_rule_group" "aws-ngfw" {
  capacity = 100
  name     = "aws-ngfw-rule-group"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "172.16.4.0/24"
          destination_port = "ANY"
          direction        = "FORWARD"
          protocol         = "TCP"
          source           = "172.16.3.0/24"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }
    }
  }
  tags = {
    Tag1 = "cyperf-test-ngfw"
  }
}

####### PANFW #######
module "panfw" {
    depends_on = [aws_internet_gateway.aws_internet_gateway, time_sleep.wait_5_seconds]
    source = "./modules/aws_panfw"
    resource_group = {
        security_group = aws_security_group.aws_cyperf_security_group.id,
        management_subnet = aws_subnet.aws_management_subnet.id
        client_subnet = aws_subnet.aws_cli_test_subnet_pan.id
        server_subnet = aws_subnet.aws_srv_test_subnet_pan.id
        bootstrap_profile = aws_iam_instance_profile.bootstrap_profile.name
    }
    aws_stack_name = var.aws_stack_name
    aws_owner = var.aws_owner
    aws_auth_key = var.aws_auth_key
    aws_panfw_machine_type = var.aws_panfw_machine_type
}
##### Output ######
output "mdw_detail"{
  value = {
    "name" : module.mdw.mdw_detail.name,
    "public_ip" : module.mdw.mdw_detail.public_ip,
    "private_ip" : module.mdw.mdw_detail.private_ip
  }
}

output "client_agent_detail"{
  value = [for x in module.clientagents :   {
    "name" : x.agents_detail.name,
    "private_ip" : x.agents_detail.private_ip
  }]
}
  output "server_agent_detail"{
  value = [for x in module.serveragents :   {
    "name" : x.agents_detail.name,
    "private_ip" : x.agents_detail.private_ip
  }]
}


