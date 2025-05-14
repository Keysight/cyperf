
# DPDK Support - CyPerf Agents in Container Environments

## Introduction
CyPerf Agent container supports DPDK. Below sections provides step by step guide.

  - [Prerequisites](#prerequisites)
  - [Prepare host for CyPerf Agent DPDK containers](#prepare-host-for-cyperf-agent-dpdk-containers)
  - [Configure host for CyPerf DPDK containers](#configure-host-for-cyperf-dpdk-containers)
  - [Removing Docker containers](#removing-docker-containers)
  - [Troubleshooting](#troubleshooting)
  - [Known Limitations](#known-limitations)

## Prerequisites
### Supported Enviornments
- Qualified on Ubuntu 22.04 host with DPDK version 22.11
- Recomended NIC types are
    - Intel Corporation Ethernet Controller E810-C for QSFP (rev 02) - ice driver
    - MT2892 Family [ConnectX-6 Dx] -  mlx5_core driver

### Prepare host for CyPerf Agent DPDK containers
User needs to carryout following steps to get the host ready
- Install Docker on the host. For detail steps click [Install Docker][1](../README.md/#general-prerequisites).

- Install DPDK. For detail steps click [Install DPDK](#dpdk-installation)

### Configure host for CyPerf DPDK containers
 - NUMA (Non-Uniform Memory Access) architecture is mandatory for optimal DPDK performance. Ensure that your system is configured with NUMA nodes.
      Verify NUMA Nodes:
    ```shell
        lscpu | grep NUMA
    ```
- Configure `hugepage`. Check [hugepage configuration](#hugepage-configuration)
- Take note of NUMA node and inteface associate with that. Check [Interface to NUMA mapping](#interface-and-numa-node-mapping)
- Bind Test interface. Check [bind interface](#binding-interface-for-dpdk)
  
### Container Deployment
- CyPerf Controller or Controller-proxy must pre exists. For detail description check [here][4,5,6](../README.md/#general-prerequisites).
- Deploy DPDK docker conainer. Check [container deployment](#docker-container-deployment)

### DPDK Installation
```shell
# Follow these steps at Ubuntu 22.04 host

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

# `hugepage` cleanup and unmount
sudo ./usertools/dpdk-hugepages.py -u -c -s

sudo ./usertools/dpdk-hugepages.py -p <Page size e.g. 1G> -r <Reserve memory e.g. 32G> -m -s

# Check the `hugepage` allocation
mount | grep huge

```
### Interface and NUMA Node mapping

 The following steps are required to identifying the interface, its PCI ID, and its NUMA node binding.

- Fetch the Interface name that need to be use
- Fetch the bus-info/PCI ID of that interface using  
  ```shell
  ethtool -i <interface name>
  ``` 
- Identify which NUMA node the interface is connected
   ```shell
   cat /sys/class/net/<interface name>/device/numa_node
   ```
  
### Docker container deployment
>[!Note]
Check details about the NUMA topology of the system before deployment using the below command. Also, decide which NUMA node will be used for each container. Based on the NUMA Node selection, set the hugepage size in bytes at the NUMA node's position for DPDK_HUGEMEM_ALLOCATION_SIZE parameter. Ex, if NUMA_NODE=0 selected, then set DPDK_HUGEMEM_ALLOCATION_SIZE="<Hugepage size in Byte>,0", on the other hand for NUMA_NODE=1, set DPDK_HUGEMEM_ALLOCATION_SIZE="0,<Hugepage size in Byte>".
    
>```shell
>    numactl --hardware
>```

#### Deploy multiple DPDK containers agents on the same host:
  
#### Create a local management network
```shell
sudo docker network create --subnet=192.168.0.0/24 mgmt-network
```
#### Deploy Containers
```Shell
sudo docker run -td --privileged --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name <DPDK Agent Container Name> --network=mgmt-network -e NUMA_NODE=<REPLACE WITH NUMA ID> -e AGENT_CPU_SET="<REPLACE WITH CPU IDS ASSOCIATED WITH PREVIOUS SPECIFIED NUMA ID>" -e DPDK_TEST_INTERFACE_PCI_ID=<PCI ID> -e DPDK_HUGEMEM_ALLOCATION_SIZE="0,<Hugepage size in Byte>" -e DPDK_HUGEMEM_ALLOCATION_PREFIX="<Unique prefix >" -e AGENT_CONTROLLER=<REPLACE WITH CONTROLLER IP> -e AGENT_TAGS="AgentType=DockerClient" -v /lib/modules:/lib/modules -v /dev:/dev -v  /lib/firmware:/lib/firmware <DPDK Agent Container Image>
```
Example:
```shell
docker run -td --privileged --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ClientAgent1 --network=mgmt-network -e NUMA_NODE=1 -e AGENT_CPU_SET="1,3,5,7,9,11,13,15" -e DPDK_TEST_INTERFACE_PCI_ID=0000:ca:00.0 -e DPDK_HUGEMEM_ALLOCATION_SIZE="0,1000" -e DPDK_HUGEMEM_ALLOCATION_PREFIX="dpdk_client1" -e AGENT_CONTROLLER=10.39.34.33 -e AGENT_TAGS="AgentType=KBMLXDockerClient" -v /lib/modules:/lib/modules -v /dev:/dev -v /lib/firmware:/lib/firmware <DPDK Agent Container Image>
```

Example:
```shell
docker run -td --privileged --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ServerAgent1 --network=mgmt-network -e NUMA_NODE=0 -e AGENT_CPU_SET="0,2,4,6,8,10,12,14" -e DPDK_TEST_INTERFACE_PCI_ID=0000:17:00.0 -e DPDK_HUGEMEM_ALLOCATION_SIZE="10000,0" -e DPDK_HUGEMEM_ALLOCATION_PREFIX="dpdk_server1" -e AGENT_CONTROLLER=10.39.34.33 -e AGENT_TAGS="AgentType=KBMLXDockerServer" -v /lib/modules:/lib/modules -v /dev:/dev -v  /lib/firmware:/lib/firmware <DPDK Agent Container Image>

```

#### Deploy DPDK agent containers on different host
Deployment steps are the same as above. But the management network, specified with `--network` parameter, for each container, must be from a different subnet, otherwise, there is a possibility of getting the same management IP for different containers.

### Binding Interface for DPDK

- For Intel NIC

```shell
#pci id and interface name mapping 
cd /root/dpdk-22.11
sudo ./usertools/dpdk-devbind.py -s

# It is recommended that vfio-pci be used as the kernel module for DPDK-bound ports in all cases

# Bind PCI device with ID
sudo ./usertools/dpdk-devbind.py --bind=vfio-pci <PCI ID> 
sudo ./usertools//dpdk-devbind.py --bind=vfio-pci <PCI ID>

```

- For MT2892 Family [ConnectX-6 Dx] NIC

```shell
# Use the following command to attach the interface to the dpdk container 

docker top <Container Name>| grep startup.sh | sed -n '1p' | awk '{ print $2 }' | xargs -I{} sudo ip link set <interface name> netns {}  

#  check whether the interface was added to the container
docker exec -it <Container Name> ifconfig -a | grep <interface name>
  
#To detach the interface use the following command 

docker top <Container Name> | grep startup.sh | sed -n '1p' | awk '{ print $2 }' | xargs -I{} sudo nsenter --target {} --net ip link set <interface name> netns 1 
```
### Removing Docker containers
>[!Note] These steps are are also required to clean up hugepages allocation
```shell
docker container stop <container name>
docker container rm -v <container name>
```
### Troubleshooting
 

### Known Limitations
- DPDK Container with Single Interface as Management & Test  - Not supported.
- Automatic MAC not supported. User need to disable Automatic mac in the Ethernet Range section of all Network segments.
- In controller UI, DPDK is shown as enabled but Supported section shows "No".
