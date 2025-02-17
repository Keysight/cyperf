import re
import time, os, sys
from turtle import pd
# 

libpath = os.path.abspath(__file__+"/../../testsuite/rest_api_wrapper/lib")
sys.path.insert(0,libpath)
from REST_WRAPPER import create_new_config, create_traffic_profile, run_test, collect_stats
from util import *
import pytest
import paramiko
import yaml
import telnetlib
from paramiko.util import log_to_file
res = []
result = True
stats_result = {}
cmtu = None
smtu = None
rtt = None
port_speed = None
msg = []
#version 1.1 05-april-2023



def check_ipv4(logger, ip):
    ipv4Regex = r'(\d{1,3}\.){3}\d{1,3}'
    ipv4_match = re.search(ipv4Regex, ipaddr)
    if ipv4_match:
        return True
    else:
        return False
def ping_ssh(logger, payload_size, args, port):
    ssh_cl = paramiko.client.SSHClient()
    ssh_cl.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh_cl.connect(hostname=args['host'], username="cyperf", password="cyperf", allow_agent=False, look_for_keys=False)
    channel = None
    execute = 1
    ipv4Regex = r'(\d{1,3}\.){3}\d{1,3}'
    ipv4_match = re.search(ipv4Regex, str(args['target']))
    ping_data = "ping" + " " + str(args['target']) + " " + "-I " + str(port) + " -c 1 -s" + " " + str(payload_size) + " " + "-M do"
    if ipv4_match:
        ping_data = "ping" + " " + str(args['target']) + " " + "-I " + str(port) + " -c 1 -s" + " " + str(payload_size) + " " + "-M do"
    else:
        ping_data = "ping6" + " " + str(args['target']) + " " + "-I " + str(port) + " -c 1 -s" + " " + str(payload_size) + " " + "-M do"
    stdin, stdout, stderr = ssh_cl.exec_command(ping_data, get_pty=True)
    print("ping data")
    #print(stdout.read())
    if "ttl" in str(stdout.read()):
        print("True")
        return True
    else:
        print("False")
        return False






def ping_works(logger, payload_size, args, port_no):
    # we capture the output to prevent ping
    # from printing to terminal
    tn = telnetlib.Telnet(args['host'], 8021)
    tn.read_until(b"login: ")
    tn.write(bytes(args['port'], 'ascii') + b"\r\n")
    ipv4Regex = r'(\d{1,3}\.){3}\d{1,3}'
    ipv4_match = re.search(ipv4Regex, str(args['target']))
    ping_data = "ping" + " " + str(args['target']) + " " + "-I ixint1 -c 1 -s" + " " + str(payload_size) + " " + "-M do"
    if ipv4_match:
        ping_data = "ping" + " " + str(args['target']) + " " + "-I ixint1 -c 1 -s" + " " + str(payload_size) + " " + "-M do"
    else:
        ping_data = "ping6" + " " + str(args['target']) + " " + "-I ixint1 -c 1 -s" + " " + str(payload_size) + " " + "-M do"
    #sys.stdout.write('%s: ' % ping_data)
    if b'#' in tn.read_until(b'#', timeout=5):
        tn.write(bytes(ping_data, 'ascii') + b"\r\n")
        if b'ttl' in tn.read_until(b'ttl', timeout=5):
            #sys.stdout.write('%s: ' % "success")
            #sys.stdout.write('%s: ' % tn.read_until(b'ttl', timeout=5))
            return True
        else:
            #sys.stdout.write('%s: '% tn.read_until(b'PING', timeout=5))
            return False
        
def assign_ip(logger, host, ip, mask):
    # 
    ssh_cl = paramiko.client.SSHClient()
    ssh_cl.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh_cl.connect(hostname=host, username="cyperf", password="cyperf", allow_agent=False, look_for_keys=False)
    channel = None
    execute = 1
    stdin, stdout, stderr = ssh_cl.exec_command('cyperfagent interface test show', get_pty=True)
    for i in stdout:
        if "Currently" in i:
            interface = re.match(r"Currently configured Test Interface is\:\s+([a-z|A-Z|0-9]+)", i)
            test_interface = interface.group(1)
            command = "sudo ifconfig " + test_interface + " " + ip + "/" + str(mask)
            stdin, stdout, stderr = ssh_cl.exec_command(command, get_pty=True)
            stdin.write("cyperf" + '\n')
            if stdout.channel.recv_exit_status() != 0:
                print("Error while setting IP")
            stdin.flush()
            return (test_interface)
            #set_logger(logger, level="INFO", message= "Successfull IP set:")

    #s.sendline ('cyperfagent interface test show')

