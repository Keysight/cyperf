locals{
    mdw_name = "${var.aws_stack_name}-controller-${var.mdw_version}"
}

resource "aws_network_interface" "aws_mdw_interface" {
    tags = {
        Owner = var.aws_owner
        Name = "${var.aws_stack_name}-mdw-mgmt-interface"
    }
    source_dest_check = true
    subnet_id = var.resource_group.management_subnet
    security_groups = [var.resource_group.security_group]
}

data "aws_ami" "mdw_ami" {
    owners = ["aws-marketplace"]
    most_recent = true
    filter {
      name   = "product-code"
      values = [var.mdw_product_code]
    }
}

resource "aws_eip" "mdw_public_ip" {
  instance = aws_instance.aws_mdw.id
  domain = "vpc"
  associate_with_private_ip = aws_instance.aws_mdw.private_ip
}

resource "aws_instance" "aws_mdw" {
    tags = {
        Owner = var.aws_owner
        Name = local.mdw_name
    }


    ami           = data.aws_ami.mdw_ami.image_id 
    instance_type = var.aws_mdw_machine_type
    //placement_group = "${var.aws_stack_name}-pg-cluster"

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
