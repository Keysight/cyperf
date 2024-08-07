provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

locals {
  main_cidr          = "172.16.0.0/16"
  mgmt_cidr_ipv4     = "172.16.1.0/24"
  test_cidr          = "172.16.2.0/24"
  mdw_name           = "${var.aws_stack_name}-mdw-${var.mdw_version}"
  client_name        = "${var.aws_stack_name}-client-${var.agent_version}"
  server_name        = "${var.aws_stack_name}-server-${var.agent_version}"
  mdw_ip_address     = var.stack_type == "ipv4" ? "${aws_instance.aws_mdw.private_ip}" : "${aws_instance.aws_mdw.ipv6_addresses[0]}"
  agent_init_cli     = <<-EOF
                #! /bin/bash
                sudo sudo chmod 777 /var/log/
                sudo sh /opt/keysight/tiger/active/bin/Appsec_init ${local.mdw_ip_address} --username "${var.controller_username}" --password "${var.controller_password}">> /var/log/Appsec_init.log
    EOF
  firewall_cidr_ipv4 = concat(var.aws_allowed_cidr_ipv4, [local.main_cidr], [local.test_cidr])
  firewall_cidr_ipv6 = var.aws_allowed_cidr_ipv6
}

resource "aws_vpc" "aws_main_vpc" {
  tags = {
    Name = "${var.aws_stack_name}-main-vpc"
  }
  enable_dns_hostnames             = true
  enable_dns_support               = true
  cidr_block                       = local.main_cidr
  assign_generated_ipv6_cidr_block = true
}

resource "aws_subnet" "aws_management_subnet" {
  vpc_id            = aws_vpc.aws_main_vpc.id
  cidr_block        = local.mgmt_cidr_ipv4
  ipv6_cidr_block   = aws_vpc.aws_main_vpc.ipv6_cidr_block
  availability_zone = var.availability_zone
  tags = {
    Name = "${var.aws_stack_name}-management-subnet"
  }
}

resource "aws_subnet" "aws_test_subnet" {
  vpc_id            = aws_vpc.aws_main_vpc.id
  availability_zone = var.availability_zone
  cidr_block        = local.test_cidr
  tags = {
    Name = "${var.aws_stack_name}-test-subnet"
  }
}

resource "aws_security_group" "aws_agent_security_group" {
  name = "agent-security-group"
  tags = {
    Name = "${var.aws_stack_name}-agent-security-group"
  }
  description = "Agent security group"
  vpc_id      = aws_vpc.aws_main_vpc.id
}

resource "aws_security_group" "aws_cyperf_security_group" {
  name = "mdw-security-group"
  tags = {
    Name = "${var.aws_stack_name}-cyperf-security-group"
  }
  description = "MDW security group"
  vpc_id      = aws_vpc.aws_main_vpc.id
}

resource "aws_security_group_rule" "aws_cyperf_agent_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.firewall_cidr_ipv4
  ipv6_cidr_blocks  = local.firewall_cidr_ipv6
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
  cidr_blocks       = local.firewall_cidr_ipv4
  ipv6_cidr_blocks  = local.firewall_cidr_ipv6
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

