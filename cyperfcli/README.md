
## CyPerf CLI Free Editon 

CyPerf CLI Free Edition is an easy-to-use command line tool which is designed  for testing networks by generating different kind of network traffic to measure performance metrices like bandwidth, connection rate capacity etc. This tool harnesses some of the key strengths of the licensed product CyPerf. This Free Edition supports throughput up to 10 Gbps and connection rate up to 100K connections per second.  

CyPerf CLI Free Edition also provides different types of statistics for a deeper insight into the network’s performance behaviour. 

 

### Supported platforms 

We aim to make CyPerf CLI Free Edition run on variety of platforms. But so far, we have targeted the following platforms to test and validate: 

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

 
CyPerf CLI Free Edition should be able to run on even more platforms like other AWS instance types, Azure instances, Kubernetes clusters with supported CNIs (Callico, AWS VPC CNI, AKS CNI), and we are continuing to test add validate this in more platforms. 


### Installation steps 
**System requirements** 

Two Hosts for running client and server 
OS: Ubuntu 2204 / Debian 12 
4 vCPU and 4 GB RAM* 
Network connectivity with IPv4 addresses 
Root access for installation and running tests 

Add CyPerf CLI Free Edition apt repo to apt sources by running the following commands 

```
sudo apt-get update 
sudo apt-get install ca-certificates curl 
sudo install -m 0755 -d /etc/apt/keyrings && curl http://cyperfcli.cyperf.io/cyperfcli-public.gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/cyperfcli-public.gpg 
echo "deb [arch=amd64  signed-by=/etc/apt/keyrings/cyperfcli-public.gpg] http://cyperfcli.cyperf.io stable main" | sudo tee /etc/apt/sources.list.d/cyperfcli.list > /dev/null 
sudo apt update 
```
 

Install CyPerf CLI Free Edition by running 
```
sudo apt install cyperf  
```
*This is suggested as a typical system requirement. Note that higher number of CPU cores will require higher free RAM. 
### Getting started 
<div style="border: 2px solid #FF6666; padding: 10px;">
CyPerf CLI Free Edition by default uses port 8080 for test traffic. To avoid disruption, ensure that no other application running in that host is using the same port. To use a different port for the test, use the -p / --port option in both client and server. 
</div>  
<br>

**Start a simple bandwidth test using CyPerf CLI Free Edition**

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
 
**Complete list of options can be found <here/ link to separate page> or in manpage and quick help**
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
    -A INPUT -i ens160 -p tcp -m tcp --dport 8080 -m comment --comment "Added by CyPerf CLI, ruleset id: cyperf_cli_server_13977" -j DROP
    ```
    can be removed by running 
    ```
    sudo iptables -D INPUT -i ens160 -p tcp -m tcp --dport 8080 -m comment --comment "Added by CyPerf CLI, ruleset id: cyperf_cli_server_13977" -j DROP
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

- Ensure there is network connectivity between the client and server.
- Ensure the server picked correct network interface and IPv4 address as the test address. This can be viewed in the ``Test Configuration Summary`` shown just at the start of the test.
  - If it is found that the IPv4 addresses and network interfaces picked by the server does not contain the correct address and network interface, then this can be fixed by using the ``-B / --bind`` option.
 
- Ensure the client picked the correct network interface and gateway (if applicable) for the test. This can be checked in the ``Test Configuration Summary`` shown just at the start of the test.
  - If it is found that the IPv4 address and network interface picked by the client is not correct, then check the Linux route table by running ip route and if any issue is found there, that needs to be fixed before trying to run client again.
  - In some less likely cases using the ``-B / --bind`` option may help
 
- Ensure that the ``Test Configuration Summary`` shows the correct server address and server port in the ``Server address`` field in client and match that server port against the ``Listen port`` field in server. If they don’t match, check the command line options being passed in both client and server.
 
- Ensure that settings like traffic direction, payload length etc are set properly in both client and server.

- Use ``--detailed-stats`` option to view the Ethernet / IP, ARP and TCP level stats to diagnose the issue.
 
 
 
