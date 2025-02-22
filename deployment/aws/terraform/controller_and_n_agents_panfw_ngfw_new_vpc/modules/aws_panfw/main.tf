locals{
    panfw_name = "${var.aws_stack_name}-panfw-${var.panfw_version}"
}

resource "aws_network_interface" "aws_panfw_interface" {
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-panfw-mgmt-interface"
    }
    source_dest_check = true
    subnet_id = var.resource_group.management_subnet
    security_groups = [var.resource_group.security_group]
}

resource "aws_network_interface" "aws_panfw_cli_interface" {
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-panfw-cli-interface"
    }
    source_dest_check = true
    subnet_id = var.resource_group.client_subnet
    security_groups = [var.resource_group.security_group]
}

resource "aws_network_interface" "aws_panfw_srv_interface" {
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-panfw-srv-interface"
    }
    source_dest_check = true
    subnet_id = var.resource_group.server_subnet
    security_groups = [var.resource_group.security_group]
}

data "aws_ami" "panfw_ami" {
    owners = ["aws-marketplace"]
    most_recent = true
    filter {
      name   = "product-code"
      values = [var.panfw_product_code]
    }
}

resource "aws_eip" "panfw_public_ip" {
  network_interface         = aws_network_interface.aws_panfw_interface.id
  domain = "vpc"
  associate_with_private_ip = aws_instance.aws_panfw.private_ip
}

resource "aws_instance" "aws_panfw" {
    tags = {
        Owner = var.aws_owner
        Name = local.panfw_name
    }


    ami           = data.aws_ami.panfw_ami.image_id 
    instance_type = var.aws_panfw_machine_type
    iam_instance_profile = var.resource_group.bootstrap_profile
    //placement_group = "${var.aws_stack_name}-pg-cluster"

    ebs_block_device {
        device_name = "/dev/sda1"
        volume_size = "100"
        delete_on_termination = true
    }

    network_interface {
        network_interface_id = aws_network_interface.aws_panfw_interface.id
        device_index         = 0
    }

    network_interface {
        network_interface_id = aws_network_interface.aws_panfw_cli_interface.id
        device_index         = 1
    }

    network_interface {
        network_interface_id = aws_network_interface.aws_panfw_srv_interface.id
        device_index         = 2
    }

    credit_specification {
        cpu_credits = "unlimited"
    }

    key_name = var.aws_auth_key
}
