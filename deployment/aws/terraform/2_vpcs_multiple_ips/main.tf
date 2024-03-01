provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.aws_region
}

locals{
    main_cidr = "172.16.0.0/16"
    main_mgmt_subnet = "172.16.1.0/24"
    main_test_subnet = "172.16.2.0/24"
    secondary_cidr = "172.17.0.0/16"
    secondary_mgmt_subnet = "172.17.1.0/24"
    secondary_test_subnet = "172.17.2.0/24"
    mdw_name = "${var.aws_stack_name}-mdw-v${var.mdw_version}"
    main_agent_name = "${var.aws_stack_name}-main-agent-${var.agent_version}"
    secondary_agent_name = "${var.aws_stack_name}-secondary-agent-${var.agent_version}"
    broker_name = "${var.aws_stack_name}-${var.broker_version}"
    main_agent_init_cli = <<-EOF
                #! /bin/bash
                sudo sudo chmod 777 /var/log/
                sudo sh /opt/keysight/tiger/active/bin/Appsec_init ${aws_instance.mdw.private_ip} --username "${var.controller_username}" --password "${var.controller_password}">> /var/log/Appsec_init.log
    EOF
    secondary_agent_init_cli = <<-EOF
                #! /bin/bash
                sudo sudo chmod 777 /var/log/
                sudo sh /opt/keysight/tiger/active/bin/Appsec_init ${aws_instance.broker.private_ip} --username "${var.broker_username}" --password "${var.broker_password}">> /var/log/Appsec_init.log
    EOF
    firewall_cidr = concat(var.aws_allowed_cidr,[local.main_cidr,local.secondary_cidr])
}

resource "aws_vpc" "main_vpc" {
    tags = {
        Name = "${var.aws_stack_name}-main-vpc"
    }
    enable_dns_hostnames = true
    enable_dns_support = true
    cidr_block = local.main_cidr
}

resource "aws_subnet" "main_management_subnet" {
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = local.main_mgmt_subnet
    availability_zone = var.availability_zone
    tags = {
        Name = "${var.aws_stack_name}-management-subnet"
    }
}

resource "aws_subnet" "main_test_subnet" {
    vpc_id     = aws_vpc.main_vpc.id
    availability_zone = var.availability_zone
    cidr_block = local.main_test_subnet
    tags = {
        Name = "${var.aws_stack_name}-test-subnet"
    }
}

resource "aws_security_group" "main_agent_security_group" {
    name = "main-agent-sg"
    tags = {
        Name = "${var.aws_stack_name}-main-agent-sg"
    }
    description = "Agent security group"
    vpc_id = aws_vpc.main_vpc.id
}

resource "aws_security_group" "main_controller_security_group" {
    name = "contoller-security-group"
    tags = {
        Name = "${var.aws_stack_name}-cyperf-sg"
    }
    description = "MDW security group"
    vpc_id = aws_vpc.main_vpc.id
}

resource "aws_security_group_rule" "main_agent_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.firewall_cidr
  ipv6_cidr_blocks  = ["::/128"]
  security_group_id = aws_security_group.main_agent_security_group.id
}

resource "aws_security_group_rule" "main_agent_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.firewall_cidr
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.main_agent_security_group.id
}

resource "aws_security_group_rule" "contoller_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.firewall_cidr
  ipv6_cidr_blocks  = ["::/128"]
  security_group_id = aws_security_group.main_controller_security_group.id
}

resource "aws_security_group_rule" "controller_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.firewall_cidr
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.main_controller_security_group.id
}

resource "aws_vpc_dhcp_options" "main_vpc_dhcp_options" {
    tags = {
        Name = "${var.aws_stack_name}-dhcp-option"
    }
    domain_name_servers  = ["8.8.8.8",
                            "8.8.4.4",
                            "AmazonProvidedDNS" ]
}

resource "aws_vpc_dhcp_options_association" "main_dns_resolver" {
    vpc_id          = aws_vpc.main_vpc.id
    dhcp_options_id = aws_vpc_dhcp_options.main_vpc_dhcp_options.id
}

resource "aws_route_table" "main_private_rt" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "${var.aws_stack_name}-main-private-rt"
    }
}

resource "aws_route_table_association" "main_test_rt_association" {
    subnet_id      = aws_subnet.main_test_subnet.id
    route_table_id = aws_route_table.main_private_rt.id
}

