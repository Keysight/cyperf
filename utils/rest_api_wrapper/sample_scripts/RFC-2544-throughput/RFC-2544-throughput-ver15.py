import sys
import logging
sys.path.append("..")
from cyperf.utils.rest_api_wrapper.lib.REST_WRAPPER_trail import collect_stats_validate_throughput, rest, create_new_config, create_traffic_profile, run_test, collect_stats
import yaml
import time
#from lib.logger import logger
from cyperf.utils.rest_api_wrapper.lib.REST_WRAPPER_trail import collect_stats_validate_throughput, rest, create_new_config, create_traffic_profile, run_test, collect_stats
import yaml
import time
import pprint

from logger_config import selective_logger
from logger_config import selective_logger1
from logger_config import selective_logger2
import pprint
from lib.logger_config import selective_logger

def print_selective(message, *args, width=120):
    formatted_message = f"{message.format(*args):<{width}}"
    selective_logger.info(formatted_message)



#We have set previous_run__throughput_in_gbps & present_run_throughput_in_gbps to zero to indicaate that the test never ran prior to executing this script.
previous_run_throughput_in_gbps = 0
present_run_throughput_in_gbps  = 0

#This count is the number of time Binary search was performed for a particular Frame size to find optimal throughput 
count=0


#Specify the path of the yaml file which contains all the parameters specified by the user for RFC2544 throughput test
file_path = "./RFC-2544-throughput/parameters.yaml"

#Function defination to read the yaml file and populate local variables
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