def get_port_speed(logger, host, interface, mtu):
    
    ssh_cl = paramiko.client.SSHClient()
    ssh_cl.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh_cl.connect(hostname=host, username="cyperf", password="cyperf", allow_agent=False, look_for_keys=False)
    channel = None
    execute = 1
    
    data = "cat /sys/class/net/" + interface + "/speed"
    stdin, stdout, stderr = ssh_cl.exec_command(data, get_pty=True)
    speed = stdout.read()
    port_speed = speed.decode().rstrip()


def assign_mtu(logger, host, interface, mtu):
    
    ssh_cl = paramiko.client.SSHClient()
    ssh_cl.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh_cl.connect(hostname=host, username="cyperf", password="cyperf", allow_agent=False, look_for_keys=False)
    channel = None
    execute = 1
    
    data = "cat /sys/class/net/" + interface + "/speed"
    stdin, stdout, stderr = ssh_cl.exec_command(data, get_pty=True)
    speed = stdout.read()
    
    port_speed = speed.decode().rstrip()
    
    data = "sudo ip link set " + str(interface) +  " mtu 9000"
    stdin, stdout, stderr = ssh_cl.exec_command(data, get_pty=True)
    stdin.write("cyperf" + '\n')
    if stdout.channel.recv_exit_status() != 0:
        set_logger(logger, level="INFO", message= "Test Failed: while setting jumbo mtu = 9000")
        pytest_assert(logger, result == True, "Test Failed while setting jumbo mtu = 9000")
        print("Error while setting IP")
    stdin.flush()
    return port_speed

def telnet(logger, host, ip, port):
    lo = 0  # MTUs lower or equal do work
    hi = 9000  # MTUs greater or equal don't work
    #print('>>> PMTU to %s in range [%d, %d)' % (args.target, lo, hi))
    
    
    arg = {'host':host, 'target': ip, 'lo':0, 'hi': 9000}
    while lo + 1 < hi:
        mid = (lo + hi) // 2
        sys.stdout.write('%d: ' % mid)
        sys.stdout.flush()
        for i in range(2):
            if ping_ssh(logger, mid, arg, port):
                lo = mid
                break
            else:
                sys.stdout.write('* ')
                sys.stdout.flush()
                time.sleep(0.2)
        else:
            hi = mid
            print('')

    # header_size = 28 if args.ipv4 else 48
    header_size = 28
    lo = lo + 28
    print('>>> optimal MTU to %s: %d  = %d' % (
        arg['target'], lo,  lo
    ))
    return (lo)


def parse_yaml():
    config_params = {}
    yaml_to_import = os.path.dirname(__file__) + "/params.yaml"
    testinfo = yaml.load(open(yaml_to_import), Loader=yaml.FullLoader)
    for key, values in testinfo.items():
        if key != "description":
            config_params[key] = values
    return config_params['config']

def report(logger, res, BB, rtt, cmtu, smtu,stats_result, logger_report):
    result1 = parse_status(res)
    set_logger(logger, level="INFO", message= "\nresult\n " + str(res) + "\n")
    if "fail" in result1.keys():
        ix.disconnect()
        set_logger(logger, level="INFO", message= str(res))
        set_logger(logger, level="INFO", message= "Test Failed: "+ str(result1['fail']))
        pytest_assert(logger, result == True, "Test Failed")
        final_report(logger,logger_report, False)
        pytest.fail("Test Failed: "+str(result1['fail']))
    elif "pass" in result1.keys():
        ix.disconnect()
        set_logger(logger, level="INFO", message=str(stats_result))
        set_logger(logger, level="INFO", message="\nConsolidated Result\n****************\nPath MTU of Client: " + str(cmtu) + "\nPath Mtu of server: " + str(smtu) + "\nRTT : " + str(rtt) + " us" + "\nTheoretical  Bottleneck Bandwidth: " + str(BB))
        consolidate_output(logger, stats_result)
        final_report(logger,logger_report, True)
        #consolidate_result(logger, stats_result)
        set_logger(logger, level="INFO", message="Test Passed")
        pytest_assert(logger, result == True, "Test Passed")

