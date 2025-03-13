import sys
sys.path.append("..")
from cyperf.utils.rest_api_wrapper.lib.REST_WRAPPER_trail import collect_stats_validate_throughput, rest, create_new_config, create_traffic_profile, run_test, collect_stats
import yaml
import time
file_path="./RFC-2544-throughput/parameters.yaml"
def read_yaml_file(file_path):
    """
    Read a YAML file and populate the values into a dictionary.
    Args:
        file_path (str): The path to the YAML file.
    Returns:
        dict: A dictionary containing the values from the YAML file.
    """
    try:
        with open(file_path, 'r') as file:
            yaml_data = yaml.safe_load(file)
            return yaml_data
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        return {}
    except yaml.YAMLError as e:
        print(f"Error parsing YAML file: {e}")
        return {}

yaml_dict = read_yaml_file(file_path)
#print(yaml_dict)




#User inputs with defaults
line_rate_for_the_media_in_gbps=yaml_dict['line_rate_for_the_media_in_gbps']
initial_target_throughput_in_gbps=yaml_dict['initial_target_throughput_in_gbps']
initial_minimum_throughput_limit_in_gbps=yaml_dict['initial_minimum_throughput_limit_in_gbps']
tolerance=yaml_dict['tolerance']
frame_size_in_bytes=yaml_dict['frame_size_in_bytes']# RFC recommened frame sizes for Testing Ethernet [64, 128, 256, 512, 1024, 1280, 1518]
direction_of_stream=yaml_dict['direction_of_stream']# allowed values are ClientToServer,ServerToClient,Bidirectional
number_of_streams=yaml_dict['number_of_streams']
number_of_trials=yaml_dict['number_of_trials'] # here trial means running tests multiple times to ensure consistency . This is not to be confused with the trial of binary serach for a particular framesize to ensure throughput . 
test_duration_in_seconds=yaml_dict['test_duration_in_seconds']
interval_between_test_run_in_seconds=yaml_dict['interval_between_test_run_in_seconds']

Ethernet_header_size_in_bytes=yaml_dict['Ethernet_header_size_in_bytes']
IP_header_size_in_bytes=yaml_dict['IP_header_size_in_bytes']
UDP_header_size_in_bytes=yaml_dict['UDP_header_size_in_bytes']
Initiator_mgmt_ip=yaml_dict['Initiator_mgmt_ip']
responder_mgmt_ip=yaml_dict['responder_mgmt_ip']

#User Input Emulated IP endpoints for client and Server 
client_start_ip=yaml_dict['client_start_ip']
client_gateway=yaml_dict['client_gateway']
Server_start_ip=yaml_dict['Server_start_ip']
server_gateway=yaml_dict['server_gateway']

#rate control while ramp
#Max_pending_simulated_user_in_percentage=str(number_of_streams)
Max_pending_simulated_user_in_percentage=yaml_dict['Max_pending_simulated_user_in_percentage']
Max_simulated_users_per_second=yaml_dict['Max_simulated_users_per_second']

#derived values from user input required for Test configuration
packet_rate=((initial_target_throughput_in_gbps*pow(10,9))/8)/frame_size_in_bytes#assuming each UDP packet is carried in a separate Ethernet frame
theoritical_packet_rate=((line_rate_for_the_media_in_gbps*pow(10,9))/8)/frame_size_in_bytes
udp_payload= frame_size_in_bytes-(Ethernet_header_size_in_bytes + IP_header_size_in_bytes + UDP_header_size_in_bytes)
#calculate Initial target throughput in Bytes per second 
initial_target_throughput_in_Bps= (initial_target_throughput_in_gbps*pow(10,9)/8)
initial_minimum_throughput_limit_in_Bps= (initial_minimum_throughput_limit_in_gbps*pow(10,9)/8)


