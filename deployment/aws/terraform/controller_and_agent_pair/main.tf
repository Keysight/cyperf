provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.aws_region
}

locals{
    main_cidr = "172.16.0.0/16"
    mgmt_cidr = "172.16.1.0/24"
    test_cidr = "172.16.2.0/24"
    mdw_name = "${var.aws_stack_name}-mdw-${var.mdw_version}"
    client_name = "${var.aws_stack_name}-client-${var.agent_version}"
    server_name = "${var.aws_stack_name}-server-${var.agent_version}"
    agent_init_cli = <<-EOF
                #! /bin/bash
                sudo sudo chmod 777 /var/log/
                sudo sh /opt/keysight/tiger/active/bin/Appsec_init ${aws_instance.aws_mdw.private_ip} >> /var/log/Appsec_init.log
    EOF
    firewall_cidr = concat(var.aws_allowed_cidr,[local.main_cidr],[local.test_cidr])
}

resource "aws_vpc" "aws_main_vpc" {
    tags = {
        Name = "${var.aws_stack_name}-main-vpc"
    }
    enable_dns_hostnames = true
    enable_dns_support = true
    cidr_block = local.main_cidr
}

resource "aws_subnet" "aws_management_subnet" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    cidr_block = local.mgmt_cidr
    availability_zone = var.availability_zone
    tags = {
        Name = "${var.aws_stack_name}-management-subnet"
    }
}

resource "aws_subnet" "aws_test_subnet" {
    vpc_id     = aws_vpc.aws_main_vpc.id
    availability_zone = var.availability_zone
    cidr_block = local.test_cidr
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
    vpc_id = aws_vpc.aws_main_vpc.id
}

resource "aws_security_group" "aws_cyperf_security_group" {
    name = "mdw-security-group"
    tags = {
        Name = "${var.aws_stack_name}-cyperf-security-group"
    }
    description = "MDW security group"
    vpc_id = aws_vpc.aws_main_vpc.id
}

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

resource "aws_vpc_dhcp_options" "aws_main_vpc_dhcp_options" {
    tags = {
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

resource "aws_route" "aws_route_to_internet" {
    depends_on = [
      aws_route_table_association.aws_mgmt_rt_association
    ]
    route_table_id            = aws_route_table.aws_public_rt.id
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_internet_gateway.id
}

resource "aws_network_interface" "aws_mdw_interface" {
    tags = {
        Name = "${var.aws_stack_name}-mdw-mgmt-interface"
    }
    source_dest_check = true
    subnet_id = aws_subnet.aws_management_subnet.id
    security_groups = [ aws_security_group.aws_cyperf_security_group.id ]
}

resource "aws_network_interface" "aws_client_mgmt_interface" {
    tags = {
        Name = "${var.aws_stack_name}-client-mgmt-interface"
    }
    security_groups = [ aws_security_group.aws_agent_security_group.id ]
    source_dest_check = true
    subnet_id = aws_subnet.aws_management_subnet.id
}

resource "aws_network_interface" "aws_server_mgmt_interface" {
    tags = {
        Name = "${var.aws_stack_name}-server-mgmt-interface"
    }
    security_groups = [ aws_security_group.aws_agent_security_group.id ]
    source_dest_check = true
    subnet_id = aws_subnet.aws_management_subnet.id
}

resource "aws_network_interface" "aws_client_test_interface" {
    tags = {
        Name = "${var.aws_stack_name}-client-test-interface"
    }
    source_dest_check = true
    subnet_id = aws_subnet.aws_test_subnet.id
    security_groups = [ aws_security_group.aws_agent_security_group.id ]
}

resource "aws_network_interface" "aws_server_test_interface" {
    tags = {
        Name = "${var.aws_stack_name}-server-test-interface"
    }
    source_dest_check = true
    subnet_id = aws_subnet.aws_test_subnet.id
    security_groups = [ aws_security_group.aws_agent_security_group.id ]
}

data "aws_ami" "mdw_ami" {
    owners = ["aws-marketplace"]
    most_recent = true
    filter {
      name   = "product-code"
      values = [var.mdw_product_code]
    }
}

data "aws_ami" "agent_ami" {
    owners = ["aws-marketplace"]
    most_recent = true
    filter {
      name   = "product-code"
      values = [var.agent_product_code]
    }
}

resource "aws_eip" "mdw_public_ip" {
  instance = aws_instance.aws_mdw.id
  vpc = true
  associate_with_private_ip = aws_instance.aws_mdw.private_ip
  depends_on = [
    aws_internet_gateway.aws_internet_gateway
  ]
}

resource "aws_eip" "server_public_ip" {
  network_interface = aws_network_interface.aws_server_mgmt_interface.id
  vpc = true
  associate_with_private_ip = aws_instance.aws_server_agent.private_ip
  depends_on = [
    aws_internet_gateway.aws_internet_gateway
  ]
}

resource "aws_eip" "client_public_ip" {
  network_interface = aws_network_interface.aws_client_mgmt_interface.id
  vpc = true
  associate_with_private_ip = aws_instance.aws_client_agent.private_ip
  depends_on = [
    aws_internet_gateway.aws_internet_gateway
  ]
}

resource "aws_instance" "aws_mdw" {
    tags = {
        Name = local.mdw_name
    }


    ami           = data.aws_ami.mdw_ami.image_id 
    instance_type = var.aws_mdw_machine_type

    ebs_block_device {
        device_name = "/dev/sda1"
        volume_size = "100"
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
    ami           = data.aws_ami.agent_ami.image_id 
    instance_type = var.aws_agent_machine_type

    ebs_block_device {
        device_name = "/dev/sda1"
        volume_size = "16"
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

    ami           = data.aws_ami.agent_ami.image_id 
    instance_type = var.aws_agent_machine_type

    ebs_block_device {
        device_name = "/dev/sda1"
        volume_size = "16"
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
    "name": local.mdw_name,
    "private_ip" : aws_instance.aws_mdw.private_ip,
    "public_ip"  : aws_eip.mdw_public_ip.public_ip
  }
}

output "agents_detail"{
  value = [
    {
      "name": local.client_name,
      "management_private_ip": aws_instance.aws_client_agent.private_ip,
      "management_public_ip": aws_eip.client_public_ip.public_ip
    },
    {
      "name": local.server_name,
      "management_private_ip": aws_instance.aws_server_agent.private_ip,
      "management_public_ip": aws_eip.server_public_ip.public_ip
    }
  ]
}