def binary_search_for_optimal_throughput( results_folder, test_name, config_path, perform_validation, number_of_streams, Initiator_mgmt_ip,responder_mgmt_ip, initial_target_throughput_in_gbps, max_allowable_througput_in_gbps, minimum_throughput_limit_in_gbps, tolerance , direction_of_stream ):
   
    width  = 120
    global count
    count  = count+1
    initial_minimum_throughput_in_gbps = minimum_throughput_limit_in_gbps
    
    #now start the binary algoritm to search the best Throughput 
    
    print_selective('*******Binary search initiated *********************** ')
    print_selective(f"** BS = {count} ********  ")
    print_selective(f"The minimum throughput value = {minimum_throughput_limit_in_gbps} gbps")
    print_selective(f"The maximum throughput value = {max_allowable_througput_in_gbps} gbps")
    print_selective(f"The target  throughput value = {initial_target_throughput_in_gbps} gbps")
    print_selective('************************************************************************************************************')
    packet_rate                          = ((initial_target_throughput_in_gbps*pow(10,9))/8)/frame_size_in_bytes
    initial_target_throughput_in_Bps     = packet_rate * frame_size_in_bytes
    
    if(direction_of_stream == 'ClientToServer'):
      rest.set_udp_client_stream_packet_rate(packet_rate)
      
    if(direction_of_stream == 'ServerToClient'):
      rest.set_udp_server_stream_packet_rate(packet_rate)

    if(direction_of_stream == 'Bidirectional'):
      rest.set_udp_client_stream_packet_rate(packet_rate/2)
      rest.set_udp_server_stream_packet_rate(packet_rate/2)
      
   
    run_test()
    
    
    previous_run_throughput_in_gbps = 0
    present_run_throughput_in_gbps  = 0

    target_throughput_acheived      = collect_stats_validate_throughput( results_folder, test_name, config_path,perform_validation,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance, direction_of_stream)
    
    #keep track of all achived throughput values in a list 
    list_of_achieved_throughput_values=[]
    if(target_throughput_acheived):
         list_of_achieved_throughput_values.append( initial_target_throughput_in_gbps)
    while (1):
                    while( target_throughput_acheived ):
                        
                        count=count+1
                        minimum_throughput_limit_in_gbps = initial_target_throughput_in_gbps
                        
                        
                        
                        #print('****** upper half validations ************'.center(width))
                        print_selective('*******Binary search initiated ******* ')
                        print_selective(f"** BS = {count} ")
                        print_selective(f"The minimum throughput value = {minimum_throughput_limit_in_gbps} gbps")
                        print_selective(f"The maximum throughput value = {max_allowable_througput_in_gbps} gbps")
                        
                        #calculate the target throughput for the next run , as earflier run could not achieve the desired throughput 
                        initial_target_throughput_in_gbps= minimum_throughput_limit_in_gbps + (max_allowable_througput_in_gbps - minimum_throughput_limit_in_gbps)/2
                        print_selective(f"The target  throughput value = {initial_target_throughput_in_gbps} gbps")
                        print_selective('************************************************************************************************************')
                        
                        if( initial_target_throughput_in_gbps < initial_minimum_throughput_in_gbps):
                            raise Exception (f" The present target throughput for this run is {initial_target_throughput_in_gbps} gbps  and is lower than minimum allowable throughput {initial_minimum_throughput_limit_in_gbps} gbps".ljust(width))
                        
                        #record the present run throughput 
                        present_run_throughput_in_gbps=initial_target_throughput_in_gbps
                        previous_run_throughput_in_gbps=minimum_throughput_limit_in_gbps
                        packet_rate=((present_run_throughput_in_gbps*pow(10,9))/8)/frame_size_in_bytes
                        #print (f"Packet rate = {packet_rate}".ljust(width))
                        #rest.set_udp_stream_packet_rate(packet_rate)
                        if(direction_of_stream == 'ClientToServer'):
                            rest.set_udp_client_stream_packet_rate(packet_rate)
      
                        if(direction_of_stream == 'ServerToClient'):
                                rest.set_udp_server_stream_packet_rate(packet_rate)

                        if(direction_of_stream == 'Bidirectional'):
                                rest.set_udp_client_stream_packet_rate(packet_rate/2)
                                rest.set_udp_server_stream_packet_rate(packet_rate/2)

                        #
                        present_target_throughput_in_Bps= (present_run_throughput_in_gbps*pow(10,9)/8)


                        #sleep for configured seconds - to allow DUT to stabilize 
                        time.sleep(interval_between_test_run_in_seconds)

                        #print_selective(f"before entering run() the list of acheived values = {list_of_achieved_throughput_values}")
                        if ( len(list_of_achieved_throughput_values) < 2):
                             run_test()
                        else: 
                            if( resolution < abs (list_of_achieved_throughput_values[-1] - list_of_achieved_throughput_values[-2])):
                                 run_test()
                            else:
                                break
                        target_throughput_acheived=collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput", config_path ,False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,present_target_throughput_in_Bps,tolerance,direction_of_stream)
                        #initial_target_throughput_in_gbps = present_run_throughput_in_gbps
                        if(not target_throughput_acheived):
                            print_selective(f"The target throughput of {present_run_throughput_in_gbps} gbps could not be acheived within the tolerance level")
                            minimum_throughput_limit_in_gbps = previous_run_throughput_in_gbps

                        if(target_throughput_acheived):
                            list_of_achieved_throughput_values.append(present_run_throughput_in_gbps)
                            print(" ")

                    while( not target_throughput_acheived ):
                        count=count+1
                        #sweep to bottom half as the initial target throughput failed
                        #Record the previous run throughput 
                        max_allowable_througput_in_gbps = initial_target_throughput_in_gbps

                        print_selective('\n*****************Binary search initiated **************************************')
                        print_selective(f"*** Binary Search count  = {count} ")
                        #print('*****************Lower half validations *******************'.ljust(width))
                        print_selective(f"maximum allowable throughput =  {max_allowable_througput_in_gbps} gbps ")
                        print_selective(f"minimum throughput limit     =  {minimum_throughput_limit_in_gbps} gbps ")
                        #calculate the target throughput for the next run , as earlier run could not achieve the desired throughput 
                        initial_target_throughput_in_gbps =  minimum_throughput_limit_in_gbps + ( max_allowable_througput_in_gbps- minimum_throughput_limit_in_gbps)/2
                        if( initial_target_throughput_in_gbps < initial_minimum_throughput_limit_in_gbps):
                            raise Exception (" The present target throughput for this run is {} and is lower than minimum allowable throughput {}".format(initial_target_throughput_in_gbps,initial_minimum_throughput_limit_in_gbps))
                        
                        #print(f"Present throughput = {initial_target_throughput_in_gbps} gbps ".ljust(width))
                        print_selective(f"The target throughput value = {initial_target_throughput_in_gbps} gbps")
                        print_selective('************************************************************************************************************'.ljust(width))
                        
                        #record the present run throughput 
                        present_run_throughput_in_gbps=initial_target_throughput_in_gbps
                        previous_run_throughput_in_gbps=max_allowable_througput_in_gbps
                        #packet_rate=((initial_target_throughput_in_gbps*pow(10,9))/8)/frame_size_in_bytes
                        packet_rate=((present_run_throughput_in_gbps*pow(10,9))/8)/frame_size_in_bytes
                        #rest.set_udp_stream_packet_rate(packet_rate)
                        if(direction_of_stream == 'ClientToServer'):
                            rest.set_udp_client_stream_packet_rate(packet_rate)
      
                        if(direction_of_stream == 'ServerToClient'):
                                rest.set_udp_server_stream_packet_rate(packet_rate)

                        if(direction_of_stream == 'Bidirectional'):
                                rest.set_udp_client_stream_packet_rate(packet_rate/2)
                                rest.set_udp_server_stream_packet_rate(packet_rate/2)


                        #print (f"Packet rate = {packet_rate} ".ljust(width))
                        present_target_throughput_in_Bps= packet_rate * frame_size_in_bytes

                        #sleep for configured seconds - to allow DUT to stabilize in between binary search runs for the frame size 
                        time.sleep(interval_between_test_run_in_seconds)
                        
                        #print_selective(f"before entering run()before entering run() teh list of acheived values = {list_of_achieved_throughput_values}")
                        if ( len(list_of_achieved_throughput_values) < 2):
                             run_test()
                        else: 
                            if( resolution < abs (list_of_achieved_throughput_values[-1] - list_of_achieved_throughput_values[-2])):
                                 run_test()
                            else:
                                break
                        target_throughput_acheived = collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput",config_path,False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,present_target_throughput_in_Bps,tolerance ,direction_of_stream )
                        #initial_target_throughput_in_gbps = present_run_throughput_in_gbps
                        if(not target_throughput_acheived):
                            print_selective(f"******** The target throughput of {present_run_throughput_in_gbps} gbps could not be acheived within the tolerance level")
                            


                        if(target_throughput_acheived):
                            list_of_achieved_throughput_values.append(present_run_throughput_in_gbps)
                            max_allowable_througput_in_gbps = previous_run_throughput_in_gbps
                    
                    if ( len(list_of_achieved_throughput_values) < 2):
                        continue
                    else: 
                        if( resolution < abs (list_of_achieved_throughput_values[-1] - list_of_achieved_throughput_values[-2])):
                            continue
                        else:
                            count=0
                            break
    if(len(list_of_achieved_throughput_values)>1):
         print_selective( f"**********  The list of achieved throughput (gbps) was ={list_of_achieved_throughput_values}  **************************************") 
         highest_tput = max(list_of_achieved_throughput_values)
         print_selective( f"**********  The highest  throughput (gbps) acheived was = {highest_tput}  *************************************************************")               
    
