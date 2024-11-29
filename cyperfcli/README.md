
## CyPerf CLI Free Editon 

CyPerf CLI Free Edition is a command line tool which is designed to help with testing networks by generating different kind of network traffic with relative ease. This tool harnesses some of the key strengths of CyPerf but with much simpler deployment steps. Its also much simpler to use. 

CyPerf CLI Free Editon can be used to generate traffic to test the following performance metrices of a network: 

- Bandwidth capacity by running throughput tests with throughput up to 10 Gbps. 

- Connection establishment capacity by running connection rate tests with connection rates up to 100K connections per second. 

We can tune parameters like TCP payload size, TCP receive window size, content of traffic etc. with the help of this tool. 

CyPerf CLI Free Editon also provides statistics like bandwidth, connection rate, average connection establishment latency etc. which are essential for debugging certain network issues. For a deeper investigation, it can also provide some detailed statistics like ARP stats, packet level stats i.e packet rate, packet drop stats etc and TCP level stats. 

 

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

CyPerf CLI Free Editon can be installed in a few simple steps. We can use Debian package management system (apt) to install, update and remove CyPerf CLI Free Edition. To install using apt we need to perform the following steps: 

Add CyPerf CLI Free Editon apt repo to apt sources by running the following commands
```
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings && \
curl http://cyperfcli.cyperf.io/cyperfcli-public.gpg | \
sudo gpg --yes --dearmor -o /etc/apt/keyrings/cyperfcli-public.gpg
echo "deb [arch=amd64  signed-by=/etc/apt/keyrings/cyperfcli-public.gpg] http://cyperfcli.cyperf.io stable main" | \
sudo tee /etc/apt/sources.list.d/cyperfcli.list > /dev/null

```
Install CyPerf CLI Free Edition by running
```
sudo apt update && sudo apt install cyperf 
```
### Getting started 


**Start a simple bandwidth test using CyPerf CLI Free Edition**

On server machine, run: 
```
sudo cyperf -s 
```

Yes, we need sudo permission, unfortunately, as we don’t know any other easy way of using the types of linux sockets we are using. And we need to set and manage some iptables rules as well. 

Once the cyperf server has started, on client run: 
```
sudo cyperf -c <server machine ip address> 
```

If there is proper network connectivity between the two machines, now we should see positive values in bandwidth statistics shown by both client and server. Once we are done with the test, we can stop it pressing Ctrl + C in the terminal. 

 

**Debugging if first test doesn’t show positive results**

First, if we have only IPv6 addresses available, then sorry, but currently CyPerf CLI Free Edition can only run using IPv4 addresses. 

Ok, tests started in both client and server without any errors, but we are not seeing any positive bandwidth stats, now what? 

Well, if proper stats cannot be seen, here are a few steps to help debug the issue: 

- Ensure both client and server machines have at least one NIC which has IPv4 address assigned to it and is in UP state. 

- Ensure there is a proper route available from client to server machine IP address. This can be checked by running 

 ```
ip route get <server machine ip address> 
```
- Ensure that ARP is not blocked by any network element. 

- CyPerf CLI Free Edition uses port 8080 by default to connect to server, ensure this is not blocked by any firewall or other element of the network. 

- Use --detailed-stats option in both client and server commands to diagnose the issue further: 

```
# On Server machine
sudo cyperf -s –detailed-stats 

# On Client machine
sudo cyperf -c <server machine ip address> --detailed-stats 
```

Now it will show some more stats like ARP stats, packet related stats and TCP stats. We can use these as per our knowledge of the network. For example, first we should check if the ARP requests are being sent from and ARP responses are getting back to client. We can check if the server receives the ARP requests and sent ARP response back. If there is no problem is ARP, then we can move to TCP stats and see if connections are getting established or not, and if not why, for example we can check whether SYN, SYN-ACK packet count, retransmission count, TCP RST packet count. These can guide us to the actual problem if there is any. 
 
**Ok, first test ran successfully, now what?**

Well, now we can play with different parameters and try to test different aspects of the network under test. Here are a few examples: 

- **Run a throughput test but with smaller payload size and a bandwidth limit of 1Gbps** 
```
# On Server machine
sudo cyperf -s --length 1k --bitrate 1G/s

# On Client machine
sudo cyperf -c <server machine ip address> --length 1k 
```

- **Run a connection rate test**
```
# On Server machine
sudo cyperf -s –cps

# On Client machine
sudo cyperf -c <server machine ip address> --cps 
```

- **Run a connection rate test with more realistic payload size and a connection rate limit of 1000 CPS** 
```
# On Server machine
sudo cyperf -s –cps –-length 1k

# On Client machine
sudo cyperf -c <server machine ip address> --cps 1k/s –-length 1k 
```
 
- **Run a test using a real file as TCP payload**
```
# On Server machine
sudo cyperf -s –-file <path to file>

# On Client machine
sudo cyperf -c <server machine ip address> –-file <path to file> 
```
 
**Ok great, what else can we do?**