resource "aws_route" "main-vpc-tgw-route" {
    depends_on = [
      aws_route_table_association.main_test_rt_association
    ]
    route_table_id            = aws_route_table.main_private_rt.id
    destination_cidr_block    = local.secondary_cidr
    transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
}

resource "aws_route_table" "main_public_rt" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "${var.aws_stack_name}-main-public-rt"
    }
}

resource "aws_route_table_association" "main_mgmt_rt_association" {
    subnet_id      = aws_subnet.main_management_subnet.id
    route_table_id = aws_route_table.main_public_rt.id
}

resource "aws_internet_gateway" "main_internet_gateway" {
    tags = {
        Name = "${var.aws_stack_name}-internet-gateway"
    }
    vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route" "main_route_to_internet" {
    depends_on = [
      aws_route_table_association.main_mgmt_rt_association
    ]
    route_table_id            = aws_route_table.main_public_rt.id
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id =  aws_internet_gateway.main_internet_gateway.id
}

resource "aws_network_interface" "mdw_interface" {
    tags = {
        Name = "${var.aws_stack_name}-mdw-mgmt-interface"
    }
    source_dest_check = true
    subnet_id = aws_subnet.main_management_subnet.id
    security_groups = [ aws_security_group.main_controller_security_group.id ]
}

resource "aws_network_interface" "main_agent_mgmt_interface" {
    count = var.agent_number
    tags = {
        Name = "${var.aws_stack_name}-main-agent-mgmt-${count.index}"
    }
    source_dest_check = true
    subnet_id = aws_subnet.main_management_subnet.id
    security_groups = [ aws_security_group.main_agent_security_group.id ]
}

resource "aws_network_interface" "main_agent_test_interface" {
    count = var.agent_number
    tags = {
        Name = "${var.aws_stack_name}-main-agent-test-${count.index}"
    }
    source_dest_check = true
    subnet_id = aws_subnet.main_test_subnet.id
    private_ips = [
        //0 - 3 and 255 are ips reserver by aws for mask /24
        // you may need to change 4+var.ip_number*count.index+i to 4+var.ip_number*count.index+i-var.ip_number to start from 5
      for i in range(var.ip_number) : "172.16.2.${4+var.ip_number*count.index+i}"
    ]
    security_groups = [ aws_security_group.main_agent_security_group.id ]
}

resource "aws_eip" "mdw_public_ip" {
  instance = aws_instance.mdw.id
  vpc = true
  associate_with_private_ip = aws_instance.mdw.private_ip
  depends_on = [
    aws_internet_gateway.main_internet_gateway
  ]
}

resource "aws_eip" "main_agent_public_ip" {
  count = var.agent_number
  network_interface = aws_network_interface.main_agent_mgmt_interface[count.index].id
  vpc = true
  associate_with_private_ip = aws_instance.main_agent[count.index].private_ip
  depends_on = [
    aws_internet_gateway.main_internet_gateway
  ]
}

resource "aws_instance" "mdw" {
    tags = {
        Name = local.mdw_name
    }


    ami           = "resolve:ssm:/aws/service/marketplace/prod-svag4bs7dtcbu/${var.cyperf_release}"
    instance_type = var.aws_mdw_machine_type

    ebs_block_device {
        device_name = "/dev/sda1"
        volume_size = "100"
        delete_on_termination = true
    }

    network_interface {
        network_interface_id = aws_network_interface.mdw_interface.id
        device_index         = 0
    }

    credit_specification {
        cpu_credits = "unlimited"
    }

    key_name = var.aws_auth_key
}

resource "aws_instance" "main_agent" {
    count = var.agent_number
    tags = {
        Name = "${local.main_agent_name}-${count.index}"
    }
    ami           = "resolve:ssm:/aws/service/marketplace/prod-tild73tpfkqko/${var.cyperf_release}"
    instance_type = var.aws_agent_machine_type

    ebs_block_device {
        device_name = "/dev/sda1"
        volume_size = "16"
        delete_on_termination = true
    }

    network_interface {
        network_interface_id = aws_network_interface.main_agent_mgmt_interface[count.index].id
        device_index         = 0
    }

    network_interface {
        network_interface_id = aws_network_interface.main_agent_test_interface[count.index].id
        device_index         = 1
    }


    credit_specification {
        cpu_credits = "unlimited"
    }
    user_data = local.main_agent_init_cli

    key_name = var.aws_auth_key
}

