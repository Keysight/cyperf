# Introduction
Welcome to the GitHub repository for CyPerf, a Keysight product. CyPerf is an agent-based network application and security test solution, that meticulously recreates realistic workloads across diverse physical and cloud environments to deliver unparalleled insights into the end-user quality of experience (QoE), security posture, and performance bottlenecks of distributed networks.

A licensed CyPerf product is compatible with multiple environments. Choose from the following supported platforms for accessing ready-to-use deployment templates.

# RFC 6349 Test

The RFC 6349 “Framework for TCP Throughput Testing” provides a methodology for testing sustained TCP Layer performance. 
 In addition to finding the TCP throughput at the optimal buffer size, RFC 6349 presents metrics that can be used to better understand the results.
 RFC 6349 testing is done in 3 steps:
 	1) Identify the Path Maximum Transmission Unit (MTU) 
 	2) Identify the Baseline Round-Trip Time (RTT) and the Bottleneck Bandwidth (BB) 
   	3) Perform the TCP Connection Throughput Tests 

# Steps to execute RFC 6349 test script

    1)	Install the latest version of Python 3.
    2)	Clone the CyPerf github reprository.
    3)	Modify “Cyperf/utils/RFC6349/test/params.yaml” such as IPAddress, "username", "password", "client_id", "ClientAgent", "ServerAgent", "ClientIP", "ClientSubnetMask", "ClientGatewayIP", "ServerIP", "ServerSubnetMask", "ServerGatewayIP" with a desire value.
    4)	Run "python setup.py setup" to install all the dependent python library (all the necessary packages are updated in file requirements.txt). This will setup the environment needed to run the script.
    5)	Navigate to RFC6349 folder and run the script:-  python -m pytest test/rfc_test.py --logstatus testlog.log
    6)	Once execution is complete, view testlog.log logfile in the extracted directory for the results.
    7)  All the result cyperf reports will be avalable under folder start with "Result" followed by execution date, exmaple : Result2025_01_22_23_57_15