def final_report(logger, logger_report, flag):
    endtime =  datetime.datetime.now().strftime("%Y%m%d-%H:%M:%S") 
    set_logger(logger_report, message="\nFinal Report\n*******************\nStart Time : " + str(starttime)+"\nEnd Time : " + str(endtime))
    txt = ''
    for status in msg :
        txt = txt + "\n" + status
    set_logger(logger_report, level="INFO", message="\nConsolidated Result\n****************"+ txt)
    if flag:
        consolidate_output(logger_report, stats_result)
        set_logger(logger_report, level="INFO", message= "Test Passed")
    else:
        set_logger(logger_report, level="INFO", message= "Test Failed")
        
def update_cmd_args(ix, cmd_dict, cmd_arg, value):
    for cmd in cmd_dict['cmd_list']:
        if cmd_arg == 'destination':
            res.append(ix.emulation_http(mode='modify_command', role='Client', network_name=cmd_dict['network_name'],
                                     agent_name=cmd_dict['agent_name'], destination = value,  command_name = cmd))

#cyperf methods


def wait_for_test_stop():
    test_is_running = True
    while test_is_running:
        status = conn.get_test_status()
        if status['status'].lower() == "stopped":
            test_is_running = False
    return




def modify_ip_config(logger, ip_start, GwStart, NetMask, network_segment):
    
    conn.set_ip_range_automatic_ip(ip_auto=False, network_segment=1, )
    conn.set_ip_range_ip_start(ip_start=ip_start, network_segment=network_segment)
    conn.set_ip_range_gateway(gateway = GwStart, network_segment=network_segment)
    conn.set_ip_range_netmask(netmask = NetMask, network_segment=network_segment)


def get_rtt(logger, data):
    try:
        #
        #conn.load_config(rtt_config)
        #
        modify_ip_config(logger, ip_start=data['ClientIP'], GwStart = data['ClientGatewayIP'], NetMask = data['ClientSubnetMask'],  network_segment=1)
        modify_ip_config(logger, ip_start=data['ServerIP'], GwStart = data['ServerGatewayIP'], NetMask = data['ServerSubnetMask'],  network_segment=2)
        server_intf = assign_ip(logger, data["ServerAgent"], data['ServerIP'],  data['ServerSubnetMask'] )
        client_intf = assign_ip(logger, data["ClientAgent"],  data['ClientIP'], data['ClientSubnetMask'])
        global cmtu
        global smtu
        global port_speed
        port_speed = assign_mtu(logger, data["ClientAgent"],  client_intf , 9000)
        port_speed = assign_mtu(logger, data["ServerAgent"],  server_intf , 9000)
        cmtu = telnet(logger, data["ClientAgent"], data['ServerIP'], client_intf)
        smtu = telnet(logger, data["ServerAgent"], data['ClientIP'], server_intf)
        set_logger(logger, level="INFO", message= "Test 1 completed.")
        set_logger(logger, level="INFO", message= "Result - Path  Mtu of Client is " + str(cmtu))
        set_logger(logger, level="INFO", message= "Result - Path  Mtu of Server is " + str(smtu))
        conn.set_ip_range_mss(mss = (int(cmtu)-28), network_segment=1)
        conn.set_ip_range_mss(mss = (int(smtu)-28), network_segment=2)
        conn.assign_agents()
        st = conn.start_test()
        #wait_for_test_stop()
        conn.wait_test_finished()
        time.sleep(10)
        x = conn.get_stats_values("client-latency")
        #
        rtt_stats = []
        for stat in x['snapshots']:
            if stat['values'][0][1] != 'null':
                rtt_stats.append(stat['values'][0][1])
        if rtt_stats:
            rtt = str(average(rtt_stats))
            avg1 = rtt.split(".")
            rtt = avg1[0]+"."+avg1[1][:2]
            print("rtt : %s", rtt)
            set_logger(logger, level="INFO", message= "Test 2 completed. ")
            set_logger(logger, level="INFO", message= "RTT is " + str(rtt) +" us")
            return (rtt, port_speed)
        else:
            print("error in finding rtt")
    except Exception as err:
        raise Exception(err)