Well, a here is a starting tip: 
```
cyperf –help 
```
This will print something like this in the console 
```
Usage: sudo cyperf [-s|-c host] [options] 

            cyperf [-h|--help] [-v|--version] [--about] 

 

Server or Client: 

  -p, --port      #           server port to listen on/connect to 

  -i, --interval  #           seconds between periodic statistics reports 

  -t, --time      #           time in seconds to run the test for (default 600 secs) 

  --cps           [#KMG][/#]  target connection rate in connections/sec (0 for unlimited) 

                              the value is optional and takes effect in client side only 

  --bidir                     run in bidirectional mode. 

                              client and server send and receive data. 

  -R, --reverse               run in reverse mode (server sends, client receives). 

  -l, --length    #[KMG]      length of buffer to read or write 

  -F, --file      <filepath>  use the specified file as the buffer to read or write 

  -B, --bind      <host>      bind to the interface associated with the address <host> 

  -w, --window    #[KMG]      set window size / socket buffer size 

  --csv-stats     <filepath>  write all stats to specified csv file 

  --detailed-stats            show more detailed stats in console 

  -v, --version               show version information and quit 

  -h, --help                  show this message and quit 

  --about                     show the Keysight contact and license information. 

Server specific: 

  -s, --server                run in server mode 

Client specific: 

  -c, --client    <host>      run in client mode, connecting to <host> 

  -b, --bitrate   #[KMG][/#]  target bitrate in bits/sec (0 for unlimited) 

  -P, --parallel  #           number of parallel client sessions to run 

 

[KMG] indicates options that support a K/M/G suffix for kilo-, mega-, or giga- 

```

If we have mandb installed in our system, we can also try reading the manual page by running 
```
man cyperf 
```
We can use these options as needed. One primary example is -P / --parallel option. Let’s retry our connection rate test with this option: 
```
# On Server machine
sudo cyperf -s –cps -P 64

# On Client machine
sudo cyperf -c <server machine ip address> --cps -P 64 
```
 
Hopefully we are seeing at least some improvements in connection rate now (unless we were already running with 64 core CPUs before). 

We will keep updating this documentation with more detailed information about how we can tune different test parameters, how to interpret the test configuration summary that gets shown at the start of the test and how to interpret the stats and test result summary at the end of the test. 

 
### **But before we stop, here are a few troubleshooting steps, and a few things to keep in mind** 

 
CyPerf CLI Free Edition needs to set some iptables rules to execute tests without interfering with linux stack traffic. But this can have a few bad side effects if we are not careful 

First, lets hammer this into our head: we will not use ssh ports or any other ports currently being used by any important program as the listen port while running CyPerf CLI Free Edition. Why, we will explore in the next item in this list. 

The iptables rules will block all traffic coming to server port (default 8080, can be changed using -p / --port option) from getting to linux network stack. And if any program was communicating using that port, then that program may not be able to continue. 

Now we can see why it is a very bad idea to use ssh port (default: 22) as the listen port, a very bad scenario would arise if we tried to do that, if the server machine is being used over ssh then this test will kill all ssh communication to that server machine. Then only way we can reach to that server machine again is by waiting out the test duration (default: 600 seconds) after which CyPerf CLI Free Edition server should automatically stop and cleanup the iptables rules blocking the ssh connection. 

But the above situation may get worse if for some reason the CyPerf CLI Free Edition server crashes due to some reason, for example being killed by kernel due to memory pressure, then we will not be able to use ssh to connect to that machine at all. To avoid such possibilities, please don’t use ports which can be or being actively used by other applications. 

**Ok, we will avoid using ssh ports as test ports like a plague. What else?**

Well, we still can run into some issues: 

We have tried to catch and squash as many bugs as we can, but there are still some possibilities that CyPerf CLI Free Edition client or server may exit unexpectedly for some reason, i.e crash or killed by kernel / user, and in that case, it will leave some iptables rules behind. These should get automatically cleaned up when we run CyPerf CLI Free Edition next time. But if for some reason, the client / server keeps crashing, it is recommended to reboot the client / server machine to clean up the iptables rules and other potential changes. But in case a reboot is not a preferred option, we can still remove these rules manually. To do that, first we can check the residual iptables rules by running: 
```
sudo iptables -S 
```
We should see an output like this: 
```
-P INPUT ACCEPT 
-P FORWARD ACCEPT 
-P OUTPUT ACCEPT 
-A INPUT -i ens160 -p tcp -m tcp --dport 8080 -m comment --comment "Added by CyPerf CLI, ruleset id: cyperf_cli_server_13977" -j DROP 
```
Now we can remove all the rules which have the comment “Added by CyPerf CLI, ruleset id: …”

For example, we can remove the rule in this example by running 
```
sudo iptables -D INPUT -i ens160 -p tcp -m tcp --dport 8080 -m comment --comment "Added by CyPerf CLI, ruleset id: cyperf_cli_server_13977" -j DROP 
```
- CyPerf CLI Free Edition currently doesn’t support running both the client and the server in same machine. We don’t know if we will be able to support it in future as well. 





