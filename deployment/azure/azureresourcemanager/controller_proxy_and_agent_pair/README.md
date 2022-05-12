# Deploying the CyPerf in Azure for controller proxy and agent pair        
## Introduction
This solution uses an ARM Template to deploy CyPerf Controller-proxy and two CyPerf Agents in an Azure Cloud.

There is a new VNET template, meaning the entire necessary resources will be created from scratch, including VNET, subnets, Security group etc.

Existing VNET template, meaning entire network resources like Resource group, VNET, subnets, Security group are pre-existing. User will be able to select existing VNET, subnet and security group during deployment.

See the Template Parameters Section for more details. Each agent has two interfaces. One is Management interface and other is Test interface. Agent communicate with Controller-proxy using Management interface. CyPerf test traffic flows through Test interface.  In this deployment first or default interface of Agent is set as management interface and second interface is set as test interface. 


## Topology Diagram
![cyperf_controller_proxy_and_agent_pair.jpg](cyperf_controller_proxy_and_agent_pair.jpg)

## Template Parameters
The following table lists the parameters for this deployment in **New VNET**.

| **Parameter label (name)**                   | **Default**            | **Description**  |
| ----------------------- | ----------------- | ----- |
| Subscription                   | Requires input            | Specify the Azure subscription from dropdown list.  |
| Resource group                   | Requires input            | Either select an existing Resource group from dropdown or create a new resource group with **Create new** option.  |
| Location                   | (US) Central US            | Preferred deployment location from dropdown list.  |
| Deployment Name                   | Requires input            | Preferred prefix for naming resources.  |
| Proximity Placement Group                   | No            | Preferred choice of proximity.  |
| Virtual Network                   |    172.16.0.0/16         | CIDR range for the Virtual Network.  |
| Management Subnet for CyPerf Controller-proxy & Agent                   | 172.16.2.0/16            | This subnet is attached to CyPerf controller proxy & CyPerf agents will use this subnet for control plane communication with controller-proxy.  |
| Test Subnet for CyPerf Agents                   | 172.16.3.0/24            | CyPerf agents will use this subnet for test traffic.  |
| VHD URL of CyPerf Agents                   | Requires input            | VHD URL link of CyPerf Agent. VHD file must be present at user’s own storage Account and Container. Example: https://cyperf.blob.core.windows.net/keysight-cyperf-*/keysight-cyperf-agent-*.vhd |
| VHD URL of CyPerf Controller-proxy                   | Requires input            | VHD URL link of CyPerf Controller-proxy. VHD file must be present at user’s own storage Account and Container. Example: https://cyperf.blob.core.windows.net/keysight-cyperf-*/keysight-cyperf-controller-proxy-*.vhd |
| VM Size Type for CyPerf Agents                   | Standard_F4s_v2            | VM type for CyPerf Agent. VM type Standard_F4s_v2 and Standard_F16s_v2 are qualified.  |
| SSH Public Key                   | Requires input            | Public key to enable SSH access to the CyPerf instances. User may create private key & public key using ssh-keygen. Then specify ssh public key here.   |
| Allowed Subnet for Security Group                   | Requires input            | Subnet range allowed to access deployed Azure resources. Execute `curl ifconfig.co` to know MyIP or google for “what is my IP”.  |
| Number of CyPerf Agents                   | 2            | Number of CyPerf agents will be deployed from this template.  |

The following table lists the parameters for this deployment in **Existing VNET**.

| **Parameter label (name)**                   | **Default**            | **Description**  |
| ----------------------- | ----------------- | ----- |
| Subscription                   | Requires input            | Specify the Azure subscription from dropdown list.  |
| Resource group                   | Requires input            | Either select an existing Resource group from dropdown or create a new resource group with **Create new** option.  |
| Location                   | (US) Central US            | Preferred deployment location from dropdown list.  |
| Deployment Name                   | Requires input            | Preferred prefix for naming resources.  |
| Proximity Placement Group                   | No            | Preferred choice of proximity.  |
| Virtual Network                   | Requires input            | Name of an existing Virtual Network.  |
| Management Subnet for CyPerf Controller-proxy & Agent                  | Requires input            | Name of existing management subnet. This subnet is attached to CyPerf controller proxy & CyPerf agents will use this subnet for control plane communication with controller proxy.  |
| Test Subnet for CyPerf Agents                   | Requires input            | Name of existing Test subnet. CyPerf agents will use this subnet for test traffic. CyPerf agents will use this subnet for test traffic.  |
| VHD URL of CyPerf Agents                   | Requires input            | VHD URL link of CyPerf Agent. VHD file must be present at user’s own storage Account and Container. Example: https://cyperf.blob.core.windows.net/keysight-cyperf-*/keysight-cyperf-agent-*.vhd  |
| VHD URL of CyPerf Controller-proxy                   | Requires input            | VHD URL link of CyPerf Controller-proxy. VHD file must be present at user’s own storage Account and Container. Example: https://cyperf.blob.core.windows.net/keysight-cyperf-*/keysight-cyperf-controller-proxy-*.vhd |
| VM Size Type for CyPerf Agents                   | Standard_F4s_v2            | VM type for CyPerf Agent. VM type Standard_F4s_v2 and Standard_F16s_v2 are qualified.  |
| SSH Public Key                   | Requires input            | Public key to enable SSH access to the CyPerf instances. User may create private key & public key using ssh-keygen. Then specify ssh public key here.   |
| Allowed Subnet for Security Group                   | Requires input            | Subnet range allowed to access deployed Azure resources. Execute `curl ifconfig.co` to know MyIP or google for “what is my IP”.  |
| Number of CyPerf Agents                   | 2            | Number of CyPerf agents will be deployed from this template.  |

**Note:** **CyPerf** and **Cyperf** represents same. ARM templates use **Cyperf** instead of **CyPerf** and it becomes an Azure limitation that introduces extra space.


## Post deployment

After successful deployment of stack, flow bellow instructions

-	Go to Azure console and look for the deployed VMs
-	Select the Controller Proxy instance and check the public IP 
-	Open your browser and access preexisting CyPerf Controller UI with URL https://"Controller Public IP" (Default Username/Password: admin/`CyPerf&Keysight#1`)
-   Select the gear icon in the right top corner. Select “Administration”, followed by “Controller Proxies” and then add the Controller Proxy public IP.
-   Registered CyPerf agents should appear in Controller UI automatically.
-   CyPerf license needs to be procured for further usage. These licenses need to be configured at “Administration” followed by “License Manager” on CyPerf controller gear menu.