def get_theory_bottleneck(logger, port_speed):
    
    MTU = int(smtu)
    MSS = MTU -40 
    MEF = int(1038)
    BB = (MSS/MEF) * int(port_speed)
    BB = BB*1024
    BB = str(BB)
    avg1 = BB.split(".")
    BB = avg1[0]+"."+avg1[1][:2]	
    BB = str(BB) + " Mbps"
     
    set_logger(logger, level="INFO", message= "Theoretical Bottleneck Bandwidth is " + str(BB))
    return (BB) 
    
    
def max_throughput(logger, logger_report, name, buffer_size, t_num):
    band_tput = {}
    for buffer in buffer_size:
        print ("Running Test for %s with buffer size  %s" % (name, buffer))
        set_logger(logger, level="INFO", message= "Running Test for" + str(name) + " with buffer size " + str(buffer))
        band_tput[buffer]= {}
        #
        conn.set_client_http_profile({"ConnectionsMaxTransactions":t_num})
        conn.set_server_http_profile({"ConnectionsMaxTransactions":t_num})
        conn.set_client_recieve_buffer_size_traffic_profile(buffer)
        conn.set_client_transmit_buffer_size_traffic_profile(buffer)
        conn.set_server_recieve_buffer_size_traffic_profile(buffer)
        conn.set_server_transmit_buffer_size_traffic_profile(buffer)
        conn.assign_agents()
        conn.start_test()
        test_duration = 60
        real_time_stats = []
        start_time = time.time()
        
        conn.wait_test_finished()
        time.sleep(10)
        x = conn.get_stats_values("client-throughput")
        rtt_stats = []
        for stat in x['snapshots']:
            if stat['values'][0][1] != 'null':           
                num = float(stat['values'][0][1])/1000
                num = num/1000
                rtt_stats.append(int(round(num)))
        
        if rtt_stats:
            tput_average = round(average(rtt_stats))
            print("tput_average : %s  mpbs", str(tput_average))
        band_tput[buffer][tput_average] = x['snapshots']
         
        file_path = os.path.abspath(__file__+"/../../")
        file_path = file_path + "\\" + result_path + "\\" + name + str(buffer) + ".pdf"
        conn.get_pdf_report(file_path)
        #conn.get_capture_files(file_path)
        #print ("Completed Test for %s with buffer size  %s, Report file %s/%s" % (name, buffer))
        set_logger(logger, level="INFO", message= "Completed Test for" + str(name) + " with buffer size " + str(buffer))
    #
    max_stats = maxtput(band_tput)
    return (max_stats)
        
        # while time.time()-start_time < test_duration:
        #     real_time_stats.append({})
        #     for stat in conn.get_available_stats_name():
        #         
        #         real_time_stats[-1][stat] = conn.get_stats_values(statName=stat)
        # print(real_time_stats)
        # print('Number of read in {} seconds is {}'.format(test_duration,len(real_time_stats)))
        # rest.wait_test_finished()
        # collect_stats("../test_results", "stats_during_runtime")

