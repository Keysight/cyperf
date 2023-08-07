# CyPerf Agents in Containers environments
## Introduction
This document describes how you can deploy the Keysight CyPerf agents inside Docker Container. The following sections contain information about the prerequisites, manual deployment steps and sample bash scripts for automated deployment.

- [General Prerequisites](#general-prerequisites)
- [Workflow](#workflow)
- [Manual Deployment](#manual-deployment)
- [Automated Deployments](#automated-deployment)
- [Test Configuration Checklist](#test-configuration-checklist)
- [Troubleshooting](#troubleshooting)
- [Known Limitations](#known-limitations)


## General Prerequisites
To deploy a Keysight CyPerf agent container at Docker, you need the following:
1. Install Docker Engine in your desired host platform if not already. Refer [Install Docker Engine](https://docs.docker.com/engine/install/) for more details.

2. Pull CyPerf Agent Docker image from public ECR `public.ecr.aws/keysight/cyperf-agent:latest` . Refer [Pull an image](https://docs.docker.com/engine/reference/commandline/pull/) for more details.

```
sudo docker pull public.ecr.aws/keysight/cyperf-agent:latest
```
    
3.  A CyPerf Controller that is already deployed and accessible from the Agent docker containers.  
    - **_NOTE:_** For information on how to deploy CyPerf Controller, see _Chapter 2_ of the [Cyperf User Guide](http://downloads.ixiacom.com/library/user_guides/KeysightCyPerf/2.1/CyPerf_UserGuide.pdf).

4.  A CyPerf Controller Proxy in a hybrid deployment scenario, where each of the distributed agents cannot directly access the CyPerf Controller. 
For example, if a CyPerf controller is deployed on-premise and the other is deployed in the cloud, they can still communicate through a CyPerf Controller Proxy. In this case, the public IP address of the Controller Proxy is configured in the CyPerf Controller and Agents register to the Controller through the Controller Proxy.

5.  Make sure that the ingress security rules for CyPerf Controller (or Contoller Proxy) allow port numbers **443** and **30422** for the control subnet in which Agent and CyPerf Controller (or Controller Proxy) can communicate.

    ```
## Workflow
To test a device which is running inside a Docker, do the following:
- Select and start with a Docker setup that is already deployed. The containerized device under test (DUT) is also expected to be deployed in the same Docker host or, deployed outside the Docker host and accessible from Agent docker containers.
- There must be a CyPerf Controller already deployed as well. Once the CyPerf Agents are deployed in the Docker following the steps described below, they will automatically get registered to CyPerf Controller and become ready to use.
- A CyPerf Controller Proxy is required in hybrid deployment scenarios, where each of the distributed Agents cannot directly access the CyPerf Controller. For example, when the CyPerf Controller is deployed on-premise and some CyPerf agents are in the cloud, they can still communicate through a CyPerf Controller Proxy. In this case, Agents register to the Controller Proxy and the public IP address of the Controller Proxy that is configured in the CyPerf Controller.
- Introduce the CyPerf Agent as a client or a server or as both that are running inside the same Docker host or separate docker host. This can be achieved by applying the [manual deployment](#manual-deployment). 
    - **_NOTE:_** Agents will be visible (by their tags and IP addresses) in the _Agent Assignment_ dialog.
- Create a test using CyPerf Controller UI. Select Agents for respective _Network Segments_ and configure appropriate properties in the _DUT Network->Configure DUT_ page in the UI before running the test. 
  - **_NOTE:_** For more information, see _Chapter 3_ of the [Cyperf User Guide](http://downloads.ixiacom.com/library/user_guides/KeysightCyPerf/2.1/CyPerf_UserGuide.pdf).

###  **Manual Deployment**

- Deploy both server and client agent containers on the same host
```
# Create a local network

sudo docker network create --subnet=192.168.0.1/24 test-network

# Deploy Client agent

sudo docker run -td --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ClientAgent --network=test-network -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerClient" public.ecr.aws/keysight/cyperf-agent:latest

# Deploy Server agent

sudo docker run -td --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ServerAgent --network=test-network -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerServer"  public.ecr.aws/keysight/cyperf-agent
```

- Deploy both server and client agent containers on different host
```
# Create a local network on a client host

sudo docker network create --subnet=192.168.0.1/24 test-client-network

# Deploy Client agent

sudo docker run -td --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ClientAgent --network=test-client-network -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerClient" public.ecr.aws/keysight/cyperf-agent:latest

# Create a local network on a server host

sudo docker network create --subnet=172.18.0.1/24 test-server-network

# Deploy Server agent

sudo docker run -td --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ServerAgent --network=test-server-network -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerServer" -p 80:80 -p 443:443  public.ecr.aws/keysight/cyperf-agent:latest
```

###  **Automated Deployment**

To deploy a Keysight CyPerf agent container at Docker, you need to install Docker engine on the docker host if not done already. Below is a sample bash script to install the docker engine on the Ubuntu host.

- Docker Installation: [install_docker_ubuntu.sh](agent_examples/install_docker_ubuntu.sh)

Execute this script from your ubuntu host. This will install Docker Engine in your host.

```
$bash containers/agent_examples/install_docker_ubuntu.sh
```

- Docker Uninstalltion: [uninstall_docker_ubuntu.sh](agent_examples/uninstall_docker_ubuntu.sh)

Execute this script from your ubuntu host. This will uninstall Docker Engine from your host.

```
$bash containers/agent_examples/uninstall_docker_ubuntu.sh
```

- CyPerf Container Agent Pair Deployment: [cyperf_agent_container_pair_deployment.sh](agent_examples/cyperf_agent_container_pair_deployment.sh)

Execute this script from your ubuntu host. This will deploy a pair of CyPerf Agent containers in the same host.

```
$bash containers/agent_examples/cyperf_agent_container_pair_deployment.sh -c <CYPERF CONTROLLER IP>
```
## Test Configuration Checklist
Ensure that the following configurations are appropriate, when configuring the CyPerf Controller for a test where CyPerf Agents container are running in the docker host. 

1. _NetWork Segment_ that is using a Cyperf Agent(s) inside a docker, should use the  _Automatic IP_, _Automatic IP prefix length_, and _Automatic gateway_ for the _IP Range_ configuration.
2. _NetWork Segment_ that is using a Cyperf Agent(s) which is simulating clients inside a docker, should use the correct IP address for _Name server_ in _DNS Resolver_ configuration to resolve FQDN of the DUT. This is not applicable if the _DUT Network_ is configured for the _Host_ with an IP address of the DUT.
3. CyPerf Agents that are simulating clients will send traffic to _Destination port_ as configured in _Connection Properties_ for _Application->Connections_. By default (indicated as `0` in UI), HTTP port `80` and TLS port `443` are used. If the DUT uses any non-default destination port for the incoming connections, you need to set this configuration appropriately.
4. CyPerf Agents that are simulating servers will listen to the _Server port_ as configured in  _Connection Properties_ for _Application->Connections_. By default (indicated as `0` in UI), HTTP port `80` and TLS port `443` are used. If the DUT uses any non-default destination port for outgoing connections, you need to set this configuration appropriately.
5. Make sure that the DUT is forwarding the traffic to a port which is used in port mapping while deploying the server agent container. Refer to section "# Deploy server agent" [Manual Deployment](#manual-deployment). 
6. If the DUT is also configured for the HTTP health check, use the same configuration as described above. 
     

## Troubleshooting

1. Collecting CyPerf Agent Logs
- At present, CyPerf Agent that is running as a container does not publish logs when collecting diagnostics from CyPerf Controller UI. However, individual container logs can be collected manually. First identify the container and then use the ID for redirecting the logs to a file. You need to transfer them manually.        
    ```
    sudo docker logs [cyperf-agent-container-id]

    sudo docker logs [cyperf-agent-container-id]  > [cyperf-agent-container-id].log 
    ```
2. Agents not visible in CyPerf Controller
- Make sure that the ingress security rules for CyPerf Controller [(or Contoller Proxy)](#general-prerequisites) allow port numbers 443 and 30422 for the control subnet in which Agent and CyPerf Controller (or Controller Proxy) can communicate. 
- Also check that the Agent containers are in ready state after deployment.
    ```
    sudo docker container ls
    ```  
     If containers are stuck in pending state, check the available resource in the docker host.
   
## Known Limitations
1. CyPerf does not support IPv6 address for management interface yet.
2. If host doesn’t have ip6tables module enabled container deployment might fail. Try following the steps in host machine to fix the problem.
```
find /lib/modules/$(uname -r) -type f -name ip6*
sudo modprobe ip6_tables
sudo modprobe ip6table_filter
```
3. Controller time and docker hosts time might be out of sync. This may result in an empty stat view in UI. To resolve setup NTP in docker host. A Controller can also be used as an NTP server. Refer to the host OS specific configuration to setup NTP. Example: [Setting NTP in Ubunutu 22.04](https://linuxconfig.org/ubuntu-22-04-ntp-server)

## Releases

- **CyPerf 2.1** - [March, 2023]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release2.1
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.523

    - Change history:

- **CyPerf 2.0** - [September, 2022]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release2.0
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.450

    - Change history:

- **CyPerf 1.7** - [August, 2022]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release1.7
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.423

    - Change history:

- **CyPerf 1.6** - [June, 2022]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release1.6
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.401  

    - Change history:

- **CyPerf 1.5** - [April, 2022]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release1.5
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.378  

    - Change history:

- **CyPerf 1.1-Update1** - [December, 2021]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release1.1-update1
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.249  

    - Change history:

- **CyPerf 1.1** - [October, 2021]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release1.1
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.233  

    - Change history:
        

- **CyPerf 1.0-Update1** - [July, 2021]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release1.0-update1
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.205  

    - Change history:
        
        - AWS VPC CNI is now supported.

    
- **CyPerf 1.0** - [May, 2021]
    - Image URI: 

        - public.ecr.aws/keysight/cyperf-agent:release1.0
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.170
