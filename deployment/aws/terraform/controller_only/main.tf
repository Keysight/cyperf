provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.aws_region
}

locals{
    mdw_name = "${var.aws_stack_name}-mdw-${var.mdw_version}"
    main_cidr = "172.16.0.0/16"
    mgmt_cidr = "172.16.1.0/24"
}

data "aws_ami" "mdw_ami" {
    owners = ["001382923476"]
    most_recent = true
    filter {
      name   = "name"
      values = [var.mdw_version]
    }
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

resource "aws_security_group" "aws_cyperf_security_group" {
    name = "mdw-security-group"
    tags = {
        Name = "${var.aws_stack_name}-cyperf-security-group"
    }
    description = "MDW security group"
    vpc_id = aws_vpc.aws_main_vpc.id
}

resource "aws_security_group_rule" "aws_cyperf_ui_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
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

resource "aws_network_interface" "aws_mdw_interface" {
    tags = {
        Name = "${var.aws_stack_name}-mdw-mgmt-interface"
    }
    source_dest_check = true
    subnet_id = aws_subnet.aws_management_subnet.id
    security_groups = [ aws_security_group.aws_cyperf_security_group.id ]
}

resource "aws_eip" "mdw_public_ip" {
  instance = aws_instance.aws_mdw.id
  vpc = true
  associate_with_private_ip = aws_instance.aws_mdw.private_ip
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

    credit_specification {
        cpu_credits = "unlimited"
    }

    network_interface {
        network_interface_id = aws_network_interface.aws_mdw_interface.id
        device_index         = 0
    }

    key_name = var.aws_auth_key
}


output "mdw_detail" {
  value = {
    "name": local.mdw_name,
    "private_ip" : aws_instance.aws_mdw.private_ip,
    "public_ip"  : aws_eip.mdw_public_ip.public_ip
  }
}