resource "aws_vpc" "secondary_vpc" {
    tags = {
        Name = "${var.aws_stack_name}-secondary-vpc"
    }
    enable_dns_hostnames = true
    enable_dns_support = true
    cidr_block = local.secondary_cidr
}

resource "aws_subnet" "secondary_management_subnet" {
    vpc_id     = aws_vpc.secondary_vpc.id
    cidr_block = local.secondary_mgmt_subnet
    availability_zone = var.availability_zone
    tags = {
        Name = "${var.aws_stack_name}-secondary-management-subnet"
    }
}

resource "aws_subnet" "secondary_test_subnet" {
    vpc_id     = aws_vpc.secondary_vpc.id
    availability_zone = var.availability_zone
    cidr_block = local.secondary_test_subnet
    tags = {
        Name = "${var.aws_stack_name}-secondary-test-subnet"
    }
}

resource "aws_security_group" "secondary_agent_security_group" {
    name = "main-agent-sg"
    tags = {
        Name = "${var.aws_stack_name}-secondary-agent-sg"
    }
    description = "Agent security group"
    vpc_id = aws_vpc.secondary_vpc.id
}

resource "aws_security_group" "secondary_controller_proxy_security_group" {
    name = "contoller-proxy-security-group"
    tags = {
        Name = "${var.aws_stack_name}-cyperf-sg"
    }
    description = "MDW security group"
    vpc_id = aws_vpc.secondary_vpc.id
}

resource "aws_security_group_rule" "secondary_agent_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.firewall_cidr
  ipv6_cidr_blocks  = ["::/128"]
  security_group_id = aws_security_group.secondary_agent_security_group.id
}

resource "aws_security_group_rule" "secondary_agent_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.firewall_cidr
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.secondary_agent_security_group.id
}

resource "aws_security_group_rule" "contoller_proxy_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.firewall_cidr
  ipv6_cidr_blocks  = ["::/128"]
  security_group_id = aws_security_group.secondary_controller_proxy_security_group.id
}

resource "aws_security_group_rule" "contoller_proxy_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.firewall_cidr
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.secondary_controller_proxy_security_group.id
}


resource "aws_vpc_dhcp_options" "secondary_vpc_dhcp_options" {
    tags = {
        Name = "${var.aws_stack_name}-dhcp-option"
    }
    domain_name_servers  = ["8.8.8.8",
                            "8.8.4.4",
                            "AmazonProvidedDNS" ]
}

resource "aws_vpc_dhcp_options_association" "secondary_dns_resolver" {
    vpc_id          = aws_vpc.secondary_vpc.id
    dhcp_options_id = aws_vpc_dhcp_options.secondary_vpc_dhcp_options.id
}

resource "aws_route_table" "secondary_private_rt" {
    vpc_id = aws_vpc.secondary_vpc.id
    tags = {
        Name = "${var.aws_stack_name}-secondary-private-rt"
    }
}

resource "aws_route_table_association" "secondary_test_rt_association" {
    subnet_id      = aws_subnet.secondary_test_subnet.id
    route_table_id = aws_route_table.secondary_private_rt.id
}

resource "aws_route" "secondary-vpc-tgw-route" {
    depends_on = [
      aws_route_table_association.secondary_test_rt_association
    ]
    route_table_id            = aws_route_table.secondary_private_rt.id
    destination_cidr_block    = local.main_cidr
    transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
}

resource "aws_route_table" "secondary_public_rt" {
    vpc_id = aws_vpc.secondary_vpc.id
    tags = {
        Name = "${var.aws_stack_name}-secondary-public-rt"
    }
}

resource "aws_route_table_association" "secondary_mgmt_rt_association" {
    subnet_id      = aws_subnet.secondary_management_subnet.id
    route_table_id = aws_route_table.secondary_public_rt.id
}

resource "aws_internet_gateway" "secondary_internet_gateway" {
    tags = {
        Name = "${var.aws_stack_name}-secondary-internet-gateway"
    }
    vpc_id = aws_vpc.secondary_vpc.id
}

resource "aws_route" "secondary_route_to_internet" {
    depends_on = [
      aws_route_table_association.secondary_mgmt_rt_association
    ]
    route_table_id            = aws_route_table.secondary_public_rt.id
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary_internet_gateway.id
}

