# About CyPerf AWS CloudFormation Templates
## Introduction
Welcome to the GitHub repository for Keysight CyPerf’s CloudFormation templates for deploying CyPerf with Amazon Web Services. 

To start using CyPerf's CFT templates, please see the **README** files in each individual directory and decide on which template to start with from the below list.

## Prerequisites
The prerequisites are:
- Key pair for management access to CyPerf instances.
- For existing VPC deployment, an existing VPC, two existing subnets in that VPC (one for test and one for Management) and existing security groups for CyPerf Controller/ Controller Proxy and CyPerf Agent.
- Permissions to create AWS Identity and Management (IAM) roles; these roles are required for Keysight CyPerf Agent to interact with the AWS environment.
- Permissions to create subnets.
- Permissions to create and access interfaces.
- Before template deployment, subscribe required Keysight CyPerf marketplace product version from [aws marketplace](https://aws.amazon.com/marketplace).
- User must be associated with managed IAM policy **"AWSCloudFormationFullAcess"** and a custom IAM policy

Note:
    JSON format for custom policy

    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "VisualEditor0",
                "Effect": "Allow",
                "Action": [
                    "iam:*",
                    "s3:*",
                    "lambda:*",
                    "cloudformation:*",
                    "ec2:*"
                ],
                "Resource": "*"
            }
        ]
    }

## Specialized knowledge
Before you deploy a CloudFormation template, we recommend that you become familiar with the following AWS services:
- [Amazon EC2](https://docs.aws.amazon.com/ec2/index.html)
- [Amazon Elastic Block Store (Amazon EBS)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonEBS.html)
- [Amazon VPC](https://docs.aws.amazon.com/vpc/index.html)
- [AWS CloudFormation](https://docs.aws.amazon.com/cloudformation/index.html)


If you are new to AWS, see [Getting Started with AWS](https://aws.amazon.com/getting-started/).

## Supported instance types 
The supported instance types are:
- For the CyPerf Controller, the supported instance type is c4.2xlarge.
- For CyPerf Agents, the supported instance types are c4.2xlarge and c5n.9xlarge.

## List of Supported CyPerf CloudFormation templates for AWS deployments
The following is a list of the current supported CyPerf CloudFormation templates. Click the links to view the README files which include the topology diagrams. 

### I. [Controller and Agent Pair](controller_and_agent_pair):

This template deploys:
- One CyPerf Controller, in a public subnet.
- Two CyPerf Agents both having two interfaces each. Each of the interafces for an Agent is in different Private subnet. One subnet is for test traffic between two Agents through the DUT, and the other subnet is for control traffic between Agents and Controller/Controller Proxy.

Select **New VPC** to deploy a new VPC or **Existing VPC** to deploy in an already existing VPC.

### II. [Controller Proxy and Agent Pair](controller_proxy_and_agent_pair):

This template deploys:
- One CyPerf Controller Proxy, in a public subnet.
- Two CyPerf Agents both having two interfaces each. Each of the interafces for an Agent is in different Private subnet. One subnet is for test traffic between two Agents through the DUT, and the other subnet is for control traffic between Agents and Controller/Controller Proxy.

Select **New VPC** to deploy a new VPC or **Existing VPC** to deploy in an already existing VPC.

### III. [Controller Only](controller_only):

This template deploys:
- A CyPerf Controller, in a public subnet.

Select **New VPC** to deploy a new VPC or **Existing VPC** to deploy in an already existing VPC.

### Template information
Descriptions for each template are contained at the top of each template in the Description key. For additional information and assistance in deploying a template, see the README file on the individual template directories.

### AWS RIGHTS

AmazonEC2FullAccess need to be given to the user that will create the deployments using terraform templates.

## Troubleshooting and Limitations

### Known Limitations

### Troubleshooting

- I encountered a **CREATE_FAILED** error when I tried deploying cloudformation template:

If AWS CloudFormation fails to create the stack, it is recommended that you relaunch the template with **Rollback on failure** set to **No**. You can find this setting in **Options** > **Advanced** in the AWS CloudFormation console.
With this setting, the stack’s state is retained, and the instance is left running so you can troubleshoot the issue. Look for the log files in **%ProgramFiles%\Amazon\EC2ConfigService** and **C:\cfn\log**.

When you set the **Rollback on failure** setting to **No**, you will continue to incur AWS charges for this stack. Make sure to delete the stack when you finish troubleshooting. For additional information, see [Troubleshooting AWS CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/troubleshooting.html) on the AWS website.

- I encountered a size limitation error when I deployed the AWS CloudFormation templates:

If you deploy the templates from a local copy on your computer or from a non-S3 location, you might encounter template size limitations when you create the stack.
For more information about AWS CloudFormation limits, see the [AWS](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cloudformation-limits.html) documentation.

