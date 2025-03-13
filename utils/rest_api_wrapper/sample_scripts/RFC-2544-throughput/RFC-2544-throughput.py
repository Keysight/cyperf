import sys
sys.path.append("..")
from cyperf.utils.rest_api_wrapper.lib.REST_WRAPPER_trail import collect_stats_validate_throughput, rest, create_new_config, create_traffic_profile, run_test, collect_stats

#User inputs with defaults
line_rate_for_the_media_in_gbps=10
initial_target_throughput_in_gbps=10
tolerance=0.02
frame_size_in_bytes=1518# RFC recommened frame sizes for Testing Ethernet [64, 128, 256, 512, 1024, 1280, 1518]
direction_of_stream="ClientToServer"# allowed values are ClientToServer,ServerToClient,Bidirectional
tolerance_value_throughput_in_percentage=10 
number_of_streams=1
number_of_trials=1 # here trial means running tests multiple times to ensure consistency . This is not to be confused with the trial of binary serach for a particular framesize to ensure throughput . 
test_duration_in_seconds=30
Ethernet_header_size_in_bytes=18
IP_header_size_in_bytes=20
UDP_header_size_in_bytes=8
Initiator_mgmt_ip="10.39.69.98"
responder_mgmt_ip="10.39.69.99"

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
#calculate Initial target throughput in Bytes per second 
initial_target_throughput_in_Bps= (initial_target_throughput_in_gbps*pow(10,9)/8)

#create the test configuration
create_new_config()

#add a traffic profile - with a UDP stream application
create_traffic_profile(["UDP Stream"], "Simulated users", number_of_streams , None, test_duration_in_seconds, ssl=None)

#update the rate control settings in rampup phase 
rest.set_max_pending_simulated_user_in_percentage(Max_pending_simulated_user_in_percentage)
rest.set_max_simulated_users_per_second(Max_simulated_users_per_second)

#payload & direction settings - UDP Streaming activity; Presently there is only one application / activity
rest.set_udp_stream_direction(direction_of_stream)
rest.set_udp_stream_payload_size(frame_size_in_bytes)
rest.set_udp_stream_packet_rate(packet_rate)

rest.assign_agents_udp_streaming(Initiator_mgmt_ip,responder_mgmt_ip)

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
rest.set_ip_range_gateway(server_gateway,2,1)

run_test()
stop_trial_for_frame_size=collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput","./RFC-2544-throughput",False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance)
print("Soumya stop_trial_for_frame_size:{}",format(stop_trial_for_frame_size))

while( not stop_trial_for_frame_size ):
    #calculate the target throughput for the next run , as earflier run could not achieve the desired throughput 
    initial_target_throughput_in_gbps=initial_target_throughput_in_gbps/2
    packet_rate=((initial_target_throughput_in_gbps*pow(10,9))/8)/frame_size_in_bytes
    rest.set_udp_stream_packet_rate(packet_rate)
    initial_target_throughput_in_Bps= (initial_target_throughput_in_gbps*pow(10,9)/8)
    run_test()
    stop_trial_for_frame_size=collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput","./RFC-2544-throughput",False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance)
    print("The frame per second for this run = {}".format(packet_rate))

