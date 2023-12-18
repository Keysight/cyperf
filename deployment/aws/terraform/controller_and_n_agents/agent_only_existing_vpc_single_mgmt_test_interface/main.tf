provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.aws_region
}

locals{
    options_tag             = "MANUAL"
    project_tag             = "CyPerf"
    agent_init_cli = <<-EOF
                #! /bin/bash
                 sudo rm -rf /etc/portmanager/node_id.txt
                 cyperfagent feature allow_mgmt_iface_for_test enable
                 sudo cyperfagent controller set ${var.aws_controller_ip} --skip-restart
                 sudo cyperfagent tag set ${var.agents_tag_name}=${var.agents_tag_value} --skip-restart
                 sudo cyperfagent configuration reload
    EOF
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

data "aws_subnet" "agent_mgmt_test_subnet" {
    filter {
      name   = "tag:Name"
      values = [var.mgmt_test_subnet_name]
    }
}

data "aws_security_group" "aws_agent_sg" {
    filter {
      name   = "tag:Name"
      values = [var.agents_sg_name]
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



####### Agents #######
module "agents" {
    depends_on = [time_sleep.wait_5_seconds]
    count = var.agents
    source = "../modules/aws_agent"
    resource_group = {
        aws_agent_security_group = data.aws_security_group.aws_agent_sg.id,
        aws_ControllerManagementSubnet = data.aws_subnet.agent_mgmt_test_subnet.id,
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

output "agent_detail"{
  value = [for x in module.agents :   {
    "name" : x.agents_detail.name,
    "private_ip" : x.agents_detail.private_ip
  }]
}


 