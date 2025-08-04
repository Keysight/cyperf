# Running CyPerf agents using separate management and test interface

## General Prerequisites 
- A kubernetes cluster is prepared on the host. For general information on K8s cluster deployment, see [Kubernetes Documentation](https://kubernetes.io/docs/setup/).
- For using DPDK, install DPDK on the host where CyPerf agents will be deployed. Follow the steps mentioned in [DPDK Installation](../../containers/dpdk/README.md#dpdk-installation) section.

### Install required CNIs

Both the CNIs mentioned below must be installed for supporting separate managment and test interfaces from agent pods.

- **Calico:**   
    - [cni_examples/onprem-calico.yaml](../cni_examples/onprem-calico.yaml) - [ [source](https://docs.projectcalico.org/manifests/calico.yaml) ]    
    - This example modifies the source by changing the mode of enabling IPIP tunneling thorugh `env CALICO_IPV4POOL_IPIP` from `"Always"` to `"CrossSubnet"`. You can use this to achieve higher performance when test traffic is flowing in the same subnet.  
```shell
kubectl apply -f onprem-calico.yaml
```
- **Multus:**

```shell
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
```

---

### Configure Hugepages (required for DPDK only)


On the hosts where CyPerf agents will be deployed, configure hugepages as shown in [hugepage configuration](../../containers/dpdk/README.md#hugepage-configuration), and restart `kubelet`.

```bash
sudo systemctl restart kubelet
```

Check:

```bash
kubectl describe node <node-name>
```

Look for entries like:

```yaml
hugepages-1Gi: 32Gi
```

---

### Deploy the Agents

Now start with one of the example YAML templates depending on whether DPDK is enabled or not, and replace the right values for the parameters before applying.

### Refer to these links for the YAML files and their parameter descriptions below: 
---
🔗  [CyPerf agents with separate test interface using dpdk](agent_examples/multus_multi_iface_dpdk.yaml)

#### Parameter Descriptions for DPDK: 
- __AGENT_CONTROLLER__: IP address of the CyPerf controller.
- __AGENT_TAGS__: (Optional) Labels used to tag agents to be shown in CyPerf UI (e.g. attack-client, application-server, etc.).
- __DPDK_TEST_INTERFACE_PCI_ID__: PCI ID of the NIC. 
- __NUMA_NODE__: NUMA node ID where the agent will run. 
- __AGENT_CPU_SET__: Selected CPU cores to use, from the CPU list retrieved earlier. 
- __DPDK_HUGEMEM_ALLOCATION_SIZE__: Hugepage size for the selected NUMA node.
    - For __NUMA_NODE=0__: "<size_in_Mbytes>,0"
    - For __NUMA_NODE=1__: "0,<size_in_Mbytes>" 
- __DPDK_HUGEMEM_ALLOCATION_PREFIX__: Any unique name for each container on this host (e.g. container1, container2 or agent1, agent2) to be used internally by DPDK. 

---

🔗 [CyPerf agents with separate test interface non dpdk](agent_examples/multus_multi_iface.yaml)

#### Parameter Descriptions for non DPDK: 
- __AGENT_CONTROLLER__: IP address of the CyPerf controller.
- __AGENT_TAGS__: (Optional) Labels used to tag agents 	to be shown in CyPerf UI (e.g. attack-client, application-server, etc.). 
- __AGENT_TEST_INTERFACE__: Interface name
---

#### Now, deploy the CyPerf agents using the following commands

```bash
kubectl apply -f multus_multi_iface_dpdk.yaml
```
Or
```bash
kubectl apply -f multus_multi_iface.yaml
```