resource "aws_network_interface" "broker_interface" {
    tags = {
        Name = "${var.aws_stack_name}-broker-mgmt-interface"
    }
    source_dest_check = true
    subnet_id = aws_subnet.secondary_management_subnet.id
    security_groups = [ aws_security_group.secondary_controller_proxy_security_group.id ]
}

resource "aws_network_interface" "secondary_agent_mgmt_interface" {
    count = var.agent_number
    tags = {
        Name = "${var.aws_stack_name}-secondary-agent-mgmt-${count.index}"
    }
    source_dest_check = true
    subnet_id = aws_subnet.secondary_management_subnet.id
    security_groups = [ aws_security_group.secondary_agent_security_group.id ]
}

resource "aws_network_interface" "secondary_agent_test_interface" {
    count = var.agent_number
    tags = {
        Name = "${var.aws_stack_name}-secondary-agent-test-${count.index}"
    }
    source_dest_check = true
    subnet_id = aws_subnet.secondary_test_subnet.id
    private_ips = [
      for i in range(var.ip_number) : "172.17.2.${4+var.ip_number*count.index+i}"
    ]
    security_groups = [ aws_security_group.secondary_agent_security_group.id ]
}

resource "aws_eip" "broker_public_ip" {
  instance = aws_instance.broker.id
  vpc = true
  associate_with_private_ip = aws_instance.broker.private_ip
  depends_on = [
    aws_internet_gateway.secondary_internet_gateway
  ]
}

resource "aws_eip" "secondary_agent_public_ip" {
  count = var.agent_number
  network_interface = aws_network_interface.secondary_agent_mgmt_interface[count.index].id
  vpc = true
  associate_with_private_ip = aws_instance.secondary_agent[count.index].private_ip
  depends_on = [
    aws_internet_gateway.secondary_internet_gateway
  ]
}

resource "aws_instance" "broker" {
    tags = {
        Name = local.broker_name
    }


    ami           = "resolve:ssm:/aws/service/marketplace/prod-xopwud6rtquaw/${var.cyperf_release}"
    instance_type = var.aws_broker_machine_type

    ebs_block_device {
        device_name = "/dev/sda1"
        volume_size = "100"
        delete_on_termination = true
    }

    network_interface {
        network_interface_id = aws_network_interface.broker_interface.id
        device_index         = 0
    }

    credit_specification {
        cpu_credits = "unlimited"
    }

    key_name = var.aws_auth_key
}

resource "aws_instance" "secondary_agent" {
    count = var.agent_number
    tags = {
        Name = "${local.secondary_agent_name}-${count.index}"
    }
    ami           = "resolve:ssm:/aws/service/marketplace/prod-tild73tpfkqko/${var.cyperf_release}"
    instance_type = var.aws_agent_machine_type

    ebs_block_device {
        device_name = "/dev/sda1"
        volume_size = "16"
        delete_on_termination = true
    }

    network_interface {
        network_interface_id = aws_network_interface.secondary_agent_mgmt_interface[count.index].id
        device_index         = 0
    }

    network_interface {
        network_interface_id = aws_network_interface.secondary_agent_test_interface[count.index].id
        device_index         = 1
    }


    credit_specification {
        cpu_credits = "unlimited"
    }
    user_data = local.secondary_agent_init_cli

    key_name = var.aws_auth_key
}

resource "aws_ec2_transit_gateway" "transit_gateway" {
    tags = {
        Name = "${var.aws_stack_name}-TGW"
    }
    description = "Gateway between main VPC and secondary VPC"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "main_attach" {
  tags = {
        Name = "${var.aws_stack_name}-main-attach"
  }
  subnet_ids         = [aws_subnet.main_test_subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = aws_vpc.main_vpc.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "secondary_attach" {
  tags = {
        Name = "${var.aws_stack_name}-secondary-attach"
  }
  subnet_ids         = [aws_subnet.secondary_test_subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = aws_vpc.secondary_vpc.id
}

output "mdw_detail" {
  value = {
    "name": local.mdw_name,
    "private_ip" : aws_instance.mdw.private_ip,
    "public_ip"  : aws_eip.mdw_public_ip.public_ip
  }
}

output "broker_public_ip" {
  value = aws_eip.broker_public_ip.public_ip
}

