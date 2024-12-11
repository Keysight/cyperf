
## CyPerf Community Edition 

CyPerf Community Edition (CE) is a free stateful network traffic generator derived from the award-winning commercial network application and security test solution – CyPerf.

CyPerf CE features a flexible and easy to use command line tool designed for testing end to end networks or network devices by generating stateful network traffic unlocking access to key performance metrics – e.g., bandwidth, connection rate, capacity, etc. It supports throughput of up to 10 Gbps and connection rates up to 100K connections per second. To review the main feature set included in CyPerf Community Edition and CyPerf Commercial please navigate to the relevant section below.


- [Installation steps](#Installation-steps)
- [Qualified platforms](#qualified-platforms)
- [Getting started](#getting-started)
- [Example use cases](#Example-use-cases)
- [Known limitations](#Known-limitation)
- [Troubleshooting](#Troubleshooting)
- [CyPerf Community Edition vs CyPerf Commercial](#cyperf-community-edition-vs-cyperf-commercial)
- [Support](#support)
- [Copyright and License](#copyright-and-license)

### Installation steps 
**Recommended system requirements** 

- Two Hosts for running client and server 
- OS: Ubuntu 2204 / Debian 12 
- 4 vCPU and 4 GB RAM* 
- Network connectivity with IPv4 addresses 
- Root access for installation and running tests 

Add CyPerf Community Edition apt repo to apt sources by running the following commands 

```
sudo apt update 
sudo apt install -y ca-certificates curl gpg
sudo install -m 0755 -d /etc/apt/keyrings && curl http://cyperfcli.cyperf.io/cyperfcli-public.gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/cyperfcli-public.gpg 
echo "deb [arch=amd64  signed-by=/etc/apt/keyrings/cyperfcli-public.gpg] http://cyperfcli.cyperf.io stable main" | sudo tee /etc/apt/sources.list.d/cyperfcli.list > /dev/null 
sudo apt update
 
```
 

Install CyPerf Community Edition by running 
```
sudo apt install -y cyperf  
```

> [!NOTE]
> **Noninteractive installation**
> To install this package in a noninteractive mode, for example in a Dockerfile, the Keysight EULA needs to be accepted by setting the environment variable ``KEYSIGHT_EULA_ACCEPTED`` to ``true`` before attempting to install.
> ```
> # Set to true if you accept the Keysight EULA: https://www.keysight.com/find/sweula
> KEYSIGHT_EULA_ACCEPTED=true sudo -E apt install cyperf
> ```


*This is suggested as a typical system requirement. Note that higher number of CPU cores will require higher free RAM. 

### Qualified platforms 

At present CyPerf Community Edition can be used on following platforms.

**Linux on premises VM**

- OS: Debian 12 / Ubuntu 2204 
- CPU: 4 vCPU or more 
- RAM: 4 GB or more 
- Storage: As required by OS 
- NIC type: vmxnet3 virtual NIC 

**Linux on AWS**

- OS: Debian 12 / Ubuntu 2204 
- Instance type: c5n.2xlarge 
- NIC type: aws ena 

CyPerf Community Edition should be able to run on platforms like AWS, Azure and GCP instances, Kubernetes clusters with supported CNIs (Calico, AWS VPC CNI, AKS CNI) etc.

### Getting started 

> [!CAUTION]
> CyPerf Community Edition by default uses port 5201 for test traffic. To   avoid disruption, ensure that no other application running in that host is using the same port. To use a different port for the test, use the ``-p / --port`` option in both client and server.
 

**Start a simple bandwidth test using CyPerf Community Edition**

Start the sever first using the following command 
```
sudo cyperf -s 
```

Once the server has started, start the client using the following command 
```
sudo cyperf -c <server machine ip address> 
```

Both client and server can be stopped by pressing Ctrl + C in their respective terminals. 

### Example use cases 

- **Throughput test with custom payload size and bandwidth limit of 1Gbps**
  ```
  sudo cyperf -s --length 1k 
  ```
  ```
  sudo cyperf -c <server ip address> --length 1k --bitrate 1G/s 
  ```
 
- **Connection rate test with default limits**
  ```
  sudo cyperf -s –cps 
  ```
  ```
  sudo cyperf -c <server ip address> --cps 
  ```
 
- **Connection rate test with custom payload size and connection rate limit of 1000 CPS**
  ```
  sudo cyperf -s –cps –-length 1k 
  ```
  ```
  sudo cyperf -c <server ip address> --cps 1k/s –-length 1k 
  ```

- **Customize number of parallel sessions**

  By default, client runs with parallel session count same as CPU core count. To customize parallel session count, use -P / --parallel option. 
  ```
  sudo cyperf -c <server machine IP address> --cps --parallel <count>
  ```
 
**Complete list of options can be found [here](HELP.md) or in manpage and quick help**
  ```
  man cyperf 
  ```
  ```
  cyperf --help 
  ```
 
### Known limitations 

- In case of listen port collision in server, cyperf will cause disruption in any other application using that port. 

- Client and server cannot be run in the same host. 

- Only IPv4 addresses are supported. 

 
### Troubleshooting 

**In case of abnormal program termination,** cyperf may fail to cleanup certain modifications in the host. A next successful run or a reboot will clean up these modifications automatically. However, these can be cleaned up manually by the following steps: 

  - Check iptables rule by running
      ```
      sudo iptables -s 
      ```
 
    If there are some rules which have the comment ``Added by CyPerf CLI …``, remove those. 

    For example, the following rule 

    ```
    -A INPUT -i ens160 -p tcp -m tcp --dport 5201 -m comment --comment "Added by CyPerf CLI, ruleset id: cyperf_cli_server_13977" -j DROP
    ```
    can be removed by running 
    ```
    sudo iptables -D INPUT -i ens160 -p tcp -m tcp --dport 5201 -m comment --comment "Added by CyPerf CLI, ruleset id: cyperf_cli_server_13977" -j DROP
    ``` 

- Restore sysctl entries net.core.rmem_max and net.core.wmem_max if needed 

    If cyperf failed to restore these values, the following files should be found: 
    
    - ``/var/log/cyperf/cli/net.core.rmem_max.bkp``
    - ``/var/log/cyperf/cli/net.core.wmem_max.bkp``

    These can be used to restore these sysctl entries to the value before they were modified by cyperf. Run 
    ```
    sudo sysctl -w net.core.rmem_max=$(cat /var/log/cyperf/cli/net.core.rmem_max.bkp) 
    ```
    ```
    sudo sysctl -w net.core.wmem_max=$(cat /var/log/cyperf/cli/net.core.wmem_max.bkp)
    ``` 
**In case both client and server start successfully, but the statistics show no traffic being exchanged**

-	Ensure proper network connectivity between the client and server and Linux route table is configured properly.
-	Ensure that the server selects the desired IPv4 addresses and network interfaces for the test. This can be viewed in the ``Test Configuration Summary`` shown at the start of the test.
    - If server selected the incorrect IPv4 addresses and network interfaces, fix this by using the ``-B / --bind`` option.

-	Ensure that the client selects the correct network interface and gateway (if applicable) for the test. This can be viewed in the ``Test Configuration Summary``.
-	Ensure that the ``Test Configuration Summary`` shows the correct server address and server port in the ``Server address`` field in client. Match that server port against the ``Listen port`` field in server.
-	Ensure that options like traffic direction, payload length etc. are set correctly in both client and server.
-	Use ``--detailed-stats`` option to view the Ethernet / IP, ARP and TCP level stats to diagnose the issue.

### CyPerf Community Edition vs CyPerf Commercial


|                  | CyPerf CE        | CyPerf           | 
|------------------|------------------|------------------|
| Performance   | Up to 10Gbps and 100K Connections per Second   | Bound the acquired license and hardware capabilities (up to multiple Tbps and millions of Connections per Second)    |
| Uni-directional and bi-directional traffic generation    | Yes  | Yes    |
| Configurable object size and real payload file   | Yes   | Yes   |
| Traffic type generation    | TCP traffic	    | Highly realistic application traffic emulation   |
| Customizable application actions and parameters    | No    | Yes    |
| Security Attack Emulation (Exploits & Malware)    | No   | Yes  |
| VPN Emulation (IPsec and SSL VPN) and ZTNA    | No    | Yes    |
| ZTNA Emulation    | No    | Yes    |
| Advanced L23 Features (multiple configurable IPs, VLANs, MACs etc) |	No |	Yes |
Advanced pcap replay    | No    | Yes   |
| Web-based UI and automation    | CLI only    | Web-based UI with comprehensive RestAPI support    |
| Statistics    | Basic stats	Advanced    | detailed stats    |
| Deployment    | Deb packages    | Deb packages, VMs (ESXi, KVM), Containers, Public Cloud (AWS, Azure, GCP)    |

### Support

For any issues, queries or concerns related to CyPerf Community Edition, please contact us at support@keysight.com, and make sure to start your email subject with CyPerfCE keyword. As being a free product, support queries will be handled on a best effort basis.

### Copyright and License

© Keysight Technologies 2013 - 2021

To  view  the licence to use this product, check the [EULA](https://www.keysight.com/find/sweula).

Notices about third-party software distributed with this software can be found [here](License/cyperf_thrid_party_license_document).

