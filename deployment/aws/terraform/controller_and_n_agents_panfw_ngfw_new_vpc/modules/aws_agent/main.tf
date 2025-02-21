locals{
    cli_agent_name = "${var.agent_role}-${var.aws_stack_name}-${var.agent_version}"
}


resource "aws_network_interface" "aws_mgmt_interface" {
    tags = {
        Owner = var.tags.aws_owner
        Name = "${var.aws_stack_name}-mgmt-interface"
        Project = var.tags.project_tag
        Options = var.tags.options_tag
    }
    source_dest_check = true
    subnet_id = var.resource_group.aws_ControllerManagementSubnet
    security_groups = [var.resource_group.aws_agent_security_group]
}

resource "aws_network_interface" "aws_cli_test_interface" {
    tags = {
        Owner = var.tags.aws_owner
        Name = "${var.aws_stack_name}-cli-test-interface"
        Project = var.tags.project_tag
        Options = var.tags.options_tag
    }
    source_dest_check = true
    subnet_id = var.resource_group.aws_AgentTestSubnet
    security_groups = [var.resource_group.aws_agent_security_group]
}

data "aws_ami" "agent_ami" {
    owners = ["aws-marketplace"]
    most_recent = true
    filter {
      name   = "product-code"
      values = [var.agent_product_code]
    }
}

resource "aws_instance" "aws_cli_agent" {
    tags = {
        Owner = var.tags.aws_owner
        Name = local.cli_agent_name
        Project = var.tags.project_tag
        Options = var.tags.options_tag
    }
    ami           = data.aws_ami.agent_ami.image_id 
    instance_type = var.aws_agent_machine_type
    //iam_instance_profile = var.resource_group.instance_profile
    //placement_group = "${var.aws_stack_name}-pg-cluster"

    ebs_block_device {
        device_name = "/dev/sda1"
        volume_size = "8"
        delete_on_termination = true
    }

    network_interface {
        network_interface_id = aws_network_interface.aws_mgmt_interface.id
        device_index         = 0
    }

        network_interface {
        network_interface_id = aws_network_interface.aws_cli_test_interface.id
        device_index         = 1
    }

    credit_specification {
        cpu_credits = "unlimited"
    }
    user_data = var.agent_init_cli

    key_name = var.aws_auth_key
}
