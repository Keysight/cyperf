# Manual AMI Deployment
<!-- blank line -->
	
This section explains how to deploy Keysight CyPerf Controller, Agent, and Controller Proxy manually using AWS console.

## Step 1: Prerequisite
1.	Create an AWS account at [https://aws.amazon.com](https://aws.amazon.com/) if you do not have one. Follow the instructions displayed on the screen.
2.	Choose the AWS region where you want to deploy Keysight CyPerf components using the region selector in the navigation bar.
3.	Create or identify preferred existing  [key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) in your  preferred region.
4.	Create or identify preferred existing VPC for your deployment.
5.	For Controller / Controller Proxy deployment, create or identify preferred existing public subnet at previous mentioned VPC. 
6.	For Agent deployment, create or identify two preferred private subnets at previously mentioned VPC.
One subnet is used for Control subnet and another subnet is used for test subnet.
Control subnet should reside behind NAT gateway, if Agents need to reach outside VPC network.
7.	If necessary, request a service limit increase for the **Amazon EC2 c5.2xlarge** instance type (or the instance type you are planning to use for the Keysight CyPerf Agent instances). You might need to do this if you have an existing deployment that uses the same instance type, and you have exceeded the [default limit](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-resource-limits.html).

## Step 2: Subscribe to the AMIs Used by the Manual Deployment
This manual deployment uses publicly available Keysight CyPerf Controller, Agent, and Controller Proxy AMIs. 
The following AMIs are available for CyPerf 3.0 release.

-	keysight-cyperf-controller-3-0

-	keysight-cyperf-controller-proxy-3-0

-	keysight-cyperf-agent-3-0

## Step 3: Launch the Keysight CyPerf Controller

**Note:** 
You are responsible for the cost of the AWS services used while running this manual deployment. 
Keysight CyPerf license needs to be procured for further usage. These licenses need to be configured at **“Administration” -> “License Manager”** on CyPerf controller gear menu. For further details, see the pricing pages for each AWS service you will be using in this manual deployment guide. Prices are subject to change.

1.	In the AWS console, select **EC2** service, followed by **Instances** and **Launch Instance**.
2.	Go to **Community AMIs** and select **“keysight-cyperf-controller-3-0”**. 
3.	Select Instance Type **“c5.2xlarge”** and move next. 
4.	Select your preferred **VPC**, preferred public subnet in that **VPC** and move next. 
5.	Keep default storage size **100 GiB** and move next. 
6.	Select or create a Security group with the following ingress custom TCP port.
 
    a. If Agents directly peers with Controller, then 
    allow **443** from your desired source IP range, where the Agents belong.

        Note: If Agents are in AWS private subnet, allow NAT gateways IP for 443 port in the ingress rule.
        Assuming all IPs and ports are allowed for egress rule.
                
    b. Allow **443** from your desired source IP range to access CyPerf Controller from your browser.
 
7.	Select **Launch** and then select the pre-created key pair.
8.	Once the **Controller** is deployed, note down its private and public IP address.
9.	Access CyPerf Controller from your browser with URL: https://"Controller Public IP". 

        Note: 
        
        Replace "Controller public IP" with the appropriate public IP. Then provide the following default credentials to login.

            Username: admin
            Password: CyPerf&Keysight#1

## Step 4: Launch the Keysight CyPerf Controller Proxy

**Note:**
You are responsible for the cost of the AWS services used while running this manual deployment. There is no additional cost for using this manual deployment. For further details, see the pricing pages for each AWS service you will be using in this manual deployment guide. Prices are subject to change.
1.	In the AWS console, select **EC2** service, followed by **Instances** and **Launch Instance**.
2.	Go to **Community AMIs** and then select **“keysight-cyperf-controller-proxy-3-0”**. 
3.	Select Instance Type **“t2.medium”** and move next. 
4.	Select your preferred **VPC**, preferred public subnet in that **VPC** and move next. 
5.	Keep default storage size **8 GiB** and move next. 
6.	Select or create a Security group with bellow ingress custom TCP port.
 
    a.	**Allow 443** from CyPerf Controller public IP.
    
    b.	**Allow 22** from your desired source IP range for ssh access.

7.	Select **Launch** and then select the pre-created key pair.
8.	Once the **Controller Proxy** deployed, note down its private and public IP address.

9.	After the Controller Proxy deployment is finished, add Controller Proxy IP in CyPerf Controller. 
10. Browse CyPerf Controller. Select the **gear**  ![gear](images/gear.png) icon in the right top corner.  Select **“Administration”**, followed by **“Message Brokers”** and then add the Controller Proxy IP.

## Step 5: Launch the Keysight CyPerf Agents

**Note:**
You are responsible for the cost of the AWS services used while running this manual deployment. Keysight CyPerf license needs to be procured for further usage. These licenses need to be configured at **“Administration” -> “License Manager”** on CyPerf controller gear menu. For further details, see the pricing pages for each AWS service you will be using in this manual deployment guide. Prices are subject to change.

**Note:**
Private subnets require NAT gateways or NAT instances in their route tables to allow the instances to download packages and software without exposing them to the internet. You will also need the domain name option configured in the DHCP options as explained in the [Amazon VPC documentation](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_DHCP_Options.html).

1.	In the AWS console, select **EC2** service, followed by **Instances** and **Launch Instance**.
2.	Go to **Community AMIs** and search and select **“keysight-cyperf-agent-3-0”**. 
3.	Specify Number of instances minimum **2**.
4.	Select Instance Type **“c5.2xlarge”** or **“c5n.9xlarge”** and move next. 
5.	Select your preferred **VPC** and then select,

    a. One pre-exists private subnet in that **VPC** for control traffic for network interface eth0 or ens4. 

    b. Another pre-exists private subnet in that **VPC** for test traffic for network interface eth1 or ens5.

**_NOTE_**, if Agent deployed with single interface only and test interface added explicitly after deployment, please jump to [**Set netplan**](#set-netplan) section, followwed by [**Set cyperfagent configuration**](#Set-cyperfagent-configuration)
6.	 In the **Advanced Details** section, in the **User Data** field, add the following lines:

```
#!/bin/bash -xe
cd /opt/keysight/tiger/active/bin/
sh /opt/keysight/tiger/active/bin/Appsec_init "IP" >> /var/log/Appsec_init.log


Note:

I. Replace "IP" with the Controller Public IP if Agents directly peer with CyPerf Controller. Also, Agents and Controller are not in same VPC.

II.	Replace "IP" with the Controller private IP if Agents directly peer with CyPerf Controller. Also, Agents and Controller are in same VPC.

III. Replace "IP" with the Controller Proxy Public IP if Agents peer with CyPerf Controller Proxy. Also, Agents and Controller Proxy are not in same VPC.

IV.	Replace "IP" with the Controller Proxy private IP if Agents peer with CyPerf Controller Proxy. Also, Agents and Controller Proxy are in same VPC.

```
7.	Keep default storage size **8** GiB and move next. 
8.	Select or create a Security group with ingress custom TCP port **22, 80, 443 or** any other custom ports used for test traffic from the VCP CIDR source IP range. 
9.	Select **Launch** and select the pre-created key pair.
10.	After successful Agent deployment, Agent should appear in CyPerf Controller.


### Set netplan

After the deployment is complete and the EC2 is in running state, the management interface must get
an IP from the DHCP server.
1. Establish a SSH connection to the CyPerf agent using the following credentials:
  username: cyperf
  password: cyperf
2. Configure the netplan settings in the file **/etc/netplan/aws-vmimport-netplan.yaml** to set the IP address
of the test interface. Choose either DHCP or static configuration based on your requirements.
For more details, see the [netplan documentation](https://github.com/canonical/netplan/tree/main/examples).

**_NOTE:_** If the Management and Test Network are in the same vpc, then the management interface must have a lower metric than the test interface.

In the following example, the user selects the test and management subnet from same VPC. ens5 is the management interface, and ens6 is the test interface. That is why the user sets metric 100 for the management interface and metric 200 for the test interface in netplan. User must specify right interface name in netplan yaml.

```
network:
  version: 2
  renderer: networkd
  ethernets:
    ens5:
      dhcp4: yes
      dhcp-identifier: mac
      dhcp4-overrides:
        route-metric: 100
    ens6:
      dhcp4: yes
      dhcp-identifier: mac
      dhcp4-overrides:
        route-metric: 200

```
After netplan configuration, apply netplan:
```
sudo netplan apply
```
### Set cyperfagent configuration ###

Use the CLI cyperfagent to configure the required parameters.
The following commands are available in CLI:
```
cyperfagent controller show
```
Shows the currently configured controller.
```
cyperfagent controller set <Controller-IPv4|Controller-Hostname> --username=<USERNAME> --password=<PASSWORD> --skipidentity-verification
```
Sets the controller. Default username "admin", password "CyPerf&Keysight#1"
For more details, see Connecting [CyPerf Agents to a Controller](#https://downloads.ixiacom.com/library/user_guides/KeysightCyPerf/3.0/CyPerf_Deployment_Guide.pdf).
```
cyperfagent interface management show
```
Shows the currently configured Management
Interface.
```
cyperfagent interface management set ens5
```
Sets the Management Interface to ens5

Or
```
cyperfagent interface management set auto
```
Sets the Management Interface to auto for dynamically detecting the Interface at runtime
```
cyperfagent interface test set ens6
```
Sets the Test Interface to ens6

Or
```
cyperfagent interface test set auto
```
Sets the Test Interface to auto for dynamically
detecting the Interface at runtime.