resource "aws_vpc_dhcp_options" "aws_main_vpc_dhcp_options" {
  tags = {
    Name = "${var.aws_stack_name}-dhcp-option"
  }
  domain_name_servers = ["8.8.8.8",
    "8.8.4.4",
  "AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.aws_main_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.aws_main_vpc_dhcp_options.id
}

resource "aws_route_table" "aws_private_rt" {
  vpc_id = aws_vpc.aws_main_vpc.id
  tags = {
    Name = "${var.aws_stack_name}-private-rt"
  }
}

resource "aws_route_table_association" "aws_test_rt_association" {
  subnet_id      = aws_subnet.aws_test_subnet.id
  route_table_id = aws_route_table.aws_private_rt.id
}

resource "aws_route_table" "aws_public_rt" {
  vpc_id = aws_vpc.aws_main_vpc.id
  tags = {
    Name = "${var.aws_stack_name}-public-rt"
  }
}

resource "aws_route_table_association" "aws_mgmt_rt_association" {
  subnet_id      = aws_subnet.aws_management_subnet.id
  route_table_id = aws_route_table.aws_public_rt.id
}

resource "aws_internet_gateway" "aws_internet_gateway" {
  tags = {
    Name = "${var.aws_stack_name}-internet-gateway"
  }
  vpc_id = aws_vpc.aws_main_vpc.id
}

resource "aws_route" "aws_route_to_internet_ipv4" {
  count = var.stack_type == "ipv6" ? 0 : 1
  depends_on = [
    aws_route_table_association.aws_mgmt_rt_association
  ]
  route_table_id         = aws_route_table.aws_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.aws_internet_gateway.id
}
resource "aws_route" "aws_route_to_internet_ipv6" {
  count = var.stack_type == "ipv4" ? 0 : 1
  depends_on = [
    aws_route_table_association.aws_mgmt_rt_association
  ]
  route_table_id              = aws_route_table.aws_public_rt.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.aws_internet_gateway.id
}

resource "aws_network_interface" "aws_mdw_interface" {
  tags = {
    Name = "${var.aws_stack_name}-mdw-mgmt-interface"
  }
  source_dest_check = true
  subnet_id         = aws_subnet.aws_management_subnet.id
  security_groups   = [aws_security_group.aws_cyperf_security_group.id]
  ipv6_addresses    = var.stack_type == "ipv4" ? [] : [cidrhost(aws_subnet.aws_management_subnet.ipv6_cidr_block, 16)]
}

resource "aws_network_interface" "aws_client_mgmt_interface" {
  tags = {
    Name = "${var.aws_stack_name}-client-mgmt-interface"
  }
  security_groups   = [aws_security_group.aws_agent_security_group.id]
  source_dest_check = true
  subnet_id         = aws_subnet.aws_management_subnet.id
  ipv6_addresses    = var.stack_type == "ipv4" ? [] : [cidrhost(aws_subnet.aws_management_subnet.ipv6_cidr_block, 32)]
}

resource "aws_network_interface" "aws_server_mgmt_interface" {
  tags = {
    Name = "${var.aws_stack_name}-server-mgmt-interface"
  }
  security_groups   = [aws_security_group.aws_agent_security_group.id]
  source_dest_check = true
  subnet_id         = aws_subnet.aws_management_subnet.id
  ipv6_addresses    = var.stack_type == "ipv4" ? [] : [cidrhost(aws_subnet.aws_management_subnet.ipv6_cidr_block, 48)]
}

resource "aws_network_interface" "aws_client_test_interface" {
  tags = {
    Name = "${var.aws_stack_name}-client-test-interface"
  }
  source_dest_check = true
  subnet_id         = aws_subnet.aws_test_subnet.id
  security_groups   = [aws_security_group.aws_agent_security_group.id]
}

resource "aws_network_interface" "aws_server_test_interface" {
  tags = {
    Name = "${var.aws_stack_name}-server-test-interface"
  }
  source_dest_check = true
  subnet_id         = aws_subnet.aws_test_subnet.id
  security_groups   = [aws_security_group.aws_agent_security_group.id]
}

resource "aws_eip" "mdw_public_ip" {
  count                     = var.stack_type == "ipv6" ? 0 : 1
  instance                  = aws_instance.aws_mdw.id
  vpc                       = true
  associate_with_private_ip = aws_instance.aws_mdw.private_ip
  depends_on = [
    aws_internet_gateway.aws_internet_gateway
  ]
}

resource "aws_eip" "server_public_ip" {
  count                     = var.stack_type == "ipv6" ? 0 : 1
  network_interface         = aws_network_interface.aws_server_mgmt_interface.id
  vpc                       = true
  associate_with_private_ip = aws_instance.aws_server_agent.private_ip
  depends_on = [
    aws_internet_gateway.aws_internet_gateway
  ]
}

resource "aws_eip" "client_public_ip" {
  count                     = var.stack_type == "ipv6" ? 0 : 1
  network_interface         = aws_network_interface.aws_client_mgmt_interface.id
  vpc                       = true
  associate_with_private_ip = aws_instance.aws_client_agent.private_ip
  depends_on = [
    aws_internet_gateway.aws_internet_gateway
  ]
}

resource "aws_instance" "aws_mdw" {
  tags = {
    Name = local.mdw_name
  }


  ami           = "resolve:ssm:/aws/service/marketplace/prod-svag4bs7dtcbu/${var.cyperf_release}"
  instance_type = var.aws_mdw_machine_type

  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_size           = "100"
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.aws_mdw_interface.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  key_name = var.aws_auth_key
}

resource "aws_instance" "aws_client_agent" {
  tags = {
    Name = local.client_name
  }
  ami           = "resolve:ssm:/aws/service/marketplace/prod-tild73tpfkqko/${var.cyperf_release}"
  instance_type = var.aws_agent_machine_type

  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_size           = "16"
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.aws_client_mgmt_interface.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.aws_client_test_interface.id
    device_index         = 1
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
  user_data = local.agent_init_cli

  key_name = var.aws_auth_key
}

resource "aws_instance" "aws_server_agent" {
  tags = {
    Name = local.server_name
  }

  ami           = "resolve:ssm:/aws/service/marketplace/prod-tild73tpfkqko/${var.cyperf_release}"
  instance_type = var.aws_agent_machine_type

  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_size           = "16"
    delete_on_termination = true
  }

  network_interface {
    network_interface_id = aws_network_interface.aws_server_mgmt_interface.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.aws_server_test_interface.id
    device_index         = 1
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
  user_data = local.agent_init_cli

  key_name = var.aws_auth_key

}

output "mdw_detail" {
  value = {
    "name" : local.mdw_name,
    "private_ip" : aws_instance.aws_mdw.private_ip,
    "public_ip" : var.stack_type == "ipv6" ? aws_instance.aws_mdw.ipv6_addresses[0] : aws_eip.mdw_public_ip[0].public_ip,
    "type" : "aws"
  }
}

output "agents_detail" {
  value = [
    {
      "name" : local.client_name,
      "management_private_ip" : aws_instance.aws_client_agent.private_ip,
      "management_public_ip" : var.stack_type == "ipv6" ? aws_instance.aws_client_agent.ipv6_addresses[0] : aws_eip.client_public_ip[0].public_ip,
      "type" : "aws"
    },
    {
      "name" : local.server_name,
      "management_private_ip" : aws_instance.aws_server_agent.private_ip,
      "management_public_ip" : var.stack_type == "ipv6" ? aws_instance.aws_server_agent.ipv6_addresses[0] : aws_eip.server_public_ip[0].public_ip,
      "type" : "aws"
    }
  ]
}