def binary_search_for_optimal_throughput( results_folder, test_name, config_path,perform_validation,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,initial_minimum_throughput_limit_in_Bps,tolerance ):
    run_test()
    stop_trial_for_frame_size=collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput","./RFC-2544-throughput",False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,initial_minimum_throughput_limit_in_Bps ,tolerance)
    #print("Soumya stop_trial_for_frame_size:{}".format(stop_trial_for_frame_size))


    while( not stop_trial_for_frame_size ):
        #record the previous run throughput 
        previous_run_throughput_in_gbps= initial_target_throughput_in_gbps
        #calculate the target throughput for the next run , as earflier run could not achieve the desired throughput 
        initial_target_throughput_in_gbps=(initial_target_throughput_in_gbps-initial_minimum_throughput_limit_in_gbps)/2
        #record the present run throughput 
        present_run_throughput_in_gbps=initial_target_throughput_in_gbps
        packet_rate=((initial_target_throughput_in_gbps*pow(10,9))/8)/frame_size_in_bytes
        rest.set_udp_stream_packet_rate(packet_rate)
        initial_target_throughput_in_Bps= (initial_target_throughput_in_gbps*pow(10,9)/8)


        #sleep for configured seconds - to allow DUT to stabilize 
        time.sleep(interval_between_test_run_in_seconds)
        run_test()
        stop_trial_for_frame_size=collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput","./RFC-2544-throughput",False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance)
        
        #Now you need to check if 



        if(stop_trial_for_frame_size):
            #User should be given this information in case he wants to further find the best throughput between the last failed and last passed using Binary search.
            #in this case the user must populate the yaml file with inital throughput value 
            print("*********************Test run start*********************************")
            print("The frame per second for this run = {}".format(packet_rate))
            print("The present attempted throughput in Gbps is {}".format(present_run_throughput_in_gbps))
            print("The previous attempted throughput in Gbps was {}".format(previous_run_throughput_in_gbps))
            print("********************************************************************")
        

    

#create the test configuration
create_new_config()

#add a traffic profile - with a UDP stream application
create_traffic_profile(["UDP Stream"], "Simulated users", number_of_streams , None, test_duration_in_seconds, ssl=None)

#setting Engine Optimations for higer rate of packets Tx/RX
rest.set_agent_optimization_mode("RATE_MODE")
rest.set_agent_streaming_purpose_cpu_percent( 80 )

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


#We have set previous_run__throughput_in_gbps to zero to indicaate that the test never ran priori to executing this script.
previous_run_throughput_in_gbps=0
present_run_throughput_in_gbps=0

''' Before running the tests ; verify if the user provided non-zero value for initial_minimum_throughput_limit_in_gbps.
    If user provided non-zero value for minimum accepatble throughput then check whether this can be achieved 
    in case it cannot be acheived we need to stop the run and inform the user that he needs to lower the initial_minimum_throughput_limit_in_gbps value'''
if(initial_minimum_throughput_limit_in_gbps > 0):
    packet_rate=((initial_minimum_throughput_limit_in_gbps*pow(10,9))/8)/frame_size_in_bytes
    rest.set_udp_stream_packet_rate(packet_rate)
    initial_target_throughput_in_Bps= (initial_minimum_throughput_limit_in_gbps*pow(10,9)/8)
    run_test()
    stop_trial_for_frame_size=collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput","./RFC-2544-throughput",False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance)
    if( not stop_trial_for_frame_size):
        print("Sorry : Your specified minimum throughput limit coudl not be acheived ! You need to adjust the minimum limit and re-run test")
    else:
        binary_search_for_optimal_throughput("../test_results", "RFC-2544-udp-streaming-throughput","./RFC-2544-throughput",False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,initial_minimum_throughput_limit_in_Bps ,tolerance)
        
else:
    run_test()
    stop_trial_for_frame_size=collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput","./RFC-2544-throughput",False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance)
    #print("Soumya stop_trial_for_frame_size:{}".format(stop_trial_for_frame_size))


    while( not stop_trial_for_frame_size ):
        #record the previous run throughput 
        previous_run_throughput_in_gbps= initial_target_throughput_in_gbps
        #calculate the target throughput for the next run , as earflier run could not achieve the desired throughput 
        initial_target_throughput_in_gbps=(initial_target_throughput_in_gbps-initial_minimum_throughput_limit_in_gbps)/2
        #record the present run throughput 
        present_run_throughput_in_gbps=initial_target_throughput_in_gbps
        packet_rate=((initial_target_throughput_in_gbps*pow(10,9))/8)/frame_size_in_bytes
        rest.set_udp_stream_packet_rate(packet_rate)
        initial_target_throughput_in_Bps= (initial_target_throughput_in_gbps*pow(10,9)/8)


        #sleep for configured seconds - to allow DUT to stabilize 
        time.sleep(interval_between_test_run_in_seconds)
        run_test()
        stop_trial_for_frame_size=collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput","./RFC-2544-throughput",False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance)
        
        #Now you need to check if 



        if(stop_trial_for_frame_size):
            #User should be given this information in case he wants to further find the best throughput between the last failed and last passed using Binary search.
            #in this case the user must populate the yaml file with inital throughput value 
            print("*********************Test run start*********************************")
            print("The frame per second for this run = {}".format(packet_rate))
            print("The present attempted throughput in Gbps is {}".format(present_run_throughput_in_gbps))
            print("The previous attempted throughput in Gbps was {}".format(previous_run_throughput_in_gbps))
            print("********************************************************************")
        

#generate_report()