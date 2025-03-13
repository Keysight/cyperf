'''import sys
sys.path.append("..")
from lib.REST_WRAPPER import rest, create_new_config, create_traffic_profile, run_test, collect_stats

#User inputs with defaults
line_rate_for_the_media_in_gbps=10
initial_target_throughput_in_gbps=1
frame_size_in_bytes=1518# RFC recommened frame sizes for Testing Ethernet [64, 128, 256, 512, 1024, 1280, 1518]
direction_of_test="ClientToServer"
tolerance_value_throughput_in_percentage=10 
number_of_streams=1
number_of_trials=1
test_duration_in_seconds=30
Ethernet_header_size_in_bytes=18
IP_header_size_in_bytes=20
UDP_header_size_in_bytes=8

#User Input Emulated IP endpoints for client and Server 
client_start_ip="10.0.0.10"
client_gateway="10.0.0.1"
Server_start_ip="10.0.0.100"
server_gateway="10.0.0.1"

#rate control while ramp
#Max_pending_simulated_user_in_percentage=str(number_of_streams)
Max_pending_simulated_user_in_percentage="100%"
Max_simulated_users_per_second=0

#derived values from user input required for Test configuration
packet_rate=((initial_target_throughput_in_gbps*pow(10,9))/8)/frame_size_in_bytes#assuming each UDP packet is carried in a separate Ethernet frame
theoritical_packet_rate=((line_rate_for_the_media_in_gbps*pow(10,9))/8)/frame_size_in_bytes
udp_payload= frame_size_in_bytes-(Ethernet_header_size_in_bytes + IP_header_size_in_bytes + UDP_header_size_in_bytes)

#create the test configuration
create_new_config()

#add a traffic profile - with a UDP stream application
create_traffic_profile(["UDP Stream"], "Simulated users", number_of_streams , None, test_duration_in_seconds, ssl=None)

#update the rate control settings in rampup phase 
rest.set_max_pending_simulated_user_in_percentage(Max_pending_simulated_user_in_percentage)
rest.set_max_simulated_users_per_second(Max_simulated_users_per_second)

#payload & direction settings - UDP Streaming activity; Presently there is only one application / activity
rest.set_udp_stream_direction(direction_of_test)
rest.set_udp_stream_payload_size(frame_size_in_bytes)
rest.set_udp_stream_packet_rate(packet_rate)

rest.assign_agents_udp_streaming("10.39.69.98","10.39.69.99")
#Turn off automatic setting on the IPrange of the client network segment 
rest.set_automatic_ip_range_inactive(1,1)
#Turn off automatic setting on the IPrange of the Server network segment 
rest.set_automatic_ip_range_inactive(2,1)

#set the IP address ranges for the client network 
rest.set_ip_range_ip_start( client_start_ip,1,1)
rest.set_ip_range_ip_increment("0.0.0.1",1,1)
rest.set_ip_range_ip_count(number_of_streams,1,1)
rest.set_ip_range_max_count_per_agent(number_of_streams,1,1)
rest.set_ip_range_netmask(16,1,1)
rest.set_ip_range_gateway(client_gateway,1,1)

#set the IP address ranges for the server network 
rest.set_ip_range_ip_start(Server_start_ip,2,1)
rest.set_ip_range_ip_increment("0.0.0.1",2,1)
rest.set_ip_range_ip_count(1,2,1)
rest.set_ip_range_max_count_per_agent(number_of_streams,2,1)
rest.set_ip_range_netmask(16,2,1)
rest.set_ip_range_gateway(server_gateway,2,1)'''



#CyPerf API test with 1 imported test config, Primary/Secondary objectives, SSL enabled and B2B agents
#test_duration = 60
#run_number=1
#create_new_config()
#rest.add_application("Baidu Microsoft Edge")
#create_new_config("../test_configs/test-appmix.zip")
#create_new_config("../test_configs/test-appmix-{}.zip".format( run_number))
#rest.get_agents_ips()
#rest.assign_agents()
#rest.set_primary_objective(objective="Throughput")
#rest.set_test_duration(test_duration)
#rest.add_secondary_objective()
#rest.add_secondary_objective_value(objective="Simulated users", objective_value=5)
#rest.set_traffic_profile_client_tls(version="tls12Enabled", status=True)
#rest.set_traffic_profile_server_tls(version="tls12Enabled", status=True)
#rest.assign_agents()
#rest.enable_disable_tls_traffic_profile()
#import pdb;pdb.set_trace()

'''my code'''
#run_test()
collect_stats("../test_results", "RFC-2544-udp-streaming-throughput","./RFC-2544-throughput",False)
