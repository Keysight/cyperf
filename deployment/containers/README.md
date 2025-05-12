# CyPerf Agents in Containers environments
## Introduction
This document describes how you can deploy the Keysight CyPerf agents inside Docker Container. The following sections contain information about the prerequisites, manual deployment steps and sample bash scripts for automated deployment.

CyPerf Agent container also supports DPDK. Refer [DPDK Support - CyPerf Agents in Container Environments](#dpdk-support---cyperf-agents-in-container-environments)
- [General Prerequisites](#general-prerequisites)
- [Workflow](#workflow)
- [Manual Deployment](#manual-deployment)
- [Automated Deployments](#automated-deployment)
- [Test Configuration Checklist](#test-configuration-checklist)
- [Troubleshooting](#troubleshooting)
- [Known Limitations](#known-limitations)


## General Prerequisites
To deploy a Keysight CyPerf agent container at Docker, you need the following:
1. Install Docker Engine in your desired host platform if not already. Refer [Install Docker Engine Server](https://docs.docker.com/engine/install/#server) for more details.
2. Understand docker compose. Refer [Docker Compose](https://docs.docker.com/compose/gettingstarted/)
3. Pull CyPerf Agent Docker image from public ECR `public.ecr.aws/keysight/cyperf-agent:latest` . Refer [Pull an image](https://docs.docker.com/engine/reference/commandline/pull/) for more details.

    ```
    sudo docker pull public.ecr.aws/keysight/cyperf-agent:latest
    ```
    - **_NOTE:_**
    In case this public repository cannot be used to pull the CyPerf Agent Docker image, download it (.tar) [here](https://support.ixiacom.com/keysight-cyperf-60) and load it using the following command
    
        ```
        sudo docker load -i <downloaded tar file>
        ```
        The loaded image needs to be tagged properly and samples need to be updated accordingly.

4.  A CyPerf Controller that is already deployed and accessible from the Agent docker containers.  
    - **_NOTE:_** For information on how to deploy CyPerf Controller, see _Chapter 2_ of the [Cyperf User Guide](http://downloads.ixiacom.com/library/user_guides/KeysightCyPerf/2.1/CyPerf_UserGuide.pdf).

5.  A CyPerf Controller Proxy is required in hybrid deployment scenarios, where each of the distributed Agents cannot directly access the CyPerf Controller. For example, if the CyPerf Controller is deployed on premise and some CyPerf Agents are in the cloud, they can still communicate through a CyPerf Controller Proxy. In this case, the public IP address of the Controller Proxy is configured in the CyPerf Controller and Agents become available to the Controller by registering to the Controller Proxy.

6.  Make sure that the ingress security rules for CyPerf Controller (or Contoller Proxy) allow port numbers **443** for the control subnet in which Agent and CyPerf Controller (or Controller Proxy) can communicate.

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

sudo docker network create --subnet=192.168.0.0/24 test-network

# Deploy Client agent

sudo docker run -td --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ClientAgent --network=test-network -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerClient" public.ecr.aws/keysight/cyperf-agent:latest

# Deploy Server agent

sudo docker run -td --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ServerAgent --network=test-network -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerServer"  public.ecr.aws/keysight/cyperf-agent:latest

# If client is sending traffic outside the host to a DUT and traffic is coming back to server container from DUT via host then use port forwarding like below

sudo docker run -td --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ServerAgent --network=test-server-network -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerServer" -p 80:80 -p 443:443  public.ecr.aws/keysight/cyperf-agent:latest
```

- Deploy both server and client agent containers on different host
```
# Create a local network on a client host

sudo docker network create --subnet=192.168.0.0/24 test-client-network

# Deploy Client agent

sudo docker run -td --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ClientAgent --network=test-client-network -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerClient" public.ecr.aws/keysight/cyperf-agent:latest

# Create a local network on a server host

sudo docker network create --subnet=172.18.0.0/24 test-server-network

Please note, that client and server network CIDR should be different. This step has been added to separate Client and Server IP on the Controller side as CyPerf agents are identified by IP at CyPerf Controller.

# Deploy Server agent

sudo docker run -td --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ServerAgent --network=test-server-network -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerServer" -p 80:80 -p 443:443  public.ecr.aws/keysight/cyperf-agent:latest
```
By default, when you create or run a container using docker create or docker run, the container doesn't expose any of its ports to the outside world. Use the --publish or -p flag to make a port available to services outside of Docker. This creates a firewall rule in the host, mapping a container port to a port on the Docker host to the outside world. In the above  example:

-p 80:80 Map port 80 on the Docker host to TCP port 80 in the container.

### **Docker Compose**

- Compose manifest: [agent_examples/docker-compose.yml](agent_examples/docker-compose.yml) 

- Modifications that are required to delpoy a CyPerf Agents, are as follows:
    1. Replace the place holder container `image` URL with the specific version, that you want to use for the CyPerf Agent container. You can get this URL from [Keysight software download portal](https://support.ixiacom.com/keysight-cyperf-software-downloads-documentation).
    2. Replace the place holder `AGENT_CONTROLLER` value with your CyPerf Controller IP address. If the controller IP address is not available, then this variable must be ommitted from the yaml. You can set this IP address after the controller deployment, by using the Cyperf Agent CLI.
    3. By default, agents will use the interface through which it can connect to the controller (or controller proxy) and select it as a management interface. The same interface will be used for test traffic also. If you need to select a management or test interface explicitly, use the following `env` variables. You can find these variables in the example yaml scripts as comments.

        ```
            #   name: AGENT_MANAGEMENT_INTERFACE
            #   value: "eth0"
            #   name: AGENT_TEST_INTERFACE
            #   value: "eth1"
        ```
    
    3. Update the docker network `driver` and `parent` as per your requirment. This is required when Client and Server containers use two differnt test network which are uplink with two different network interfaces. The networks should be connected alphabetically if the interfaces need to be in a specific order when mounted to the docker container.
    ```
            networks:
            #  cyperf-test-client-net:
            #    name: cyperf-test-client-net
            #    driver: macvlan
            #    driver_opts:
            #      parent: ens192
            #    ipam:
            #      config:
            #        - subnet: "172.32.12.0/22"
            #  cyperf-test-server-net:
            #    name: cyperf-test-server-net
            #    driver: macvlan
            #    driver_opts:
            #      parent: ens224
            #    ipam:
            #      config:
            #        - subnet: "10.10.10.0/24"
    ```
    4. Replace the place holder `AGENT_TAGS` with your preferred tags for identifying the agents as visible in the CyPerf Controller Agent Assignement dialog.
    5. When Client and Server containers are running in two different hosts, them Server container must do port mirroring with host for port 80 and 443.
    ```
            #     ports:
            #       - "80:80"
            #       - "443:443"
    ```
    5. Reserve and limit the memory and cpu resources for CyPerf Agent containers, depending on your requirement. 
        
        **_NOTE:_** For more information, see [Managing Resources for the CyPerf Agents](#managing-resources-for-the-cyperf-agents).
- Apply the conpose file.
  Download the docker compose file and place in the docker host. Change to the directory where docker compose file present.
    ```
    # For creating containers
    sudo docker compose up -d

    # For removing containers
    sudo docker compose down
    ```

## Managing Resources for the CyPerf Agents
- It is recommended to run the CyPerf Agent clients and servers in different docker host. The example manifests can achieve this by using the `client` section in one host and `server` section in other host.

- If you need to share the resources among multiple CyPerf Agents, (for example: when multiple Agent containers are runing in the same node) then use the following:

```
#    client:
#        mem_limit: "4g"
#        mem_reservation: "2g"
#        cpus: "2"
#        cpuset: "0-1"

#     server:
#        mem_limit: "4g"
#        mem_reservation: "2g"
#        cpus: "2"
#        cpuset: "2-3"
```
- If any specific command you need to execute during docker deployment, use below section
```
#     command:
#         - /bin/bash
#         - -c
#         - |
#           cyperfagent feature allow_mgmt_iface_for_test disable

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
- Make sure that the ingress security rules for CyPerf Controller [(or Contoller Proxy)](#general-prerequisites) allow port numbers 443 for the control subnet in which Agent and CyPerf Controller (or Controller Proxy) can communicate. 
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

4. CyPerf Container deployment workflow does not recommend using cyperagent CLI commands within the containers. container spawning command should supply all the environment variables for initializing the agent.

## Releases

- **CyPerf 6.0** - [December, 2024]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release6.0
        - public.ecr.aws/keysight/cyperf-agent:6.0.3.746

- **CyPerf 5.0** - [October, 2024]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release5.0
        - public.ecr.aws/keysight/cyperf-agent:5.0.3.723
<details>

<Summary> Old cyperf agent contriner release </summary>

- **CyPerf 4.0** - [July, 2024]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release4.0
        - public.ecr.aws/keysight/cyperf-agent:4.0.3.704

- **CyPerf 3.0** - [February, 2024]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release3.0
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.656
    
- **CyPerf 2.6** - [Oct, 2023]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release2.6
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.614

    - Change history:

- **CyPerf 2.5** - [July, 2023]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release2.5
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.575

    - Change history:

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
  </details>


# DPDK Support - CyPerf Agents in Container Environments


## Introduction
CyPerf Agent container supports DPDK. Below sections provides step by step guide.
- [Prerequisites](#prerequisites)
- [DPDK Host Preparation](#preparing-the-host-for-using-dpdk)
- [OS Type Qualified](#os-type-qualified)
- [Nic Type Qualified](#nic-type-qualified)
- [Dpdk Version Qualified](#dpdk-version-qualified)
- [DPDK Installation](#dpdk-installtion)
- [Hugepage Configuration](#hugepage-configuration)
- [Binding Interface](#binding-interface-for-dpdk)
- [Docker Container Deployment](#docker-container-deployment)
- [Known Limitation](#known-limitations-1)
## Prerequisites
To deploy a Keysight CyPerf agent container at Docker, you need the following:
1. Install Docker Engine in your desired host platform if not already. Refer [Install Docker Engine Server](https://docs.docker.com/engine/install/#server) for more details.
2. Pull CyPerf Agent Docker image from public ECR `public.ecr.aws/keysight/cyperf-agent-dpdk:latest` . Refer [Pull an image](https://docs.docker.com/engine/reference/commandline/pull/) for more details.

    ```
    sudo docker pull public.ecr.aws/keysight/cyperf-agent-dpdk:latest
    ```
    - **_NOTE:_**
    In case this public repository cannot be used to pull the CyPerf Agent Docker image, download it (.tar) [here](https://support.ixiacom.com/keysight-cyperf-70) and load it using the following command
    
        ```
        sudo docker load -i <downloaded tar file>
        ```
        The loaded image needs to be tagged properly and samples need to be updated accordingly.

3.  A CyPerf Controller that is already deployed and accessible from the Agent docker containers.  
    - **_NOTE:_** For information on how to deploy CyPerf Controller, see _Chapter 2_ of the [Cyperf User Guide](http://downloads.ixiacom.com/library/user_guides/KeysightCyPerf/2.1/CyPerf_UserGuide.pdf).

4.  A CyPerf Controller Proxy is required in hybrid deployment scenarios, where each of the distributed Agents cannot directly access the CyPerf Controller. For example, if the CyPerf Controller is deployed on premise and some CyPerf Agents are in the cloud, they can still communicate through a CyPerf Controller Proxy. In this case, the public IP address of the Controller Proxy is configured in the CyPerf Controller and Agents become available to the Controller by registering to the Controller Proxy.

5.  Make sure that the ingress security rules for CyPerf Controller (or Contoller Proxy) allow port numbers **443** for the control subnet in which Agent and CyPerf Controller (or Controller Proxy) can communicate.
     
## Preparing the Host for using DPDK
#### OS type qualified
As of now only Ubuntu 22.04 is qualified.
#### NIC type qualified
- Intel Corporation Ethernet Controller E810-C for QSFP (rev 02) - ice driver
- MT2892 Family [ConnectX-6 Dx] -  mlx5_core driver
#### DPDK version qualified
- 22.11

#### DPDK Installation
```shell
# Follow these steps at Ubutu 22.04 host

sudo su 
cd /root
apt install -y build-essential cmake
```
> [!NOTE] If python3 and python3-pip are already pre-installed in the OS, the below step is NOT REQUIRED.

> apt install -y python3 python3-pip

```shell
apt install -y libnuma-dev libpcap-dev 
pip3 install meson ninja pyelftools 
wget https://fast.dpdk.org/rel/dpdk-22.11.tar.xz 
tar -xvf ./dpdk-22.11.tar.xz 
cd dpdk-22.11 
meson build 
ninja -C build 
ninja -C build install 
cd /root 
git clone git://dpdk.org/dpdk-kmods 
cd dpdk-kmods/linux/igb_uio/ 
make clean && make 
modprobe uio 
insmod igb_uio.ko 
cd /root/dpdk-22.11 
./usertools/dpdk-devbind.py --status 
```

### Hugepage Configuration
```shell
cd /root/dpdk-22.11 
sudo ./usertools/dpdk-hugepages.py -p <Page size e.g. 1G> -r <Reserve memory e.g. 32G> -m

# Check the `hugepage` allocation
mount | grep huge

# `hugepage` cleanup and unmount
sudo ./usertools/dpdk-hugepages.py -u -c

```
### Binding Interface for DPDK
> [!NOTE] 
> Below `devbind` steps are required for Intel NIC only.

> For attaching MT2892 Family [ConnectX-6 Dx] refer
[Attach MT2892 Family [ConnectX-6 Dx] NIC to dpdk container](#attach-mt2892-family-connectx-6-dx-nic-to-dpdk-container)

```shell
#pci id and interface name mapping 
cd /root/dpdk-22.11
sudo ./usertools/dpdk-devbind.py -s

# It is recommended that vfio-pci be used as the kernel module for DPDK-bound ports in all cases

# Bind PCI device with ID
sudo ./usertools/dpdk-devbind.py --bind=vfio-pci <PCI ID> 
sudo ./usertools//dpdk-devbind.py --bind=vfio-pci <PCI ID>

```
### Docker container deployment

- Deploy both server and client agent containers on the same host
  > [!NOTE]
  Check details about the NUMA topology of the system before deployment using the below command. Also, decide which NUMA node will be used for each container. Based on the NUMA Node selection, set the hugepage size in bytes at the NUMA node's position for DPDK_HUGEMEM_ALLOCATION_SIZE parameter. Ex, if NUMA_NODE=0 selected, then set DPDK_HUGEMEM_ALLOCATION_SIZE="<Hugepage size in Byte>,0", on the other hand for NUMA_NODE=1, set DPDK_HUGEMEM_ALLOCATION_SIZE="0,<Hugepage size in Byte>".
  
  > Also, note down pci bus id of the relevant interfaces using `lspci` command.

  
>```shell
>    numactl --hardware
>```
#### **Deploy Client agent**

#### Create a local network
```shell
sudo docker network create --subnet=192.168.0.0/24 mgmt-network

sudo docker run -td --privileged --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ClientAgent --network=mgmt-network -e NUMA_NODE=<REPLACE WITH NUMA ID> -e AGENT_CPU_SET="<REPLACE WITH CPU IDS ASSOCIATED WITH PREVIOUS SPECIFIED NUMA ID>" -e DPDK_TEST_INTERFACE_PCI_ID=<PCI ID> -e DPDK_HUGEMEM_ALLOCATION_SIZE="0,<Hugepage size in Byte>" -e DPDK_HUGEMEM_ALLOCATION_PREFIX="dpdk_client" -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerClient" -v /lib/modules:/lib/modules -v /dev/hugepages:/dev/hugepages -v /dev/vfio:/dev/vfio -v  /lib/firmware:/lib/firmware public.ecr.aws/keysight/cyperf-agent-dpdk:latest
```
Example:
```shell
docker run -td --privileged --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ClientAgent --network=mgmt-network -e NUMA_NODE=1 -e AGENT_CPU_SET="1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59,61,63,65,67,69,71" -e DPDK_TEST_INTERFACE_PCI_ID=0000:ca:00.0 -e DPDK_HUGEMEM_ALLOCATION_SIZE="0,1000000" -e DPDK_HUGEMEM_ALLOCATION_PREFIX="dpdk_client" -e AGENT_CONTROLLER=10.39.34.33 -e AGENT_TAGS="AgentType=KBMLXDockerClient" -v /lib/modules:/lib/modules -v /dev/hugepages:/dev/hugepages -v /dev/vfio:/dev/vfio -v  /lib/firmware:/lib/firmware public.ecr.aws/keysight/cyperf-agent-dpdk:latest
```

#### **Deploy Server agent**
  Decide which NUMA node will be used for it. Based on NUMA ID selection, set hugepage size in bytes at NUMA id's position for DPDK_HUGEMEM_ALLOCATION_SIZE parameter.
```shell
sudo docker run -td --privileged --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ServerAgent --network=mgmt-network -e NUMA_NODE=<REPLACE WITH NUMA ID> -e AGENT_CPU_SET="<REPLACE WITH CPU IDS ASSOCIATED WITH PREVIOUS SPECIFIED NUMA ID>" -e DPDK_TEST_INTERFACE_PCI_ID=<PCI ID> -e DPDK_HUGEMEM_ALLOCATION_SIZE="<Hugepage size in Byte>,0" -e DPDK_HUGEMEM_ALLOCATION_PREFIX="dpdk_client" -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerServer" -v /lib/modules:/lib/modules -v /dev/hugepages:/dev/hugepages -v /dev/vfio:/dev/vfio -v  /lib/firmware:/lib/firmware public.ecr.aws/keysight/cyperf-agent-dpdk:latest
````

Example:
```shell
docker run -td --privileged --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ServerAgent --network=mgmt-network -e NUMA_NODE=0 -e AGENT_CPU_SET="0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58,60,62,64,66,68,70" -e DPDK_TEST_INTERFACE_PCI_ID=0000:17:00.0 -e DPDK_HUGEMEM_ALLOCATION_SIZE="1000000,0" -e DPDK_HUGEMEM_ALLOCATION_PREFIX="dpdk_server" -e AGENT_CONTROLLER=10.39.34.33 -e AGENT_TAGS="AgentType=KBMLXDockerServer" -v /lib/modules:/lib/modules -v /dev/hugepages:/dev/hugepages -v /dev/vfio:/dev/vfio -v  /lib/firmware:/lib/firmware public.ecr.aws/keysight/cyperf-agent-dpdk:latest

```

- Deploy both server and client agent containers on different host

#### Create a local network on a client host
```shell
sudo docker network create --subnet=192.168.0.0/24 mgmt-client-network

docker run -td --privileged --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ClientAgent --network=mgmt-client-network -e NUMA_NODE=1 -e AGENT_CPU_SET="1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59,61,63,65,67,69,71" -e DPDK_TEST_INTERFACE_PCI_ID=0000:ca:00.0 -e DPDK_HUGEMEM_ALLOCATION_SIZE="0,32000" -e DPDK_HUGEMEM_ALLOCATION_PREFIX="dpdk_client" -e AGENT_CONTROLLER=10.39.34.33 -e AGENT_TAGS="AgentType=KBMLXDockerClient" -v /lib/modules:/lib/modules -v /dev/hugepages:/dev/hugepages -v /dev/vfio:/dev/vfio -v  /lib/firmware:/lib/firmware public.ecr.aws/keysight/cyperf-agent-dpdk:latest
```
#### Create a local network on a server host
```shell
sudo docker network create --subnet=172.18.0.0/24 mgmt-server-network

sudo docker run -td --privileged --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ServerAgent --network=mgmt-server-network -e NUMA_NODE=<REPLACE WITH NUMA ID> -e AGENT_CPU_SET="<REPLACE WITH CPU IDS ASSOCIATED WITH PREVIOUS SPECIFIED NUMA ID>" -e DPDK_TEST_INTERFACE_PCI_ID=<PCI ID> -e DPDK_HUGEMEM_ALLOCATION_SIZE="<Hugepage size in Byte>,0" -e DPDK_HUGEMEM_ALLOCATION_PREFIX="dpdk_client" -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerServer" -v /lib/modules:/lib/modules -v /dev/hugepages:/dev/hugepages -v /dev/vfio:/dev/vfio -v  /lib/firmware:/lib/firmware public.ecr.aws/keysight/cyperf-agent-dpdk:latest

```

#### Attach MT2892 Family [ConnectX-6 Dx] NIC to dpdk container

```shell
# Use the following command to attach the interface to the dpdk container 

docker top <Container Name>| grep startup.sh | sed -n '1p' | awk '{ print $2 }' | xargs -I{} sudo ip link set <interface name> netns {}  

#To detach the interface use the following command 

docker top <Container Name> | grep startup.sh | sed -n '1p' | awk '{ print $2 }' | xargs -I{} sudo nsenter --target {} --net ip link set <interface name> netns 1 
```
### Known Limitations
DPDK Container with Single Interface as Management & Test  - Not Supported.
