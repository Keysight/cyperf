
# DPDK Support - CyPerf Agents in Container Environments

## Introduction
This guide provides step-by-step instructions for deploying CyPerf Agent containers with DPDK support for enhanced performance.

  1. [Supported Architectures](#supported-architectures)
  2. [Deploying Containers](#deploying-containers)
        - [Attaching Interface to Containers](#attaching-interface-to-containers)
        - [Detaching Interface from Containers](#detaching-interface-from-containers)
  3. [Removing Containers](#removing-containers)
  4. [Troubleshooting](#troubleshooting)
  5. [Known Limitations](#known-limitations)
  6. [Releases](#releases)

## Supported architectures
CyPerf Contailer image now support both [x86_64](#x86_64-cpu-architecture) and [aarch64](#aarch64-cpu-architecture) CPU architectures.

## x86_64 CPU architecture
### Prerequisites

- Install Docker Engine on the host if not already installed. For more details, refer to: [How to install Docker Engine](https://docs.docker.com/engine/install/#server).

- ### Supported Environments
    - Ubuntu 22.04 or higher, or Debian 12
    - Recommended NIC types:
        - Intel Corporation Ethernet Controller E810-C for QSFP (rev 02) - ice driver
        - MT2892 Family [ConnectX-6 Dx] or higher - mlx5_core driver

### Prepare the Host
Complete the following steps to prepare the host for configuring and deploying CyPerf containers:

- Pull the container image `public.ecr.aws/keysight/cyperf-agent-dpdk:latest`. For more details, refer to: [How to pull docker image](https://docs.docker.com/engine/reference/commandline/pull/).

    ```shell
    docker pull public.ecr.aws/keysight/cyperf-agent-dpdk:latest
    ```
    - **Note:** If the public repository is inaccessible, download the .tar file from the [CyPerf downloads page](https://support.ixiacom.com/keysight-cyperf-2600) and load it using the following command:
    
        ```shell
        docker load -i <downloaded tar file>
        ```
    
    - Verify the manually pulled image using `docker images` as shown below:
        ```shell
        ixia@cyperf:~$ docker images
        REPOSITORY                            TAG          IMAGE ID       CREATED       SIZE
        cyperf_agent_x86_64_ixstack_release   26.0.3.834   a8c4f5afd0e1   4 weeks ago   841MB
   ```

## aarch64 CPU architecture
### ARM Prerequisites

- An ARM-based system running a supported Linux distribution (Debian 12/Ubuntu 22.04 or later recommended).
- Docker Engine installed on the ARM host. Refer to [Install Docker Engine](https://docs.docker.com/engine/install/#server) for details.
- A CyPerf Controller that is already deployed and accessible from the Agent.

- ### Supported Environments
    - Ubuntu 22.04 or higher, or Debian 12
    - Recommended NIC types:
        - Intel Corporation Ethernet Controller E810-C for QSFP (rev 02) - ice driver
        - MT2892 Family [ConnectX-6 Dx] or higher - mlx5_core driver

### ARM Docker Image

CyPerf agent's ARM image can be pulled from `public.ecr.aws` using the following commad:

```shell
sudo docker pull public.ecr.aws/keysight/cyperf-agent-dpdk-aarch64:latest
```

This image is also available as a `.tar` file which can be downloaded from [Keysight Software Download Portal](https://support.ixiacom.com/keysight-cyperf-2601).

Load the .tar file using the following command:
```shell
sudo docker load -i cyperf_agent_aarch64_ixstack_release_<version>.tar
```

### ARM Known Limitations

## Workflow 

- Download the DPDK Usertools package (required for NIC inspection and hugepage allocation):
    ```shell
    wget https://fast.dpdk.org/rel/dpdk-25.11.tar.xz 
    tar -xvf ./dpdk-25.11.tar.xz
    #CyPerf currently supports DPDK 25.11 LTS
    ```
- DPDK runs on both single-node (SMP/UMA) and multi-node (NUMA) systems. On NUMA systems, performance can be improved by aligning CPU, memory, and NIC resources per node.

    Verify the system’s NUMA configuration using `lscpu | grep NUMA`

    Example output for a system with 2 NUMA nodes:
    ```shell
    NUMA node(s):                         2
    NUMA node0 CPU(s):                    0-31,64-95
    NUMA node1 CPU(s):                    32-63,96-127
    ```

## Configure the Host

- ### 1. Check interface status
    ```shell
    cd dpdk-25.11/
    ./usertools/dpdk-devbind.py --status 
    ```
    This tool lists all network devices available in the system along with their PCI ID, interface name, and the network driver. This information will be required later when deploying containers.
    - #### Example output for MLX NIC:
        ```shell
        Network devices using kernel driver
        ===================================
        # Format: <PCI ID> '<Device Name>' if=<Interface Name> drv=<Active Driver> unused=<Unused Drivers compatible with interface>
        0000:01:00.0 'MT2910 Family [ConnectX-7] 1021' if=enp1s0f0np0 drv=mlx5_core unused= 
        0000:01:00.1 'MT2910 Family [ConnectX-7] 1021' if=enp1s0f1np1 drv=mlx5_core unused= 
        0006:01:00.0 'MT2892 Family [ConnectX-6 Dx] 101d' if=enP6p1s0f0np0 drv=mlx5_core unused= 
        0006:01:00.1 'MT2892 Family [ConnectX-6 Dx] 101d' if=enP6p1s0f1np1 drv=mlx5_core unused= 
        ```
        **Note:** MLX NICs do not require additional driver configuration. Skip to [Hugepage Configuration](#2-hugepage-configuration).

    - #### Example output for Intel NIC:
        ```shell
        Network devices using kernel driver
        ===================================
        # Format: <PCI ID> '<Device Name>' if=<Interface Name> drv=<Active Driver> unused=<Unused Drivers compatible with interface>
        0000:50:00.0 'Ethernet Controller E810-C for QSFP 1592' if=ens7np0 drv=ice unused=vfio-pci 
        0000:50:00.1 'Ethernet Controller E810-C for QSFP 1592' if=ens7np1 drv=ice unused=vfio-pci 
        0000:53:00.0 'Ethernet Controller E810-C for QSFP 1592' if=ens15np0 drv=ice unused=vfio-pci 
        0000:53:00.1 'Ethernet Controller E810-C for QSFP 1592' if=ens15np1 drv=ice unused=vfio-pci 
        ```

        **Note:** Intel NICs require the `vfio-pci` driver for DPDK. CyPerf handles the binding automatically, but the `vfio-pci` module must be loaded on the host before deployment.

        - Verify `vfio-pci` is loaded by running the following command on the host:
            ```shell
            lsmod | grep vfio-pci
            ```
            If not loaded, modprobe it with:
            ```shell
            sudo modprobe vfio-pci
            ```
            Ubuntu and Debian distributions ship with vfio-pci available by default. Other operating system distributions may require installing `vfio-pci` manually.
        - Additionally, to use VFIO, both the kernel and BIOS must support and be configured to use IO virtualization (such as Intel® VT-d).
            
            In most cases, specifying `iommu=on` as a kernel parameter in `/etc/default/grub` should be sufficient to configure the Linux kernel to use IOMMU.
            
            To know more about `vfio` and `iommu`, refer to the [official DPDK guide](https://doc.dpdk.org/guides/linux_gsg/linux_drivers.html#vfio).


- ### 2. Hugepage Configuration
    - Ubuntu and Debian distributions come with 2M hugepages mounted by default. However, 1G hugepages are recommended for DPDK as they significantly improve performance. 
    
        Set up 1G hugepages using the DPDK usertools:    
        ```shell
        cd dpdk-25.11/

        # Reset existing hugepages
        sudo ./usertools/dpdk-hugepages.py -u -c -s

        # Check per-NUMA memory
        numactl --hardware

        # Hugepages are allocated uniformly across NUMA nodes.
        # Use 50% of the memory of the node with lower memory for all nodes.
        # Example: Node 0 = 128G, Node 1 = 64G → reserve 32G per node.

        # Reserve 1G hugepages (32G per node in this example)
        sudo ./usertools/dpdk-hugepages.py -p 1G -r 32G -m -s

        # Verify (expect pagesize=1024M)
        mount | grep huge
        ```
    - In case `mount` shows pagesize=2M, Follow the steps mentioned in [Troubleshooting](#troubleshooting).
    - **Note:** The hugepage configuration shown above must be repeated after every reboot. Alternatively, configure hugepages permanently by adding `hugepagesz=1G hugepages=<number>` to the kernel boot parameters in `/etc/default/grub`.

- ### 3. Interface and NUMA Node Mapping

    Before deploying containers, identify the interface name, PCI ID, and NUMA node for each interface:

    - To list available interfaces and their PCI IDs, refer to [Check Interface Status](#1-check-interface-status). 
    - Alternatively, use `ethtool -i <interface name>` to retrieve the bus-info (PCI ID) of a specific interface:

        **Example:**
        ```shell
        ixia@cyperf:~$ ethtool -i enP4p1s0f0np0
        driver: mlx5_core
        ...
        bus-info: 0004:01:00.0
        ...
        # bus-info is PCI ID
        ```

    - Identify the NUMA node the interface is connected to:
        ```shell
        cat /sys/class/net/<interface name>/device/numa_node
        ```
        **Example:**
        ```shell
        ixia@cyperf:~$ cat /sys/class/net/enP4p1s0f0np0/device/numa_node 
        0 # This is the NUMA node ID
        ```
    
## Deploying Containers

- Before deploying containers, ensure the host is configured correctly and hugepages are set up as described in [Configure the Host](#configure-the-host).

- Ensure a CyPerf Controller or Controller-proxy is already deployed and running, and is accessible from the host.

- **NUMA Node Selection:**

    Check the NUMA topology of the system using `numactl --hardware` and decide which NUMA node to use for each container.
    
    While deploying the containers, set the `DPDK_HUGEMEM_ALLOCATION_SIZE` parameter based on the selected NUMA node as shown below:
    - For `NUMA_NODE=0`: set `DPDK_HUGEMEM_ALLOCATION_SIZE="<Hugepage size in MB>,0"`
    - For `NUMA_NODE=1`: set `DPDK_HUGEMEM_ALLOCATION_SIZE="0,<Hugepage size in MB>"`
    - For single node systems, i.e, `NUMA_NODE=0`: set `DPDK_HUGEMEM_ALLOCATION_SIZE="<Hugepage size in MB>"`
   
- ### Deploying Multiple Agents on the Same Host
  
    - #### 1. Create a Local Management Network
        This network will be used by the containers to communicate with CyPerf Controller.
        ```shell
        docker network create --subnet=192.168.0.0/24 mgmt-network
        ```
    - #### 2. Deploy Containers
        ```Shell
        docker run -td --privileged \
        --cap-add=NET_ADMIN \
        --cap-add=IPC_LOCK \
        --cap-add=NET_RAW \
        --name "<Agent Container Name>" \
        --network=mgmt-network \
        -e NUMA_NODE="<NUMA NODE ID>" \
        -e AGENT_CPU_SET="<CPU IDS ASSOCIATED WITH ABOVE MENTIONED NUMA NODE>" \
        -e DPDK_TEST_INTERFACE_PCI_ID="<PCI ID>" \
        -e DPDK_HUGEMEM_ALLOCATION_SIZE="0,<Hugepage size in MB>" \
        -e DPDK_HUGEMEM_ALLOCATION_PREFIX="<Any string unique to each container>" \
        -e AGENT_CONTROLLER="<CONTROLLER IP>" \
        -e AGENT_TAGS="<KEY:VALUE pair for identification from UI>" \
        -v /lib/modules:/lib/modules \
        -v /dev:/dev \
        -v  /lib/firmware:/lib/firmware \
        <Container Image:tag>
        ```
     - **Example:**
        ```shell
        # Client side container
        docker run -td --privileged \
        --cap-add=NET_ADMIN \
        --cap-add=IPC_LOCK \
        --cap-add=NET_RAW \
        --name "ClientAgent1" \
        --network=mgmt-network \
        -e NUMA_NODE="1" \
        -e AGENT_CPU_SET="1,3,5,7,9,11,13,15" \
        -e DPDK_TEST_INTERFACE_PCI_ID="0000:ca:00.0" \
        -e DPDK_HUGEMEM_ALLOCATION_SIZE="0,32000" \
        -e DPDK_HUGEMEM_ALLOCATION_PREFIX="dpdk_client1" \
        -e AGENT_CONTROLLER="10.39.34.33" \
        -e AGENT_TAGS="AgentType=MLXDockerClient" \
        -v /lib/modules:/lib/modules \
        -v /dev:/dev \
        -v /lib/firmware:/lib/firmware \
        public.ecr.aws/keysight/cyperf-agent-dpdk:latest
        ```
        ```shell
        # Server side container
        docker run -td --privileged \
        --cap-add=NET_ADMIN \
        --cap-add=IPC_LOCK \
        --cap-add=NET_RAW \
        --name "ServerAgent1" \
        --network=mgmt-network \
        -e NUMA_NODE="0" \
        -e AGENT_CPU_SET="0,2,4,6,8,10,12,14" \
        -e DPDK_TEST_INTERFACE_PCI_ID="0000:17:00.0" \
        -e DPDK_HUGEMEM_ALLOCATION_SIZE="32000,0" \
        -e DPDK_HUGEMEM_ALLOCATION_PREFIX="dpdk_server1" \
        -e AGENT_CONTROLLER="10.39.34.33" \
        -e AGENT_TAGS="AgentType=MLXDockerServer" \
        -v /lib/modules:/lib/modules \
        -v /dev:/dev \
        -v  /lib/firmware:/lib/firmware \
        public.ecr.aws/keysight/cyperf-agent-dpdk:latest
        ```

- ### Deploying Agents on Different Hosts
    The deployment steps are the same as above. However, the management network (specified with the `--network` parameter) for each container must use a different subnet to avoid duplicate management IP addresses. Unique management IP addresses are required because CyPerf identifies agents based on this address.

- ### Attaching Interface to Containers

    - Use the following command to attach a network interface to the container:
        ```shell
        docker top <Container Name>| grep startup.sh | sed -n '1p' | awk '{ print $2 }' | xargs -I{} sudo ip link set <interface name> netns {}  
        ```

        Verify the interface was added to the container:
        ```shell
        docker exec -it <Container Name> ifconfig -a | grep <interface name>
        ```
- ### Detaching Interface from Containers

    > **Note:** Detaching the interface is only required for Mellanox (MLX) drivers. Other NICs like Intel E810 do not require this step. Removing the container correctly (as shown in the next section) will automatically return the interface to the host.

    - To detach an interface from a container:
        ```shell
        docker top <Container Name> | grep startup.sh | sed -n '1p' | awk '{ print $2 }' | xargs -I{} sudo nsenter --target {} --net ip link set <interface name> netns 1 
        ```

## Removing Containers

- Execute the following commands in the specified order to stop and remove containers gracefully while cleaning up hugepage allocations. For Intel NICs, these steps will also return the attached test interface to the host OS.

    ```shell
    docker container stop <container name>
    docker container rm -v <container name>
    ```

## Troubleshooting

- If hugepage allocation fails, clean up any residual hugepages using the following steps, then retry the [configuration](#2-hugepage-configuration):
    ```shell
    # Clean up hugepages
    sudo ./usertools/dpdk-hugepages.py -c -s
    # Unmount hugepages
    sudo ./usertools/dpdk-hugepages.py -u -s
    ``` 
- Misconfiguring the interface, NUMA node, CPUs, or hugepages will significantly impact performance. Ensure the interface-to-NUMA-node mapping is correct during deployment.
- For MLX NICs, if the interface is not detached before the container is stopped and removed, it may take some time to return to the host OS. This is expected behavior.
- For Intel NICs, if the container is not stopped gracefully, the interface will not return to the host. To recover the interface, use the following command:
    ```shell
    cd dpdk-22.11/
    ./usertools/dpdk-devbind.py -b ice <PCI ID of interface>

    # This rebinds the interface to the ice kernel driver, making it visible to the host OS.
    ```

## Known Limitations
- Using a single interface for both management and test traffic is not supported.
- In the Controller UI, DPDK may show as enabled while the "Supported" field displays "No".

## Releases

- **CyPerf 26.0.1** - [August, 2026]
    - Image URI:
        - public.ecr.aws/keysight/cyperf-agent-dpdk:release26.0.1
        - public.ecr.aws/keysight/cyperf-agent-dpdk:26.0.X.X
        - public.ecr.aws/keysight/cyperf-agent-dpdk-aarch64:26.0.X.X

- **CyPerf 26.0.0** - [March, 2026]
    - Image URI:
        - public.ecr.aws/keysight/cyperf-agent-dpdk:release26.0.0
        - public.ecr.aws/keysight/cyperf-agent-dpdk:26.0.3.834

- **CyPerf 7.0** - [July, 2025]
    - Image URI:
        - public.ecr.aws/keysight/cyperf-agent-dpdk:release7.0
        - public.ecr.aws/keysight/cyperf-agent-dpdk:7.0.3.807
