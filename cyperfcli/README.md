# CyPerf CLI

## What is CyPerf CLI?

It is a lighter weight version of CyPerf meant to be much easier to install and use albeit with a very limited feature set. It has the following features:

- Standalone package installer (Currently only Debian package (.deb), planned support for RHEL package (.rpm) too)
- Single binary executable with a simple command line interface.
Easy to use with just a single command for each node, client / server.
- Key benefits of CyPerf are also available in this tool: Throughput testing, Connection rate testing, concurrency testing (future)
- Key statistics available in tabular and CSV format.

## What is the purpose of CyPerf CLI?

This tool is designed to be a free network testing tool which can help Keysight market the key strengths of CyPerf in a more hands on manner. It is expected that with this free tool, many new customers will get to try and get familiarized to the strengths of CyPerf. If this helps them achieve their network testing requirements, Keysight CyPerf will get more exposure to the customers. If they need more features / performance of CyPerf, they may be more ready to try and purchase full CyPerf solution.



## If this tool is free, will it not become a free competition of CyPerf?

This tool is designed to be a free and limited preview of key CyPerf features. For example, it doesn’t have features like different control plane options, ATI, Zero Trust etc. Also, it is limited to certain performance numbers:

- Throughput: 10 Gbps
- Connection rate: 100K CPS
- Concurrency: 64K (May be 1M in future)


## How to use CyPerf CLI?

It is a CLI tool which can be invoked from the terminal with certain command line parameters. If server and client side are started correctly and the network connectivity between these two nodes are properly established, traffic should be seen between these two nodes. Also, CyPerf CLI can show variety of stats. For more information on how to run the CyPerf CLI, refer to the attached documentation.



## What are CyPerf CLI system requirements?

CyPerf CLI should run on any Debian based distribution and any VM with atleast 2 vCPUs and 4 GB of RAM. However to keep CyPerf CLI resource requirements well defined, the following should be considered:

- CPU : 4 vCPU
- Memory: 4 GB of RAM (And increase proportionally with CPU core count.)
- Debian 12 / Ubuntu 20.04 / Ubuntu 22.04


## How to test CyPerf CLI?

As of now CyPerf CLI can be tested manually until an automated test harness is developed. For testing CyPerf CLI manually, the following steps are needed:

- Prepare two nodes for client and server using one of the supported OS.
- Ensure there is connectivity to package installation repositories.
- Install cyperf cli package using the package manager (use apt or apt-get so that dependencies are automatically installed, DO NOT USE dpkg directly, it may result in broken dependency tree).
Start the cyperf cli process in the server node first by running the desired cyperf tool with desired CLI options.
- Once the test is stared in server side, start the cyperf cli process in client in the same way except using the client specific cli options in client node.
- The tool will start printing stats on console (by default every 3 seconds, but this is overridable using -i cli option)
- If more stats are required, --detailed-stats CLI option can be used.
- To stop the test, client process should be stopped followed by the server process.


## What to test in CyPerf CLI?



The following is a non-exhaustive set of tests for CyPerf CLI, more tests should be carried out but are not listed here yet.

GLOBAL PERFORMANCE LIMITS WHICH SHOULD NOT BE BREACHED IN ANY CIRCUMSTANCES:

- Throughput: 10 Gbps (10 Gigabits per second)
- Connection rate: 100 K CPS (100000 connections per second)

Some current limitations:

- Currently only TCP is supported
- Currently only IPv4 is supported
- Currently only throughput and correction rate objectives can be used, concurrency will appear later.
Some work in progress features which are not present in current build but should appear before release 1.0:

- Real file payload option.
- Use of gateway to hop across network.
- Traffic direction: Download from server.
- CSV / JSON stats.

Potential tests:

- Basic functionality (network):
	Test with explicitly specified test NIC
	Run a test with a specified test NIC in both client and server.
	For server, -B / --bind CLI option will be needed to specify the test interface by specifying the ip address of that interface.
	For client:
Either use -B / --bind CLI option like in server
Or if the routes are configured properly in linux route table, the client should automatically select the proper test interface. To check if the route is configured correctly, the following command can be used: ip route get <server ip address>


Test without explicitly specified test NIC (single NIC in both client and server):
Run a test without specifying test NIC in both client and server.
The server should start listening on the only available NIC in server node.
The client should start connections via the only available NIC in client.
Test without explicitly specified test NIC (multiple NIC in both client and server):
Run a test without specifying test NIC in both client and server.
The server should start listening on all available NIC in server node.
The client should pick the correct NIC to use from the linux route table.
The server should be able to accept connection coming from all NICs in server side.


Basic functionality (input validation tests, both positive and negative):
WIP


Basic functionality (throughput):
Basic throughput test without specific throughput limit:
Run a test without any explicitly specified throughput limit
The test should still be automatically limited to global limits mentioned earlier.
Basic throughput test with specific throughput limit under or equals to global throughput limit:
Run a test with a specific throughput limit which is under the global throughput limit mentioned above.
The test should achieve the throughput as specified if the resources are sufficient for that and it should not overshoot the specified throughput.
The test should not breach the global connection rate limit.
Basic throughput test with specific throughput limit over the global throughput limit:
Run a test with a specific throughput limit which is over the global throughput limit mentioned above.
The client should not start and show a proper error message and exit.


Basic functionality (connection rate):
Basic connection rate without specific connection rate limit:
Run a test without any explicitly specified connection rate limit
The test should still be automatically limited to global limits mentioned earlier.
Basic throughput test with specific connection rate limit under or equals to global connection rate limit:
Run a test with a specific connection rate limit which is under the global connection rate limit mentioned above.
The test should achieve the connection rate as specified if the resources are sufficient for that and it should not overshoot the specified connection rate.
The test should not breach the global throughput limit.
Basic connection rate test with specific connection rate limit over the global connection rate limit:
Run a test with a specific connection rate limit which is over the global connection rate limit mentioned above.
The client should not start and show a proper error message and exit.


## Advanced functionality (traffic direction):
Tests with traffic direction from client to server (default):
Run a test with configuration where traffic will flow from client to server.
The stats should show traffic flowing from client to server.
Tests with traffic direction from server to client:
Run a test with configuration where traffic will flow from server to client.
The stats should show traffic flowing from server to client.
Tests with traffic direction - bidirectional:
Run a test with configuration where traffic will flow in both direction (--bidir cli option).
The stats should show traffic flowing in both directions in approximately 50%-50% ration.


## Advanced functionality (payloads):
Test with different payload size (-l / --length CLI option)
Test with real file payload (-F / --file CLI option)


## Advanced functionality (connection properties):
Test with different window size (-w / --window CLI option)
Test with different MSS (-M / --set-mss CLI option)
Test with different server port (-p / --port CLI option)


## Advanced functionality (statistics):
Test with detailed statistics to test for different L23 and L4 statistics.
The console statistics view should adjust based on console width, wide table with 3 side by side sub tables if the console is wide enough, else tall table with 3 sub tables stacked.
CSV / JSON stats (WIP).




# Installtion

## Prerequisite
```
  curl -O http://cyperfcli.cyperf.io/pgp-key.public
  sudo mkdir -p /etc/apt/keyrings
  cat pgp-key.public | sudo gpg --dearmor -o /etc/apt/keyrings/cyperfcli-repo-keyring.gpg
  echo "deb [arch=amd64  signed-by=/etc/apt/keyrings/cyperfcli-repo-keyring.gpg] http://cyperfcli.cyperf.io stable main" | sudo tee /etc/apt/sources.list.d/cyperfcli.list
  sudo apt update
  sudo apt install cyperf
```
