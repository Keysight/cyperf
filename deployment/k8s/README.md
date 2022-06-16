# About using CyPerf Agents in K8s environments
## Introduction
This document describes about how Keysight CyPerf’s Agents can be deployed inside Kubernetes clusters. Following sections mention the prerequiites for such deployments and elaborate on minimal modifications that will be required in the client and server manifest yaml examples. Some of these modifications are required for updating the manifests for specific user environment and some will be optional or depend on different types of deployment scenarios.

- [Workflow](#workflow)
- [General Prerequisites](#general-prerequisites)
- [Example Manifests](#example-manifests)
- [Deployment in **AWS EKS**](#deployment-in-aws-eks)
- [Deployment in **On-Premise K8s Cluster**](#deployment-in-on-premise-k8s-cluster)
- [Managing Resource for CyPerf Agents](#managing-resource-for-cyperf-agents)
- [Supported CNIs](#supported-cnis)
- [Test Configuration Checklist](#test-configuration-checklist)
- [Troubleshooting](#troubleshooting)


## Workflow
- In order to test some device or service running inside a K8s cluster, user must start with such a cluster already deployed. The containerzied device under test (DUT) is expected to be already deployed in this cluster.
- There must be a CyPerf Controller already deployed as well. Once the CyPerf Agents are deployed in the cluster following the steps described below, they will automatically get registered to CyPerf Controller and become ready to use.
- A CyPerf Controller Proxy is required in some hybrid deployment scenarios, where each of the distributed Agents cannot directly access the CyPerf Controller. For example, when the CyPerf Controller is deployed on premise and some CyPerf Agents are in the cloud, they can still communicate through a CyPerf Controller Proxy. In this case, Agents register to the Controller Proxy and the public IP address of the Controller Proxy is configured in the CyPerf Controller.
- User can now introduce CyPerf Agents as client or server or both running inside the cluster by applying the [example manifests](#example-manifests). These manifests will require a few edits for adjusting to specific delpoyment scenario. 
- Agents will be visible (by their tags and IP addresses) in the _Agent Assignment_ dialog.
- Create a test using CyPerf Controller UI. Select Agents for respective _Network Segments_ and configure appropriate properties in _DUT Network->Configure DUT_ page in the UI before running the test. _[More details can be found in **_Chapter 3_** of **_Cyperf User Guide_**.]_ 

## General Prerequisites

1.  A kubernetes cluster along with DUT should be already deployed. For more details on how to deploy the DUT in a K8s cluster, please follow the instructions provided in the deployment guide for a specific DUT. For general information on K8s cluster deployment, please refer to [K8s website](https://kubernetes.io/docs/setup/).  
    - K8s version 1.20 or 1.21 is recommended.
    - *CyPerf Agents can be used in both* **_on-premise_** *K8s cluster (e.g. where nodes can be VMs on ESXi host) or in* **_cloud_** *(e.g. where nodes can be in* **_AWS EKS_***).*
2.  CyPerf Controller is already deployed. It should be accessible from the nodes inside the kubernetes cluster.  
    *Details on how to deploy CyPerf Controller and use it, how to manage licenses etc. can be found in* **_Chapter 2_** *of* **_Cyperf User Guide_ ***, which can be downloaded from Keysight's software download portal.*
3.  A CyPerf Controller Proxy is required in some hybrid deployment scenarios, where each of the distributed Agents cannot directly access the CyPerf Controller. For example, when the CyPerf Controller is deployed on premise and some CyPerf Agents are in the cloud, they can still communicate through a CyPerf Controller Proxy. In this case, Agents register to the Controller Proxy and the public IP address of the Controller Proxy is configured in the CyPerf Controller.
4.  Make sure that ingress security rules for CyPerf Controller (or Contoller Proxy) allow port numbers 443 and 30422 for the control subnet in which Agent and CyPerf Controller (or Controller Proxy) can communicate.
5.  The example manifests use the latest image URL from Keysight CyPerf's public container repository in ECR. If you need specific versions, note down CyPerf Agent's container image URL that you want to use. This ECR Public image URL needs to be accessible from the test environment, i.e. from the cluster nodes.
6.  Assign `agenttype=client` label to the nodes where you want to deploy CyPerf Agents as  test traffic initiating clients and assign `agenttype=server` label to the nodes where you want CyPerf Agents to be simulating the test servers.    
    ```
    kubectl get nodes --show-labels

    kubectl label nodes <your-node-name> agenttype=client
    kubectl label nodes <your-node-name> agenttype=server
    ```

## Example Manifests
- Client: [agent_examples/cyperf-agent-client.yaml](agent_examples/cyperf-agent-client.yaml) 
- Server: [agent_examples/cyperf-agent-server.yaml](agent_examples/cyperf-agent-server.yaml)        

- Modifications needed:
    1. Change the place holder container `image` URL with one that you want to use for CyPerf Agent container. Please get this URL from Keysight's software download portal.
    2. Change the place holder `AGENT_CONTROLLER` value with your CyPerf Controller's IP address. If controller IP is not known yet, this variable must be ommitted from the yaml and using cyperfagent CLI can be set after controller deployment.
    3. By default, agents will use the interface through which it can connect to the controller (or controller proxy) and select that as management interface. The same interface will be used for test traffic too. In case there is a need for explicitly selecting management or test interface, following `env` variables can be used. These are mentioned in the example yaml scripts as comments.

    ```
        #   name: AGENT_MANAGEMENT_INTERFACE
        #   value: "eth0"
        #   name: AGENT_TEST_INTERFACE
        #   value: "eth1"
    ```
    
    3. Change the place holder `AGENT_TAGS` with your preferred tags for identifying the agents as visible in CyPerf Controller's Agent Assignemnt dialog.
    4. If needed, update `nodeSelector` rule according to your preference. The example manifests assume that `agenttype=client`and `agenttype=server` labels are already assigned to the chosen worker nodes so that CyPerf Agent client pods and server pods are not deployed in the same node.
    5. Review the server manifest yaml to decide what `type` of `Service` your use case would require. e.g. `ClusterIP`, `NodePort` etc. and change accordingly.
    6. Decide on how many replicas for CyPerf Agent's client and server pods you would want to start with, and modify `replicas` count accordingly.
    7. Depending on your requirement, you may want to reserve and limit memory and cpu resources for CyPerf Agent pods. For more details please see section - [Managing Resource for CyPerf Agents](#managing-resource-for-cyperf-agents).
- Apply the manifests.
    ```
    kubectl apply -f cyperf-agent-client.yaml

    kubectl apply -f cyperf-agent-server.yaml

    ```
- You may scale the deployments later with desired number of replicas.
    ```
    kubectl scale deployment.v1.apps/cyperf-agent-server-deployment --replicas=2
    
    ```
- When there is a requirement for increasing server agent replica while a test is running, enable `readinessProbe` so that test traffic is forwarded to a server agent when it is ready.
    ```
        readinessProbe:
            httpGet:
                path: /CyPerfHTTPHealthCheck
                port: 80
            periodSeconds: 5
    ```

## Deployment in **AWS EKS**
#### Prerequisites
- All of [General Prerequisites](#general-prerequisites).
- In this case, the K8s cluster is in EKS which can be deployed using `eksctl` or any other methods described in [Getting started with Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html).  


### *A.* _**East-West**_ *traffic between pods and internal container services and workloads in* _**Amazon Elastic Kubernetes Service (EKS)**_ *environments*

- Deploy both client and server for CyPerf Agents.
- Depending on if CyPerf Agent servers need to be configured in DUT using `podIP` or the `ClusterIP` of the service, collect the values by checking the pod or service properties respectively.
    ```
    kubectl get pods -l run=cyperf-agent-server -o wide

    kubectl get svc cyperf-agent-service -o wide
    ```
- In case, FQDN is used for the DUT, configure a _Name Server_ IP address in CyPerf Contoller's _Configure Network->DNS Resolver_ page for clients' _Network Segments_. For example, if the cluster is using CoreDNS cluster addon (application name kube-dns), you can collect the DNS server IP address using following command.
    ```
    kubectl get services kube-dns --namespace=kube-system
    ```        

### *B.* _**North-South**_ *traffic destined to container services and workloads in* _**Amazon Elastic Kubernetes Service (EKS)**_ *environments*
- Deploy CyPerf Agent as server(s) behind the DUT.
- Depending on if CyPerf Agent servers need to be configured in DUT using `podIP` or the `ClusterIP` of the service, collect the values by checking the pod or service properties respectively.
    ```
    kubectl get pods -l run=cyperf-agent-server -o wide

    kubectl get svc cyperf-agent-service -o wide
    ```
- Besides all of the [General Prerequisites](#general-prerequisites), followings are needed.
    1. CyPerf Agents outside EKS which are supposed to be simulating clients, for initiating traffic flows.  
    *These client agents can also be running as pods in an on-prem kubernetes cluster or agents running in VM or COTS hardware.*
    2. Collect the FQDN or public IP address for the DUT, which needs to be configured in CyPerf Controller's _DUT Network_.
    3. In case, FQDN is used for the DUT, this needs to be resolved by CyPerf client Agents. Configure a _Name Server_ IP address in CyPerf Contoller's _Configure Network->DNS Resolver_ page for clients' _Network Segments_ .    


## Deployment in **On-Premise K8s Cluster**
#### Prerequisites
- All of [General Prerequisites](#general-prerequisites).

### *A. Traffic between pods and services within on-premise kubernetes cluster*

- Deploy both client and server for CyPerf Agents.
- Depending on if CyPerf Agent servers need to be configured in DUT using `podIP` or the `ClusterIP` of the service, collect the values by checking the pod or service properties respectively.
    ```
    kubectl get pods -l run=cyperf-agent-server -o wide

    kubectl get svc cyperf-agent-service -o wide
    ```
- In case, FQDN is used for the DUT, configure a _Name Server_ IP address in CyPerf Contoller's _Configure Network->DNS Resolver_ page for clients' _Network Segments_. For example, if the cluster is using CoreDNS cluster addon (application name kube-dns), you can collect the DNS server IP address using following command.
    ```
    kubectl get services kube-dns --namespace=kube-system
    ```

### *B. Traffic destined to container services in on-premise kubernetes cluster*
- Deploy CyPerf Agent as server(s) behind the DUT.
- Depending on if CyPerf Agent servers need to be configured in DUT using `podIP` or the `ClusterIP` of the service, collect the values by checking the pod or service properties respectively.
    ```
    kubectl get pods -l run=cyperf-agent-server -o wide

    kubectl get svc cyperf-agent-service -o wide
    ```
- Besides all of the [General Prerequisites](#general-prerequisites), followings are needed.
    1. CyPerf Agents outside cluster which are supposed to be clients initiating traffic flows destined to the DUT.  
    *These client agents can also be running as pods in an on-prem kubernetes cluster or agents running in VM or COTS hardware.*
    2. Collect the FQDN or public IP address for the DUT, which needs to be configured in CyPerf Controller's _DUT Network_.
    3. In case, FQDN is used for the DUT, this needs to b resolved by CyPerf client Agents. Configure a _Name Server_ IP address in CyPerf Contoller's _Configure Network->DNS Resolver_ page for clients' _Network Segments_ .

## Managing Resource for CyPerf Agents
- It is recommended to run CyPerf Agent clients and servers in different worker nodes, although it is not mandatory. The example manifests achive this by using `nodeSelector` and assigning labels in nodes as described in [General Prerequisites](#general-prerequisites).
    ```
        nodeSelector:    
            agenttype: client 

        --------

        nodeSelector:    
            agenttype: server 
    ```
- It is also recommended to run one Cyperf Agent in one worker node for best performance. It is not mandatory though. To ensure that even same type of CyPerf Agents are not sharing a node, following `podAntiAffinity` rule can be used.
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
- If you still want to share resources among multiple CyPerf Agents, for example when multiple server pods runing in the same node, then use `limits` and `requests` for `cpu` and `memory` `resources` for more deterministic behaviour.
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
    a. [cni_examples/onprem-kube-flannel.yaml](cni_examples/onprem-kube-flannel.yaml) - [ [source](https://github.com/flannel-io/flannel/blob/master/Documentation/kube-flannel.yml) ]
- **Calico:**   
    a. [cni_examples/onprem-calico.yaml](cni_examples/onprem-calico.yaml) - [ [source](https://docs.projectcalico.org/manifests/calico.yaml) ]    
    - This example modifies the source by changing the mode of enabling IPIP tunneling thorugh `env CALICO_IPV4POOL_IPIP` from `"Always"` to `"CrossSubnet"`, for achieving higher performance when test traffic is flowing in same subnet.    

    b. [cni_examples/eks-calico-vxlan.yaml](cni_examples/eks-calico-vxlan.yaml) - [ [source](https://docs.projectcalico.org/manifests/calico-vxlan.yaml) ]  

    - For more details, see [Install EKS with Calico networking](https://docs.projectcalico.org/getting-started/kubernetes/managed-public-cloud/eks#install-eks-with-calico-networking).

- **AWS VPC CNI:**  
This is the default CNI in AWS EKS, and is now supported starting from CyPerf version 1.0-Update1. 
    - For more details, see [Install EKS with Amazon VPC networking](https://docs.projectcalico.org/getting-started/kubernetes/managed-public-cloud/eks#install-eks-with-amazon-vpc-networking).

## Test Configuration Checklist
When configuring CyPerf Controller for a test where CyPerf Agents are running inside K8s cluster, ensure that following configurations are appropriate.

1. _NetWork Segment_ using Agent(s) inside a cluster should use  _Automatic IP_, _Automatic IP prefix length_ and _Automatic gateway_ for the _IP Range_ configuration.
2. _NetWork Segment_ using Agent(s) simulating clients inside a cluster, should use correct IP address for _Name server_ in _DNS Resolver_ configuration which can resolve FQDN of the DUT. This is not applicable if _DUT Network_ is configured for _Host_ with IP address of DUT.
3. CyPerf Agents simulating clients will send traffic to _Destination port_ as configured in _Connection Properties_ for _Application->Connections_. By default (indicated as `0` in UI), HTTP port `80` and TLS port `443` is used. If DUT uses any non-default destination port for incoming connections, this configuration must be set appropriately.
4. CyPerf Agents simulating servers will listen on _Server port_ as configured in  _Connection Properties_ for _Application->Connections_. By default (indicated as `0` in UI), HTTP port `80` and TLS port `443` is used. If DUT uses any non-default destination port for outgoing connections, this configuration must be set appropriately.
5. Make sure that DUT is forwarding the traffic to a port same as the `port` mentioned in manifest yaml for `cyperf-agent-service`, while CyPerf server Agents will have to be listening on `targetPort`. For changing any of these values, configurations for DUT or CyPerf Contoller need to be adjusted appropriately.
6. When `readinessProbe` is used in the manifest yaml for CyPerf server Agent, note that it is configured for `httpGet` where `path` is specified as `/CyPerfHTTPHealthCheck` and `port` as `80`. These must match with _HTTP Health Check->Parameters_, _Target URL_ and _Port_ respectively as cofigured in _DUT Network_ in CyPerf Controller UI and _HTTP Health Check_ must be enabled.
7. In case DUT is also configured for HTTP health check, use the same configuration as described above. 
     

## Troubleshooting

1. Collecting CyPerf Agent Logs
- At present, CyPerf Agent running as a container does not publish logs when collecting diagnostics from CyPerf Controller UI. However, individual pod's logs can be collected manually. First identify the pod showing the details of all pods labeled as cyprf-agent, and use the ID for redirecting logs to a file; then transfer manually.        
    ```
    kubectl get pods -l app=cyperf-agent -o wide

    kubectl logs [cyperf-agent-pod-id]  > [cyperf-agent-pod-id].log 
    ```
2. Agents not visible in CyPerf Controller
- Make sure that ingress security rules for CyPerf Controller [(or Contoller Proxy)](#general-prerequisites) allow port numbers 443 and 30422 for the control subnet in which Agent and CyPerf Controller (or Controller Proxy) can communicate. 
- Also check that Agent pods are in ready state after deployment.
    ```
    kubectl get pods -l app=cyperf-agent -o wide
    ```  
     If pods are stuck in pending state, check available resource in the nodes vs requested resource in manifest yaml. Adjust requested resource or available resource in the node and redeploy.

3. Repeating pattern of connection failures in the test

- There can be several reasons for connection failures, like misconfigurations in general. For example, connections for test traffic might fail if some gateway or DUT is not reachable from the client. However, there could be intermittent connection failures observed in a high scale test which might be puzzling. Such cases may show repeated pattern for connection failures during the test.

    In K8s, some CNIs like Calico use "conntrack", which is a feature of the Linux kernel’s networking stack. It allows the kernel to keep track of all logical network connections or flows, so that all of the packets for individual flows can be handled consistently together. The conntrack table has a configurable maximum size and, if it fills up, connections will start getting dropped. A few scenarios where the conntrack table is responsible for connection failures are mentioned bellow.

    * The most obvious case is if the test is supposed to maintain an extremely high number of active connections. For example, if conntrack table size is configured to be 128k entries but the test tries to open more than 128k simultaneous connections, it will hit table overflow issue.

    * The slightly less obvious case is if the test is generating an extremely high number of connections per second. Even if the connections are short-lived, connections continue to be tracked for a short timeout period (120 seconds by default). For example, if the conntrack table size is configured to be 128k and generated connections per second is 1200, that is going to exceed conntrack table size even if connections are very short-lived (1200 per sec * 120 sec = 144k, which is greater than 128k). 

    * Another possibility could be when a test that was using ClusterIP as the connection destination, is changed to use server pod’s IP as the new destination or the other way round, conntrack may get confused. If these two consecutive tests are run without waiting for 120 seconds there will be chances that some conntrack table entries are still in the TIME_WAIT state, which may result in connection failures as well. 

Therefore, it is recommended to wait for at least 120 seconds between test runs. 
To know more about how conntrack works and how to to disable that you can refer to following articles

https://projectcalico.docs.tigera.io/security/high-connection-workloads#extreme-high-connection-workloads

https://www.tigera.io/blog/when-linux-conntrack-is-no-longer-your-friend/

<!--
TO BE CONTINUED ...
-->   
   
## Known Limitations
1. CyPerf does not support IPv6 address for management interface yet.


## Releases

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
