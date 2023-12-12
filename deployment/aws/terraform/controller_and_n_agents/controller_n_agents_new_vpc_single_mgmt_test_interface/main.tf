provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.aws_region
}

locals{
    main_cidr = "172.21.0.0/16"
    mgmt_cidr = "172.21.1.0/24"
    firewall_cidr = concat(var.aws_allowed_cidr,[local.main_cidr])
    options_tag             = "MANUAL"
    project_tag             = "CyPerf"
    agent_init_cli = <<-EOF
                #! /bin/bash
                 sudo rm -rf /etc/portmanager/node_id.txt
                 cyperfagent feature allow_mgmt_iface_for_test enable
                 sudo cyperfagent controller set ${module.mdw.mdw_detail.private_ip} --skip-restart
                 sudo cyperfagent configuration reload
    EOF
}

resource "aws_vpc" "aws_main_vpc" {
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-main-vpc"
    }
    enable_dns_hostnames = true
    enable_dns_support = true
    cidr_block = local.main_cidr
}

####### Subnets #######
resource "aws_subnet" "aws_management_subnet" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    cidr_block = local.mgmt_cidr
    availability_zone = var.availability_zone
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-management-subnet"
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
resource "aws_route_table_association" "aws_mgmt_rt_association" {
    subnet_id      = aws_subnet.aws_management_subnet.id
    route_table_id = aws_route_table.aws_public_rt.id
}
resource "aws_internet_gateway" "aws_internet_gateway" {
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-internet-gateway"
    }
    vpc_id = aws_vpc.aws_main_vpc.id  
}
resource "aws_route" "aws_route_to_internet" {
    depends_on = [
      aws_route_table_association.aws_mgmt_rt_association
    ]
    route_table_id            = aws_route_table.aws_public_rt.id
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_internet_gateway.id
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
  inline_policy {
    name   = "${var.aws_stack_name}-policy"
    policy = data.aws_iam_policy_document.inline_policy.json
  }
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

####### Controller #######
module "mdw" {
    depends_on = [aws_internet_gateway.aws_internet_gateway, time_sleep.wait_5_seconds]
    source = "../modules/aws_mdw"
    resource_group = {
        security_group = aws_security_group.aws_cyperf_security_group.id,
        management_subnet = aws_subnet.aws_management_subnet.id
    }
    aws_stack_name = var.aws_stack_name
    aws_owner = var.aws_owner
    aws_auth_key = var.aws_auth_key
    aws_mdw_machine_type = var.aws_mdw_machine_type
}

####### Agents #######
module "agents" {
    depends_on = [module.mdw.mdw_detail, time_sleep.wait_5_seconds]
    count = var.agents
    source = "../modules/aws_agent"
    resource_group = {
        aws_agent_security_group = aws_security_group.aws_agent_security_group.id,
        aws_ControllerManagementSubnet = aws_subnet.aws_management_subnet.id,
        instance_profile = aws_iam_instance_profile.instance_profile.name
    }
    tags = {
        project_tag = local.project_tag,
        aws_owner   = var.aws_owner,
        options_tag = local.options_tag
    }
    aws_stack_name = var.aws_stack_name
    aws_auth_key   = var.aws_auth_key
    aws_agent_machine_type = var.aws_agent_machine_type
    agent_role = "agents-role"
    agent_init_cli = local.agent_init_cli
}

##### Output ######
output "mdw_detail"{
  value = {
    "name" : module.mdw.mdw_detail.name,
    "public_ip" : module.mdw.mdw_detail.public_ip,
    "private_ip" : module.mdw.mdw_detail.private_ip
  }
}

output "agent_detail"{
  value = [for x in module.agents :   {
    "name" : x.agents_detail.name,
    "private_ip" : x.agents_detail.private_ip
  }]
}