def get_bottleneck(logger,  data, logger_report, buffer_size, number, name, tcp= []):
    try :
        #
        conn.load_config(test_name = name)
        conn.set_traffic_profile_timeline(duration=120, objective_value = 100)
        conn.set_ip_range_mss(mss = (int(cmtu)-28), network_segment=1)
        conn.set_ip_range_mss(mss = (int(smtu)-28), network_segment=2)
        modify_ip_config(logger, ip_start=data['ClientIP'], GwStart = data['ClientGatewayIP'], NetMask = data['ClientSubnetMask'],  network_segment=1)
        modify_ip_config(logger, ip_start=data['ServerIP'], GwStart = data['ServerGatewayIP'], NetMask = data['ServerSubnetMask'],  network_segment=2)
        if tcp:
            for tcp_no in tcp:
                print ("Running Test for TCP %s conn" % tcp)
                set_logger(logger, level="INFO", message= "Running Test for " + str(tcp_no) + " TCP connections:") 
                tput = max_throughput(logger, logger_report, name,buffer_size, t_num=tcp_no)
                buffer_size_new = list(tput.keys())[0]
                avg = list(tput[buffer_size_new].keys())[0]
                avg = int(avg)/1000
                key= name + "_" + "tcp" + "_" + str(tcp_no) + "_conn"
                stats_result[key] = {buffer_size_new:avg}
                set_logger(logger, level="INFO", message= "Max Throughput for: " + str(name)  + "\nBuffer size: " + str(buffer_size_new) +"\nAchieve TPUT: "+str(avg) + " mpbs")
        else:
            tput = max_throughput(logger, logger_report, name,buffer_size, t_num=2)
            buffer_size_new = list(tput.keys())[0]
            avg = list(tput[buffer_size_new].keys())[0]
            #avg = int(avg)/1000
            stats_result[name] = {buffer_size_new:avg}
            set_logger(logger, level="INFO", message= "Max Throughput for: " + str(name)  + "\nBuffer size: " + str(buffer_size_new) +"\nAchieve TPUT: "+str(avg) + " mpbs")
    except Exception as err:
        raise Exception(err)
            