#User inputs read from yaml file
yaml_dict = read_yaml_file(file_path)

line_rate_for_the_media_in_gbps         = yaml_dict['line_rate_for_the_media_in_gbps']
max_allowable_througput_in_gbps         = yaml_dict['max_allowable_througput_in_gbps']
initial_target_throughput_in_gbps       = yaml_dict['initial_target_throughput_in_gbps']
initial_minimum_throughput_limit_in_gbps= yaml_dict['initial_minimum_throughput_limit_in_gbps']

#initial_target_throughput_in_gbps_client_serever = yaml_dict['initial_target_throughput_in_gbps_client_serever']
#initial_target_throughput_in_gbps_serever_client = yaml_dict['initial_target_throughput_in_gbps_serever_client']

tolerance                               = yaml_dict['tolerance']
resolution                              = yaml_dict['resolution']
list_of_frame_size_in_bytes             = yaml_dict['list_of_frame_size_in_bytes']
direction_of_stream                     = yaml_dict['direction_of_stream']
number_of_streams                       = yaml_dict['number_of_streams']
number_of_trials                        = yaml_dict['number_of_trials'] 

test_duration_in_seconds                = yaml_dict['test_duration_in_seconds']
interval_between_test_run_in_seconds    = yaml_dict['interval_between_test_run_in_seconds']
Ethernet_header_size_in_bytes           = yaml_dict['Ethernet_header_size_in_bytes']
IP_header_size_in_bytes                 = yaml_dict['IP_header_size_in_bytes']
UDP_header_size_in_bytes                = yaml_dict['UDP_header_size_in_bytes']
Initiator_mgmt_ip                       = yaml_dict['Initiator_mgmt_ip']
responder_mgmt_ip                       = yaml_dict['responder_mgmt_ip']

