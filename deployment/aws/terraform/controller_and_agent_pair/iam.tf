resource "aws_iam_instance_profile" "IamInstanceProfile" {
	name = "${local.UserLoginTag}_${local.ProjectTag}_IAM_INSTANCE_PROFILE_${local.uuid}_${local.RegionTag}"
	role = aws_iam_role.IamRole.name
}

resource "aws_iam_role_policy_attachment" "IamRolePolicyAttachment" {
	role = aws_iam_role.IamRole.name
	policy_arn = aws_iam_policy.IamPolicy.arn
}

resource "aws_iam_role" "IamRole" {
	name = "${local.UserLoginTag}_${local.ProjectTag}_IAM_ROLE_${local.uuid}_${local.RegionTag}"
	assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Action": "sts:AssumeRole",
			"Principal": {
				"Service": "ec2.amazonaws.com"
			},
			"Effect": "Allow"
		}
	]
}
EOF
	path = "/"
}

resource "aws_iam_policy" "IamPolicy" {
	name = "${local.UserLoginTag}_${local.ProjectTag}_IAM_POLICY_${local.uuid}_${local.RegionTag}"
	description = "IamPolicy"
	policy = jsonencode({
		Version = "2012-10-17"
		Statement = [
			{
				Action = [
					"ec2:CreateNetworkInterface",
					"ec2:DescribeInstances",
					"ec2:ModifyNetworkInterfaceAttribute",
					"ec2:AttachNetworkInterface",
					"ec2:DescribeSubnets",
					"ec2:DescribeSecurityGroups",
					"ec2:DescribeTags"
				]
				Effect = "Allow",
				Resource = "*"
			},
			{
				Action = [
					"ssm:UpdateInstanceInformation",
					"ssmmessages:CreateControlChannel",
					"ssmmessages:CreateDataChannel",
					"ssmmessages:OpenControlChannel",
					"ssmmessages:OpenDataChannel"
				]
				Effect = "Allow",
				Resource = "*"
			}
		]
	})
}