def test_script(logger, logger_report):
    data = parse_yaml()
    
    
    server = data['IPAddress']
    username = data['username']
    password = data['password']
    client_id = data['client_id']
    client_ip = data['ClientAgent']
    server_ip = data['ServerAgent']
    client_gateway_ip = data['ClientGatewayIP']
    server_gateway_ip = data['ServerGatewayIP']
    client_subnet_mask = data['ClientSubnetMask']
    server_subnet_mask = data['ServerSubnetMask']
    global conn
    global result_path
    set_logger(logger, level="INFO", message = "RUNNING RFC 6349 TEST WITH PARAMETERS")
    set_logger(logger, level="INFO", message="CyPerf Server " + str(server) +  " Client ID " + str(client_id))
    set_logger(logger, level="INFO", message="Client Agent " + str(client_ip) + " Server Agent  " + str(server_ip))
    set_logger(logger, level="INFO", message="Client Ip " + str(data["ClientIP"]) +  " Client gateway IP  " + str(data["ClientGatewayIP"]) + "Client subnet mask " + str(data["ClientSubnetMask"]) )
    set_logger(logger, level="INFO", message="Server Ip " + str(data["ServerIP"]) +  " Server gateway IP " + data['ServerGatewayIP'] + " Server Subnet Mask " + str(data['ServerSubnetMask']))

    set_logger(logger, level="INFO", message="RFC 6349 based Throughput Testing \n ********************************** \nThe RFC 6349 “Framework for TCP Throughput Testing” provides a methodology for testing sustained TCP Layer performance. \n In addition to finding the TCP throughput at the optimal buffer size, RFC 6349 presents metrics that can be used to better understand the results.\n RFC 6349 testing is done in 3 steps:\n 1.	Identify the Path Maximum Transmission Unit (MTU) \n 2.	Identify the Baseline Round-Trip Time (RTT) and the Bottleneck Bandwidth (BB) \n 3.	Perform the TCP Connection Throughput Tests \n ***********************************\n")
    set_logger(logger, level="INFO", message="Test 1 - Determine the Path MTU between the client and the server\n -----------------------------------------------------------------\n")
    rtt_name = "1_RTT"
    rtt_config= os.path.abspath(__file__+"/../../" + rtt_name + ".zip")
    
    conn = create_new_config(server, username, password, client_id, rtt_config, rtt_name)
    #rtt = "1_RTT"
    bottleneck = "2_Bottleneck_bandwidth"
    upstream = "3_Upstream_tput"
    downstream = "4_Downstream_tput"
    bidirectional = "5_Bidirectional_tput"
    bidirectional_user = "6_Bidirectional_tput_user_constraint"
    #rtt_config= os.path.abspath(__file__+"/../../" + rtt + ".zip")
    bottleneck_config= os.path.abspath(__file__+"/../../" + bottleneck + ".zip")
    upstream_config= os.path.abspath(__file__+"/../../" + upstream + ".zip")
    downstream_config= os.path.abspath(__file__+"/../../" + downstream + ".zip")
    bidirectional_config= os.path.abspath(__file__+"/../../" + bidirectional + ".zip")
    bidirectional_user_config= os.path.abspath(__file__+"/../../" + bidirectional_user + ".zip")
    conn.import_config(bottleneck_config)
    conn.import_config(upstream_config)
    conn.import_config(downstream_config)   
    #
    conn.import_config(bidirectional_config)
    time.sleep(5)
    conn.import_config(bidirectional_user_config)
    (rtt, speed) = get_rtt(logger, data)
    
    result_path = result_log()
    set_logger(logger, level="INFO", message="Test 3 - Determine the Theoretical Bottleneck Bandwidth \n -----------------------------------------------------------------\n")
    BB = get_theory_bottleneck(logger=logger, port_speed=speed)
    set_logger(logger, level="INFO", message="Test 3 completed.\n Theoretical Bottleneck Bandwidth " + BB + "\n-----------------------------------------------------------------\n")
    buffer_size = [4096, 8192, 16384, 32768, 49152, 65536]
    set_logger(logger, level="INFO", message="Test 3 completed.\n  -----------------------------------------------------------------\n")    
    set_logger(logger, level="INFO", message="Test 4 - Determine the Bottleneck Bandwidth of the network \n -----------------------------------------------------------------\n")
    set_logger(logger, level="INFO", message= "Running Bottleneck test for rxf " + str(bottleneck))
    get_bottleneck(logger=logger, data = data, logger_report=logger_report, buffer_size= buffer_size, number=3, name=bottleneck)
    set_logger(logger, level="INFO", message="Test 4 completed.\n  -----------------------------------------------------------------\n")
    set_logger(logger, level="INFO", message="Test 5 - TCP Connection Throughput tests \n -----------------------------------------------------------------\n")
    set_logger(logger, level="INFO", message="Test 5.1 -	Upstream TCP Throughput test \n -----------------------------------------------------------------\n")
    set_logger(logger, level="INFO", message= "Running Upstream test for rxf " + str(upstream))
    
    get_bottleneck(logger=logger, data = data, logger_report=logger_report, buffer_size= buffer_size, number=3, name=upstream)
    set_logger(logger, level="INFO", message="Test 5.1 completed.\n  -----------------------------------------------------------------\n")
    set_logger(logger, level="INFO", message="Test 5.2 - Downstream TCP Throughput test  \n -----------------------------------------------------------------\n")
    set_logger(logger, level="INFO", message= "Running Downstream test for rxf " + str(downstream))
    get_bottleneck(logger=logger, data = data, logger_report=logger_report, buffer_size= buffer_size, number=3, name=downstream)
    set_logger(logger, level="INFO", message="Test 5.2 completed.\n  -----------------------------------------------------------------\n")
    set_logger(logger, level="INFO", message="Test 5.3 - Bidirectional TCP Throughput test  \n -----------------------------------------------------------------\n")
    set_logger(logger, level="INFO", message= "Running Bidirectonal test for rxf " + str(bidirectional))
    get_bottleneck(logger=logger, data = data, logger_report=logger_report, buffer_size= buffer_size, number=3, name=bidirectional)
    set_logger(logger, level="INFO", message="Test 5.3 completed.\n  ----------------------------------------------------------------\n")
    tcp_conn = [2, 4, 8, 16]
    buffer_size = [4096, 16384, 49152]
    set_logger(logger, level="INFO", message= "Test 5.4 - Multiple TCP Connection test ")
    set_logger(logger, level="INFO", message= "Running Multi Connection test for rxf " + str(bidirectional_user))
    get_bottleneck(logger=logger, data = data, logger_report=logger_report, buffer_size= buffer_size, number=3, name=bidirectional_user, tcp=tcp_conn)
    set_logger(logger, level="INFO", message="\nConsolidated Result\n****************\nPath MTU of Client: " + str(cmtu) + "\nPath Mtu of server: " + str(smtu) + "\n RTT : " + str(rtt) + " us" +"\nTheoretical  Bottleneck Bandwidth: " + str(BB))
    
    consolidate_result(logger, stats_result)
    set_logger(logger, level="INFO", message="Test Passed")
    pytest_assert(logger, result == True, "Test Passed")