#User Input read from yaml file - Emulated IP endpoints for client and Server 
client_start_ip = yaml_dict['client_start_ip']
client_gateway  = yaml_dict['client_gateway']
Server_start_ip = yaml_dict['Server_start_ip']
server_gateway  = yaml_dict['server_gateway']

#rate control while ramp-up phase
Max_pending_simulated_user_in_percentage = yaml_dict['Max_pending_simulated_user_in_percentage']
Max_simulated_users_per_second = yaml_dict['Max_simulated_users_per_second']

Max_BS_count     = yaml_dict['Max_BS_count']

#sanitize the throughput values entered by the user
if (initial_minimum_throughput_limit_in_gbps <= 0 or initial_target_throughput_in_gbps <0 or max_allowable_througput_in_gbps <0 ) :
        raise Exception("any throughput values  < 0 is not acceptable. Please re-check the throughput values")
if ( initial_target_throughput_in_gbps >  max_allowable_througput_in_gbps ) :
        raise Exception("initial_target_throughput_in_gbps cannot be greater than max_allowable_througput_in_gbps")
if ( initial_minimum_throughput_limit_in_gbps > initial_target_throughput_in_gbps  ) :
        raise Exception("initial_minimum_throughput_limit_in_gbps cannot be greater than  initial_target_throughput_in_gbps")
if ( initial_minimum_throughput_limit_in_gbps >  max_allowable_througput_in_gbps ) :
        raise Exception("initial_minimum_throughput_limit_in_gbps cannot be greater than  max_allowable_througput_in_gbps")


###==========================================================================####
#create the test configuration
create_new_config()

#add a traffic profile - with a UDP stream application
create_traffic_profile(["UDP Stream"], "Simulated users", number_of_streams , None, test_duration_in_seconds, ssl=None)

#setting Engine Optimations for higer rate of packets Tx/RX
#rest.set_agent_optimization_mode("RATE_MODE")
#rest.set_agent_streaming_purpose_cpu_percent( 80 )

#update the rate control settings in rampup phase 
rest.set_max_pending_simulated_user_in_percentage(Max_pending_simulated_user_in_percentage)
rest.set_max_simulated_users_per_second(Max_simulated_users_per_second)

#direction settings - UDP Streaming activity; Presently there is only one application / activity
rest.set_udp_stream_direction(direction_of_stream)
#rest.set_udp_stream_payload_size(frame_size_in_bytes - (Ethernet_header_size_in_bytes + IP_header_size_in_bytes + UDP_header_size_in_bytes))
####

rest.assign_agents_udp_streaming(Initiator_mgmt_ip,responder_mgmt_ip)

#Turn off automatic setting on the IPrange of the client network segment 
rest.set_automatic_ip_range_inactive(1,1)
#Turn off automatic setting on the IPrange of the Server network segment 
rest.set_automatic_ip_range_inactive(2,1)

#Turn MSS to Auto on bothe initiator and responder
rest.set_agent_mss_to_automatic(1,1)
rest.set_agent_mss_to_automatic(2,1)

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

