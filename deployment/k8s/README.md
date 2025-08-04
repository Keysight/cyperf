# CyPerf Agents in Kubernetes (K8s) environments
## Introduction
This document describes how you can deploy the Keysight CyPerf agents inside Kubernetes clusters. The Following sections contain information about the prerequisites for deployments and also explain the modifications that are required in the client and server manifest yaml examples. Some modifications are mandatory for updating the manifests for specific user environment whereas some of them are optional and depend on different types of deployment scenarios.

The following section describes the steps for using same interface for both management and test traffic.

> ### For running CyPerf agents using separate management and test interface, please switch to the other [page](multus/README.md). This page also describes [how to enable DPDK](multus/README.md) for CyPerf agents.


- [General Prerequisites](#general-prerequisites)
- [Workflow](#workflow)
    - [Example Manifests](#example-manifests)
- [Deployment in **AWS EKS or AZURE AKS**](#deployment-in-aws-eks-or-azure-aks)
- [Deployment in **On-Premise K8s Cluster**](#deployment-in-on-premise-k8s-cluster)
- [Managing Resources for the CyPerf Agents](#managing-resources-for-the-cyperf-agents)
- [Supported CNIs](#supported-cnis)
- [Test Configuration Checklist](#test-configuration-checklist)
- [Troubleshooting](#troubleshooting)


## General Prerequisites
To deploy a Keysight CyPerf agent inside Kubernetes, you need the following:
1. You can use the *CyPerf Agents in both* **_on-premise_** *K8s cluster (For example: **nodes in VMs on ESXi host**) and in* **_cloud_** *(For example: nodes in **_AWS EKS_***).
    
    - K8s version 1.27 is recommended for On-Premises K8s, EKS and AKS Clusters
    
2. A kubernetes cluster along with a containerzied device under test (DUT) that is already deployed in the same cluster. 
  
    - **_NOTE:_** For more information on how to deploy the DUT in a K8s cluster, follow the instructions provided in the [Cyperf Deployment Guide](http://downloads.ixiacom.com/library/user_guides/KeysightCyPerf/2.1/CyPerf_Deployment_Guide.pdf) for a specific DUT . For general information on K8s cluster deployment, see [Kubernetes Documentation](https://kubernetes.io/docs/setup/).

3.  A CyPerf Controller that is already deployed and accessible from the nodes inside the kubernetes cluster.  
    - **_NOTE:_** For information on how to deploy CyPerf Controller, see _Chapter 2_ of the [Cyperf User Guide](http://downloads.ixiacom.com/library/user_guides/KeysightCyPerf/2.1/CyPerf_UserGuide.pdf).

3. A CyPerf Controller Proxy is required in hybrid deployment scenarios, where each of the distributed Agents cannot directly access the CyPerf Controller. For example, if the CyPerf Controller is deployed on premise and some CyPerf Agents are in the cloud, they can still communicate through a CyPerf Controller Proxy. In this case, the public IP address of the Controller Proxy is configured in the CyPerf Controller and Agents become available to the Controller by registering to the Controller Proxy.

4.  Make sure that the ingress security rules for CyPerf Controller (or Contoller Proxy) allows port numbers **443** for the control subnet in which Agent and CyPerf Controller (or Controller Proxy) can communicate.
5.  Place holder container image URL for the CyPerf Agent container. The example manifests use the latest image URL from Keysight CyPerf's public container repository in ECR. For specific versions, use the CyPerf Agent's container image URL. This ECR Public image URL needs to be accessible from the test environment, for example: _the cluster nodes_.
6.  Assign `agenttype=client` label to the nodes if you want to deploy CyPerf Agents as test traffic to initiate the clients and assign `agenttype=server` label to the nodes if you want the CyPerf Agents to simulate the test servers.    
    ```
    kubectl get nodes --show-labels

    kubectl label nodes <your-node-name> agenttype=client
    kubectl label nodes <your-node-name> agenttype=server
    ```
## Workflow
To test a device or a service that is running inside a K8s cluster, do the following:
- Select and start with a cluster that is already deployed. The containerzied device under test (DUT) is also expected to be deployed in the same cluster.
- There must be a CyPerf Controller already deployed as well. Once the CyPerf Agents are deployed in the cluster following the steps described below, they will automatically get registered to CyPerf Controller and become ready to use.
- A CyPerf Controller Proxy is required in hybrid deployment scenarios, where each of the distributed Agents cannot directly access the CyPerf Controller. For example, if the CyPerf Controller is deployed on premise and some CyPerf Agents are in the cloud, they can still communicate through a CyPerf Controller Proxy. In this case, the public IP address of the Controller Proxy is configured in the CyPerf Controller and Agents become available to the Controller by registering to the Controller Proxy.
- Introduce the CyPerf Agent as a client or a server or as both that is running inside the cluster. This can be achieved by applying the [example manifests](#example-manifests). These manifests will require a few modifications for adjusting to specific delpoyment scenario. 
    - **_NOTE:_** Agents will be visible (by their tags and IP addresses) in the _Agent Assignment_ dialog.
- Create a test using CyPerf Controller UI. Select Agents for respective _Network Segments_ and configure appropriate properties in the _DUT Network->Configure DUT_ page in the UI before running the test. 
  - **_NOTE:_** For more information, see _Chapter 3_ of the [Cyperf User Guide](http://downloads.ixiacom.com/library/user_guides/KeysightCyPerf/2.1/CyPerf_UserGuide.pdf).

###  **Example Manifests**
- Client: [agent_examples/cyperf-agent-client.yaml](agent_examples/cyperf-agent-client.yaml) 
- Server: [agent_examples/cyperf-agent-server.yaml](agent_examples/cyperf-agent-server.yaml)        

- Modifications that are required to delpoy a CyPerf Agent, are as follows:
    1. Replace the place holder container `image` URL with the specific version, that you want to use for the CyPerf Agent container. You can get this URL from [Keysight software download portal](https://support.ixiacom.com/keysight-cyperf-software-downloads-documentation).
    2. Replace the place holder `AGENT_CONTROLLER` value with your CyPerf Controller IP address. If the controller IP address is not available, then this variable must be ommitted from the yaml. You can set this IP address after the controller deployment, by using the Cyperf Agent CLI.
    3. By default, agents will use the interface through which it can connect to the controller (or controller proxy) and select it as a management interface. The same interface will be used for test traffic also. If you need to select a management or test interface explicitly, use the following `env` variables. You can find these variables in the example yaml scripts as comments.

        ```
            #   name: AGENT_MANAGEMENT_INTERFACE
            #   value: "eth0"
            #   name: AGENT_TEST_INTERFACE
            #   value: "eth1"
        ```
    
    3. Replace the place holder `AGENT_TAGS` with your preferred tags for identifying the agents as visible in the CyPerf Controller Agent Assignement dialog.
    4. Update the `nodeSelector` rule according to your preference, if required. The example manifests assume that the `agenttype=client`and `agenttype=server` labels are already assigned to the chosen worker nodes, so that the CyPerf Agent client and server pods are not deployed in the same node.
    5. Review the server manifest yaml to decide which `type` of `Service` is required in your use case (for example: `ClusterIP`, `NodePort`, and etc.) and change accordingly.
    6. Decide the number of replicas that are required to start with the CyPerf Agent client and server pods and modify the count accordingly.
    7. Reserve and limit the memory and cpu resources for CyPerf Agent pods, depending on your requirement. 
        
        **_NOTE:_** For more information, see [Managing Resources for the CyPerf Agents](#managing-resources-for-the-cyperf-agents).
- Apply the manifests.
    ```
    kubectl apply -f cyperf-agent-client.yaml

    kubectl apply -f cyperf-agent-server.yaml

    ```
- You may scale the deployments later with the desired number of replicas.
    ```
    kubectl scale deployment.v1.apps/cyperf-agent-server-deployment --replicas=2
    
    ```
- If you need to increase the number of the server agent replica while a test is running, enable the `readinessProbe` so that the test traffic is forwarded to a server agent when it is ready.
    ```
        readinessProbe:
            httpGet:
                path: /CyPerfHTTPHealthCheck
                port: 80
            periodSeconds: 5
    ```
## Deployment in **AWS EKS or AZURE AKS**
### Prerequisites
1. All the general prerequisites that are mentioned in the [General Prerequisites](#general-prerequisites) section. 
2. For AWS EKS, select a K8s cluster in EKS which can be deployed by using 'eksctl' or any other methods that are described in the [Getting started with Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html).
3. For AZURE AKS, select a K8s cluster in AKS which can be deployed by using 'az aks' or any other methods that are described in [Getting started with Azure AKS](https://docs.microsoft.com/en-us/azure/aks/).

    **_NOTE:_** Along with all the general prerequisites, the following are also required.
    - CyPerf Agents outside the EKS, which can simulate clients, for initiating the traffic flows.  
    _These client agents can also run as pods in an on-premise kubernetes cluster or on the agents that are running in VM or COTS hardware._
    - Collect the FQDN (Fully qualified domain name) or the public IP address for the DUT, which needs to be configured in the CyPerf Controller's _DUT Network_.   
    - If FQDN is used for the DUT, that needs to be resolved by the CyPerf client Agents. Configure a _Name Server_ IP address in the CyPerf Contoller's _Configure Network->DNS Resolver_ page for clients' _Network Segments_.


### Deployment of CyPerf
You can deploy in AWS EKS or in AZURE AKS in the following two ways:
#### 1. _**East-West** traffic between the pods and the internal container services and the workloads in **Amazon Elastic Kubernetes Service (EKS) or Azure Kubernetes Service (AKS)** environments._

- Deploy both client and server for CyPerf Agents.
- Collect the values by checking the pod or service properties respectively, if the CyPerf Agent servers are required to be configured in the DUT by using the `podIP` or the `ClusterIP` of the service.
    ```
    kubectl get pods -l run=cyperf-agent-server -o wide

    kubectl get svc cyperf-agent-service -o wide
    ```
- Configure a _Name Server_ IP address in CyPerf Contoller's _Configure Network->DNS Resolver_ page for clients' _Network Segments_, if FQDN is used for the DUT. For example: if the cluster is using CoreDNS cluster addon (application name kube-dns), you can collect the DNS server IP address by using the following command.
    ```
    kubectl get services kube-dns --namespace=kube-system
    ```        

#### 2. _**North-South** traffic that is destined to the container services and the workloads in **Amazon Elastic Kubernetes Service (EKS) or Azure Kubernetes Service (AKS)** environments._
- Deploy CyPerf Agent as server(s) behind the DUT.
- Collect the values by checking the pod or service properties respectively, if the CyPerf Agent servers are required to be configured in the DUT by using the `podIP` or the `ClusterIP` of the service. 
    ``` 
    kubectl get pods -l run=cyperf-agent-server -o wide

    kubectl get svc cyperf-agent-service -o wide
    ```  
    **_NOTE:_** When traffic source (Client Agent) is outside of the cluster
    - change ServiceType to NodePort in the server manifest
    - set NodePort service port to any port in the range 30000-32767
    - in the DUT section of CyPerf config, set the master node's IP of cluster where the server is deployed, 
    - in the CyPerf test config, "Traffic destination port" should be same as the port which is set as NodePort service port in the manifest

## Deployment in **On-Premise K8s Cluster**
### For running CyPerf agents using separate test interface or DPDK test interface please follow this [link](multus/README.md).
### Prerequisites
1. All the general prerequisites that are mentioned in the [General Prerequisites](#general-prerequisites) section.
    
    **_NOTE:_** Along with all the general prerequisites, the following are also required.

    - CyPerf Agents outside the cluster which are supposed to be simulating clients to initiate traffic flows that are destined to the DUT.
    _These client agents can also run as pods in an on-premise kubernetes cluster or as agents running in a VM or COTS hardware._
    - Collect the FQDN or the public IP address for the DUT, which needs to be configured in the CyPerf Controller's DUT Network.
    - If FQDN is used for the DUT, this needs to be resolved by the CyPerf client Agents. Configure a _Name Server_ IP address in CyPerf Contoller's _Configure Network->DNS Resolver page for clients' Network Segments_.

### Deployment of CyPerf
You can deploy in On-Premise K8s Cluster in the following two ways:

#### 1. _Traffic between the pods and the services within the on-premise kubernetes cluster._

- Deploy both client and server for CyPerf Agents.
- Collect the values by checking the pod or the service properties respectively, if the CyPerf Agent servers are required to be configured in the DUT by using the `podIP` or the `ClusterIP` of the service. 
    ```
    kubectl get pods -l run=cyperf-agent-server -o wide

    kubectl get svc cyperf-agent-service -o wide
    ```
- Configure a _Name Server_ IP address in CyPerf Contoller's _Configure Network->DNS Resolver_ page for clients' _Network Segments_, if FQDN is used for the DUT. For example: if the cluster is using CoreDNS cluster addon (application name kube-dns), you can collect the DNS server IP address by using the following command.
    ```
    kubectl get services kube-dns --namespace=kube-system
    ```

#### 2. _Traffic that are destined to the container services in the on-premise kubernetes cluster._
- Deploy CyPerf Agent as server(s) behind the DUT.
- Collect the values by checking the pod or service properties respectively, if the CyPerf Agent servers are required to be configured in the DUT by using the `podIP` or the `ClusterIP` of the service. 
    ```
    kubectl get pods -l run=cyperf-agent-server -o wide

    kubectl get svc cyperf-agent-service -o wide
    ```

## Managing Resources for the CyPerf Agents
- It is recommended to run the CyPerf Agent clients and servers in different worker nodes. The example manifests can achive this by using the `nodeSelector` and by assigning labels in the nodes as described in the [General Prerequisites](#general-prerequisites) section.
    ```
        nodeSelector:    
            agenttype: client 

        --------

        nodeSelector:    
            agenttype: server 
    ```
- It is also recommended to run one Cyperf Agent in one worker node for the best performance. To ensure that, multiple CyPerf Agents of the same type are not sharing a single node, follow the `podAntiAffinity` rule:
    ```
        affinity:
            podAntiAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                - labelSelector:
                    matchExpressions:
                    - key: app
                      operator: In
                      values:
                      - cyperf-agent
                  topologyKey: "kubernetes.io/hostname"

    ``` 
- If you still need to share the resources among multiple CyPerf Agents, (for example: when multiple server pods are runing in the same node) then use the following:
    * `limits` and `requests` for `cpu`
    * `memory` and `resources` for more deterministic behaviour.
    ```
        resources:
            limits:
                memory: "4Gi"
                cpu: "3.5"
                ## skipping requests means limits=requests
                ## with 3.5 for 8 core node it should be able to run 2 replicas
            requests:
                memory: "2Gi"
    ```

## Supported CNIs
- **Flannel:**  
    [cni_examples/onprem-kube-flannel.yaml](cni_examples/onprem-kube-flannel.yaml) - [ [source](https://github.com/flannel-io/flannel/blob/master/Documentation/kube-flannel.yml) ]
- **Calico:**   
    a. [cni_examples/onprem-calico.yaml](cni_examples/onprem-calico.yaml) - [ [source](https://docs.projectcalico.org/manifests/calico.yaml) ]    
    - This example modifies the source by changing the mode of enabling IPIP tunneling thorugh `env CALICO_IPV4POOL_IPIP` from `"Always"` to `"CrossSubnet"`. You can use this to achieve higher performance when test traffic is flowing in the same subnet.    

    b. [cni_examples/eks-calico-vxlan.yaml](cni_examples/eks-calico-vxlan.yaml) - [ [source](https://docs.projectcalico.org/manifests/calico-vxlan.yaml) ]  

    - For more information, see [Install EKS with Calico networking](https://docs.projectcalico.org/getting-started/kubernetes/managed-public-cloud/eks#install-eks-with-calico-networking). 

- **AWS VPC CNI:** 

    This is the default CNI in the AWS EKS and is now supported by CyPerf version 1.0-Update1 and higher.
    - For more information, see [Install EKS with Amazon VPC networking](https://docs.projectcalico.org/getting-started/kubernetes/managed-public-cloud/eks#install-eks-with-amazon-vpc-networking).

- **PAN-CNI:**

    CyPerf agent pods with appropriate annotation can be deployed in a cluster with PAN CN-Series firewall. In this scenario,  test traffic is redirected by PAN-CNI to the firewall.

    ```
    annotations:                   paloaltonetworks.com/firewall: pan-fw
    ```
    Note that when CN-Series firewall is deployed as a K8s Service (as opposed to a Daemonset), traffic redirection between application pods and firewall happens via secure VXLAN encapsulation. In this case following modifications will also be required in the manifest file in addition to aforementioned annotation.


    ```
    -   name: AGENT_TEST_INTERFACE
        value: "vxlan0"
    -   name: AGENT_PROMISC_INTERFACE
        value: "<all>"
    ```

## Test Configuration Checklist
Ensure that the following configurations are appropriate, when configuring the CyPerf Controller for a test where CyPerf Agents are running inside the K8s cluster. 

1. _NetWork Segment_ that is using a Cyperf Agent(s) inside a cluster, should use the  _Automatic IP_, _Automatic IP prefix length_, and _Automatic gateway_ for the _IP Range_ configuration.
2. _NetWork Segment_ that is using a Cyperf Agent(s) that is simulating clients inside a cluster, should use the correct IP address for _Name server_ in _DNS Resolver_ configuration to resolve FQDN of the DUT. This is not applicable if the _DUT Network_ is configured for the _Host_ with IP address of the DUT.
3. CyPerf Agents that are simulating clients will send traffic to _Destination port_ as configured in _Connection Properties_ for _Application->Connections_. By default (indicated as `0` in UI), HTTP port `80` and TLS port `443` are used. If the DUT uses any non-default destination port for the incoming connections, you need to set this configuration appropriately.
4. CyPerf Agents that are simulating servers will listen to the on _Server port_ as configured in  _Connection Properties_ for _Application->Connections_. By default (indicated as `0` in UI), HTTP port `80` and TLS port `443` are used. If the DUT uses any non-default destination port for outgoing connections, you need to set this configuration appropriately.
5. Make sure that the DUT is forwarding the traffic to a port which is same as the `port` mentioned in the manifest yaml for `cyperf-agent-service`, while the CyPerf server Agents are listening to the `targetPort`. Adjust the configurations for the DUT or the CyPerf Contoller appropriately, to change any of these values.
6. When the `readinessProbe` is used in the manifest yaml for the CyPerf server Agent, note that it is configured for `httpGet` where the `path` is specified as `/CyPerfHTTPHealthCheck` and `port` as `80`. These parameters must match with the _HTTP Health Check->Parameters_ and the  _Target URL_ and the _Port_ respectively, as cofigured in the _DUT Network_ in CyPerf Controller UI and _HTTP Health Check_ which must be enabled.
7. If the DUT is also configured for the HTTP health check, use the same configuration as described above. 
     

## Troubleshooting

1. Collecting CyPerf Agent Logs
- At present, CyPerf Agent that is running as a container does not publish logs when collecting diagnostics from CyPerf Controller UI. However, individual pod logs can be collected manually. First identify the pod can show the details of all pods labeled as cyprf-agent, and then use the ID for redirecting the logs to a file. You need to transfer them manually.        
    ```
    kubectl get pods -l app=cyperf-agent -o wide

    kubectl logs [cyperf-agent-pod-id]  > [cyperf-agent-pod-id].log 
    ```
2. Agents not visible in CyPerf Controller
- Make sure that the ingress security rules for CyPerf Controller [(or Contoller Proxy)](#general-prerequisites) allow port numbers 443 for the control subnet in which Agent and CyPerf Controller (or Controller Proxy) can communicate. 
- Also check that the Agent pods are in ready state after deployment.
    ```
    kubectl get pods -l app=cyperf-agent -o wide
    ```  
     If pods are stuck in pending state, check the available resource in the nodes against the requested resource in the manifest yaml. Also, adjust the requested resource or the available resource in the node and redeploy.

3. Repeating pattern of connection failures in the test

- There can be several reasons for connection failures, like misconfigurations in general. For example, connections for test traffic might fail if some of the gateways or the DUT are not reachable from the client. However, there could be intermittent connection failures observed in a high scale test which might create confusions. In such cases, you can see a repeated pattern for the connection failures during the test.

    In K8s, some of the CNIs (for example: Calico) use the "conntrack", which is a feature of the Linux kernel networking stack. It allows the kernel to keep track of all the logical network connections or flows, so that all of the packets for individual flows can be handled consistently together. The conntrack table has a configurable maximum size. If it fills up, connections will start getting dropped.
    
    The scenarios where the conntrack table is responsible for connection failures are as follows:

    1. When the test is responsible to maintain an extremely high number of active connections. 
    
        For example: when the conntrack table size is configured for 128k entries but the test is trying to open more than 128k simultaneous connections, it will hit the table overflow issue. 

        **_NOTE:_** It is a scenario that can occur very often with a test case. 

    2. When the test is generating an extremely high number of connections per second. 
    
        Even if the connections are short-lived, you can track them for a short timeout period (by default, 120 seconds). 
        For example: if the conntrack table size is configured for 128k and the generated connections per second is 1200, it will exceed the conntrack table size, even if the connections are very short-lived (1200 per sec * 120 sec = 144k, which is greater than 128k). 

    3. When a test is using a ClusterIP as the connection destination and is modified to use a server pod IP as a new destination or is modified the other way round, the conntrack may get confused. 
    
        If you run these two tests consecutively without waiting for 120 seconds, there can be possibilities that some of the conntrack table entries will still remain in the TIME_WAIT state, which may result in connection failures also. 
        
        
        **_NOTE:_** It is recommended to wait for at least 120 seconds, before you run a new test. 
        For more information on conntrack, see the following articles:

    * https://projectcalico.docs.tigera.io/security/high-connection-workloads#extreme-high-connection-workloads

    * https://www.tigera.io/blog/when-linux-conntrack-is-no-longer-your-friend/

## Known Limitations


## Releases

- **CyPerf 7.0** - [July, 2025]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release7.0
        - public.ecr.aws/keysight/cyperf-agent:7.0.3.807

- **CyPerf 6.0** - [December, 2024]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release6.0
        - public.ecr.aws/keysight/cyperf-agent:6.0.3.746

- **CyPerf 5.0** - [October, 2024]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release5.0
        - public.ecr.aws/keysight/cyperf-agent:5.0.3.723

- **CyPerf 4.0** - [July, 2024]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release4.0
        - public.ecr.aws/keysight/cyperf-agent:4.0.3.704

- **CyPerf 3.0** - [February, 2024]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release3.0
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.656

- **CyPerf 2.6** - [October, 2023]
    - Image URI: 
        - public.ecr.aws/keysight/cyperf-agent:release2.6
        - public.ecr.aws/keysight/cyperf-agent:1.0.3.614

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