store_list_of_frame_size = list_of_frame_size_in_bytes
validator_path=""
for i in range(number_of_trials):
    i=i+1
    print_selective(f"\n************* Trail # {i} ******************\n")
    while(list_of_frame_size_in_bytes):
            print_selective(f"                                                                                ")
            print_selective(f"\n************* Frame size # { list_of_frame_size_in_bytes[-1]} ******************\n")
            print_selective(f"                                                                               ")
            frame_size_in_bytes            = list_of_frame_size_in_bytes.pop()
            #assuming each UDP packet is carried in a separate Ethernet frame
            packet_rate                             =((initial_minimum_throughput_limit_in_gbps*pow(10,9))/8)/frame_size_in_bytes
            udp_payload                             = frame_size_in_bytes-(Ethernet_header_size_in_bytes + IP_header_size_in_bytes + UDP_header_size_in_bytes)
            min_target_throughput_in_Bps            = packet_rate*frame_size_in_bytes
            
            if(direction_of_stream == 'ClientToServer' ):
                rest.set_udp_client_stream_payload_size(udp_payload)
                rest.set_udp_client_stream_packet_rate(packet_rate)
                validator_path="/RFC-2544-throughput/RFC-2544-throughput-validator-C-S"
            if(direction_of_stream == 'ServerToClient' ):
                rest.set_udp_server_stream_payload_size(udp_payload)
                rest.set_udp_server_stream_packet_rate(packet_rate)
                validator_path="./RFC-2544-throughput/RFC-2544-throughput-validator-S-C"
            if(direction_of_stream == 'Bidirectional'):
                rest.set_udp_client_stream_payload_size(udp_payload)
                rest.set_udp_client_stream_packet_rate(packet_rate/2)
                rest.set_udp_server_stream_payload_size(udp_payload)
                rest.set_udp_server_stream_packet_rate(packet_rate/2)
                validator_path="./RFC-2544-throughput/RFC-2544-throughput-validators"
                #min_target_throughput_in_Bps = min_target_throughput_in_Bps * 2
                

            
            run_test()
        
            target_throughput_acheived     = collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput",validator_path,False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,min_target_throughput_in_Bps,tolerance,direction_of_stream)
            if( not target_throughput_acheived):
                print_selective(f"\n******* Your specified minimum throughput limit with frame size of {frame_size_in_bytes} Bytes could not be acheived ! You need to adjust the minimum throughput limit or the tolerance value and re-run test  *********")
                print_selective(" *********continuing with the next frame size ***************************************************************************************\n")
                continue
            else:
                #if(direction_of_stream == 'Bidirectional'):
                #   initial_target_throughput_in_gbps = initial_target_throughput_in_gbps * 2
                #    max_allowable_througput_in_gbps = max_allowable_througput_in_gbps *2
                #   initial_minimum_throughput_limit_in_gbps = initial_minimum_throughput_limit_in_gbps *2
                
                initial_target_throughput_in_Bps   = (initial_target_throughput_in_gbps*pow(10,9)/8)
                theoritical_packet_rate            = ( (line_rate_for_the_media_in_gbps * pow(10,9))/8 )/frame_size_in_bytes
                packet_rate                        = ( (initial_target_throughput_in_gbps * pow(10,9))/8 )/frame_size_in_bytes
                #set up packet rates based on the stream direction
                if(direction_of_stream == 'ClientToServer' ):
                    rest.set_udp_client_stream_packet_rate(packet_rate)
                if(direction_of_stream == 'ServerToClient' ):
                    rest.set_udp_server_stream_packet_rate(packet_rate)
                if(direction_of_stream == 'Bidirectional'):
                    rest.set_udp_client_stream_packet_rate(packet_rate/2)
                    rest.set_udp_server_stream_packet_rate(packet_rate/2)
                    #initial_target_throughput_in_Bps = initial_target_throughput_in_Bps *2
                    
                     
                
                binary_search_for_optimal_throughput("../test_results", "RFC-2544-udp-streaming-throughput",validator_path ,False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_gbps ,max_allowable_througput_in_gbps,initial_minimum_throughput_limit_in_gbps ,tolerance, direction_of_stream )
    
    #Restore the list for next trial 
    list_of_frame_size_in_bytes = store_list_of_frame_size          
        
