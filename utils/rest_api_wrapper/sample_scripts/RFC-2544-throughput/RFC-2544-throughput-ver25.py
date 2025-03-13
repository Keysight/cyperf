import sys
import logging
sys.path.append("..")
from logger_config import selective_logger
from lib.REST_WRAPPER import collect_stats_validate_throughput, rest, create_new_config, create_traffic_profile, run_test, collect_stats,rename_file_with_timestamp
import yaml
import time
import math
import pprint

#set previous_run__throughput_in_gbps & present_run_throughput_in_gbps to zero to indicate that the test never ran prior to executing this script.
previous_run_throughput_in_gbps = 0
present_run_throughput_in_gbps  = 0

#This count is the number of time Binary search was performed for a particular Frame size to find optimal throughput 
count=0

#Specify the path of the yaml file which contains all the parameters specified by the user for RFC2544 throughput test
file_path = "./RFC-2544-throughput/parameters.yaml"



def print_selective(message, *args, width=120):
    formatted_message = f"{message.format(*args):<{width}}"
    selective_logger.info(formatted_message)

def remove_percent(s):
   
    if s.endswith('%'):
        return s[:-1]
    else:
        return s


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
def check_max_throughput(frame_size_in_bytes,max_allowable_througput_in_gbps,direction_of_stream,number_of_streams):
            packet_rate                             =((max_allowable_througput_in_gbps*pow(10,9))/8)/(frame_size_in_bytes* number_of_streams)
            udp_payload                             = frame_size_in_bytes-(Ethernet_header_size_in_bytes + IP_header_size_in_bytes + UDP_header_size_in_bytes)
            target_throughput_in_Bps                = packet_rate*frame_size_in_bytes * number_of_streams

            if(direction_of_stream == 'ClientToServer' ):
                rest.set_udp_client_stream_payload_size(udp_payload)
                rest.set_udp_client_stream_packet_rate(packet_rate)
                validator_path="./RFC-2544-throughput/RFC-2544-throughput-validator-C-S-TX"
            if(direction_of_stream == 'ServerToClient' ):
                rest.set_udp_server_stream_payload_size(udp_payload)
                rest.set_udp_server_stream_packet_rate(packet_rate)
                validator_path="./RFC-2544-throughput/RFC-2544-throughput-validator-S-C-TX"
            if(direction_of_stream == 'Bidirectional'):
                rest.set_udp_client_stream_payload_size(udp_payload)
                rest.set_udp_client_stream_packet_rate(packet_rate/2)
                rest.set_udp_server_stream_payload_size(udp_payload)
                rest.set_udp_server_stream_packet_rate(packet_rate/2)
                validator_path="./RFC-2544-throughput/RFC-2544-throughput-validators-TX"

            run_test()
            print_selective(f"Validating the configured maximum throughput first")
            target_throughput_acheived     = collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput",validator_path,False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,target_throughput_in_Bps,tolerance,direction_of_stream,packet_loss_tolerance )
            #print_selective(f"In process of validating the configured minimum throughput first")

def binary_search_for_optimal_throughput( results_folder, test_name, config_path, perform_validation, number_of_streams, Initiator_mgmt_ip,responder_mgmt_ip, initial_target_throughput_in_gbps, max_allowable_througput_in_gbps, minimum_throughput_limit_in_gbps, tolerance , direction_of_stream , packet_loss_tolerance ):
   
    width  = 120
    global count
    count  = count+1
    #initial_minimum_throughput_in_gbps = minimum_throughput_limit_in_gbps
    
    #The binary algoritm to search the best Throughput 
    
    print_selective('Binary search initiated  ')
    print_selective(f"** BS = {count} ********  ")
    print_selective(f"The minimum throughput value = {minimum_throughput_limit_in_gbps} gbps")
    print_selective(f"The maximum throughput value = {max_allowable_througput_in_gbps} gbps")
    print_selective(f"The target  throughput value = {initial_target_throughput_in_gbps} gbps")
    print_selective('*****************************************************************************************************')
    packet_rate                          = ((initial_target_throughput_in_gbps*pow(10,9))/8)/(frame_size_in_bytes* number_of_streams)
    initial_target_throughput_in_Bps     = packet_rate * frame_size_in_bytes * number_of_streams
    
    if(direction_of_stream == 'ClientToServer'):
      rest.set_udp_client_stream_packet_rate(packet_rate)
      
    if(direction_of_stream == 'ServerToClient'):
      rest.set_udp_server_stream_packet_rate(packet_rate)

    if(direction_of_stream == 'Bidirectional'):
      rest.set_udp_client_stream_packet_rate(packet_rate/2)
      rest.set_udp_server_stream_packet_rate(packet_rate/2)
      
   
    run_test()
    
    
    #previous_run_throughput_in_gbps = 0
    #present_run_throughput_in_gbps  = 0

    target_throughput_acheived      = collect_stats_validate_throughput( results_folder, test_name, config_path,perform_validation,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance, direction_of_stream, packet_loss_tolerance )
    
    #keep track of all achived throughput values in a list 
    list_of_achieved_throughput_values=[]
   

    bs_max = 0 
    bs_min = 0 
    bs_target = 0 

    if(target_throughput_acheived):
         list_of_achieved_throughput_values.append( initial_target_throughput_in_gbps)
         bs_max = max_allowable_througput_in_gbps
         bs_min = initial_target_throughput_in_gbps
           
    else :
         bs_max = initial_target_throughput_in_gbps
         bs_min = minimum_throughput_limit_in_gbps
         



    while (1):
                    while( target_throughput_acheived ):
                        
                        count=count+1
                        if(count > Max_BS_count):
                            break
                        
                        
                        #****** upper half validations ************
                        print_selective('Binary search initiated ')
                        print_selective(f"** BS = {count} ")
                        print_selective(f"The minimum throughput value = {bs_min} gbps")
                        print_selective(f"The maximum throughput value = {bs_max} gbps")
                        #calculate the target throughput for the next run , as earflier run could not achieve the desired throughput 
                        bs_target= (bs_max + bs_min)/2
                        print_selective(f"The target  throughput value = {bs_target} gbps")
                        print_selective('*******************************************************************************************')
                        
                        packet_rate=((bs_target*pow(10,9))/8)/(frame_size_in_bytes * number_of_streams )
                        
                        #set the packet rates as per the stream directions
                        if(direction_of_stream == 'ClientToServer'):
                            rest.set_udp_client_stream_packet_rate(packet_rate)
      
                        if(direction_of_stream == 'ServerToClient'):
                                rest.set_udp_server_stream_packet_rate(packet_rate)

                        if(direction_of_stream == 'Bidirectional'):
                                rest.set_udp_client_stream_packet_rate(packet_rate/2)
                                rest.set_udp_server_stream_packet_rate(packet_rate/2)

                        
                        present_target_throughput_in_Bps= packet_rate * frame_size_in_bytes * number_of_streams

                        #sleep for configured seconds - to allow DUT to stabilize 
                        time.sleep(interval_between_test_run_in_seconds)
 
                        #Do a resolution check for the list Throughput achieved
                        if ( len(list_of_achieved_throughput_values) < 2 ):
                             run_test()
                        else: 
                            if( resolution < abs (list_of_achieved_throughput_values[-1] - list_of_achieved_throughput_values[-2])):
                                 run_test()
                            else:
                                break
                        
                        target_throughput_acheived=collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput", config_path ,False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,present_target_throughput_in_Bps,tolerance,direction_of_stream , packet_loss_tolerance )
                        
                        if(not target_throughput_acheived):
                            print_selective(f"The target throughput of {bs_target} gbps could not be acheived")
                            bs_max = bs_target

                        if(target_throughput_acheived):
                            list_of_achieved_throughput_values.append(bs_target)
                            bs_min = bs_target
                            

                    while( not target_throughput_acheived ):
                        count=count+1
                        if(count > Max_BS_count): 
                             break
                        
                        #bs_max = bs_target
                        
                        bs_target =   ( bs_max + bs_min )/2
                        #print_selective(f"I am in Lower bs_target = {bs_target}")
                        #print_selective(f"I am in Lower bs_max = {bs_max}")
                        #*****************Lower half validations *******************'
                        print_selective('\nBinary search initiated')
                        print_selective(f"*** Binary Search count  = {count} ")
                        print_selective(f"maximum allowable throughput =  {bs_max} gbps ")
                        print_selective(f"minimum throughput limit     =  {bs_min} gbps ")
                        #calculate the target throughput for the next run , as earlier run could not achieve the desired throughput 
                        
                        #print_selective(f"bs_target= {bs_target}")
                        
                        #print(f"Present throughput = {initial_target_throughput_in_gbps} gbps ".ljust(width))
                        print_selective(f"The target throughput value = {bs_target} gbps")
                        print_selective('*******************************************************************************************'.ljust(width))
                        
                        
                        packet_rate=((bs_target*pow(10,9))/8)/(frame_size_in_bytes * number_of_streams)
                        present_target_throughput_in_Bps= packet_rate * frame_size_in_bytes * number_of_streams
                        if(direction_of_stream == 'ClientToServer'):
                            rest.set_udp_client_stream_packet_rate(packet_rate)
      
                        if(direction_of_stream == 'ServerToClient'):
                                rest.set_udp_server_stream_packet_rate(packet_rate)

                        if(direction_of_stream == 'Bidirectional'):
                                rest.set_udp_client_stream_packet_rate(packet_rate/2)
                                rest.set_udp_server_stream_packet_rate(packet_rate/2)



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
                        target_throughput_acheived = collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput",config_path,False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,present_target_throughput_in_Bps,tolerance ,direction_of_stream ,packet_loss_tolerance  )
                        #initial_target_throughput_in_gbps = present_run_throughput_in_gbps
                        if(not target_throughput_acheived):
                            print_selective(f"The target throughput of {bs_target} gbps could not be acheived ")
                            bs_max = bs_target


                        if(target_throughput_acheived):
                            list_of_achieved_throughput_values.append(bs_target)
                            bs_min = bs_target
                    
                    
                    if(count > Max_BS_count):
                         print_selective(f"The maximum limit of Binary search exceeded , aborting now for the frame size")
                         count=0
                         break

                    if ( len(list_of_achieved_throughput_values) < 2):
                        continue
                    else: 
                        if( resolution < abs (list_of_achieved_throughput_values[-1] - list_of_achieved_throughput_values[-2])):
                            continue
                        else:
                            count=0
                            break
    if(len(list_of_achieved_throughput_values)>1):
         print_selective( f"**********  Binary search is terminated as resolution is reached **************************************")
         print_selective( f"**********  The list of achieved throughput (gbps) was ={list_of_achieved_throughput_values}************************") 
         highest_tput = max(list_of_achieved_throughput_values)
         print_selective( f"**********  The highest  throughput (gbps) acheived was = {highest_tput}  *************************************")               
    
#User inputs read from yaml file
yaml_dict = read_yaml_file(file_path)

line_rate_for_the_media_in_gbps         = yaml_dict['line_rate_for_the_media_in_gbps']
max_allowable_througput_in_gbps         = yaml_dict['max_allowable_througput_in_gbps']
#initial_target_throughput_in_gbps       = yaml_dict['initial_target_throughput_in_gbps']
#This througput must be acheived by the Test , else the Test to find optimal throughput 
#for a particular frame size will be aborted
initial_minimum_throughput_limit_in_gbps= yaml_dict['initial_minimum_throughput_limit_in_gbps']
initial_target_throughput_in_gbps       = (max_allowable_througput_in_gbps + initial_minimum_throughput_limit_in_gbps)/2
tolerance                               = yaml_dict['tolerance']
resolution                              = yaml_dict['resolution']
list_of_frame_size_in_bytes             = yaml_dict['list_of_frame_size_in_bytes']
list_of_frame_size_in_bytes.reverse()             
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
#Emulated IP endpoints for client and Server 
client_start_ip                         = yaml_dict['client_start_ip']
client_gateway                          = yaml_dict['client_gateway']
Server_start_ip                         = yaml_dict['Server_start_ip']
server_gateway                          = yaml_dict['server_gateway']

#rate control while ramp-up phase
Max_pending_simulated_user_in_percentage = yaml_dict['Max_pending_simulated_user_in_percentage']
#Max_simulated_users_per_second           = yaml_dict['Max_simulated_users_per_second']
#Max_simulated_users_per_second            = 
Max_BS_count                             = yaml_dict['Max_BS_count']

packet_loss_tolerance                    = yaml_dict['packet_loss_tolerance']
#printing the parameters in the report 
print_selective(f"**********************************Test parameters ***************************************************")
print_selective(f"line rate for the media (in gbps)         =  {line_rate_for_the_media_in_gbps}")
print_selective(f"max allowable througput (in gbps)         =  {max_allowable_througput_in_gbps}")
print_selective(f"list of frame size (in bytes)             =  {list_of_frame_size_in_bytes.reverse() }")
print_selective(f"initial minimum throughput limit (in_gbps)=  {initial_minimum_throughput_limit_in_gbps}")
print_selective(f"Throughput fluctuation tolerance          =  {tolerance *100}%")
print_selective(f"resolution in Gbps                        =  {resolution}")
print_selective(f"direction of stream                       =  {direction_of_stream   }")
print_selective(f"number of streams                         =  {number_of_streams} ")
print_selective(f"number of trials                          =  {number_of_trials}"  )
print_selective(f"test duration in seconds                  =  {test_duration_in_seconds}")
print_selective(f"interval between test run in seconds      =  {interval_between_test_run_in_seconds}")
print_selective(f"Ethernet header size in bytes             =  {Ethernet_header_size_in_bytes}")
print_selective(f"IP_header size in bytes                   =  {IP_header_size_in_bytes}")
print_selective(f"UDP header size in bytes                  =  {UDP_header_size_in_bytes}")
print_selective(f"Initiator mgmt ip address                 =  {Initiator_mgmt_ip}")
print_selective(f"responder mgmt ip address                 =  {responder_mgmt_ip}")
print_selective(f"client start ip  address                  =  {client_start_ip}")
print_selective(f"client gateway   address                  =  {client_gateway}")
print_selective(f"Server start ip  address                  =  {Server_start_ip}")
print_selective(f"server gateway address                    =  {server_gateway}")
print_selective(f"Max pending simulated user in percentage  =  {Max_pending_simulated_user_in_percentage}")
#print_selective(f"Max simulated users per second            =  {Max_simulated_users_per_second}")
print_selective(f"packet loss tolerance                     =  {packet_loss_tolerance*100} % ")
print_selective(f"Max Binary search count                   =  {Max_BS_count}")

print_selective(f"****************************************************************************************************")
#sanitize the throughput values entered by the user
if (initial_minimum_throughput_limit_in_gbps <= 0 or initial_target_throughput_in_gbps <0 or max_allowable_througput_in_gbps <0 ) :
        raise Exception("any throughput values  < 0 is not acceptable. Please re-check the throughput values")
if (max_allowable_througput_in_gbps > line_rate_for_the_media_in_gbps ):
        raise Exception("The maximum allowable throughput cannot be greater than the Line rate for the Media")
if ( initial_target_throughput_in_gbps >  max_allowable_througput_in_gbps ) :
        raise Exception("initial_target_throughput_in_gbps cannot be greater than max_allowable_througput_in_gbps")
if ( initial_minimum_throughput_limit_in_gbps > initial_target_throughput_in_gbps  ) :
        raise Exception("initial_minimum_throughput_limit_in_gbps cannot be greater than  initial_target_throughput_in_gbps")
if ( initial_minimum_throughput_limit_in_gbps >  max_allowable_througput_in_gbps ) :
        raise Exception("initial_minimum_throughput_limit_in_gbps cannot be greater than  max_allowable_througput_in_gbps")


#derive the max user per second from the max pending users - set it as half the rate of max-pending-user
max_pending_streams=math.ceil(int(remove_percent(Max_pending_simulated_user_in_percentage))/100*number_of_streams)
#print(f"max_pending_streams ={max_pending_streams}\n")
max_simulated_users_per_second=math.ceil(max_pending_streams/2)
#print(f"max_simulated_users_per_second = {max_simulated_users_per_second}\n")
Max_simulated_users_per_second=str(max_simulated_users_per_second)
#print(f"Max_simulated_users_per_second ={Max_simulated_users_per_second}\n")
ramp_up_time =  math.ceil(number_of_streams/max_simulated_users_per_second)
minimum_estimated_sustain_time = ramp_up_time + 3 
if (test_duration_in_seconds <= ramp_up_time ) :
        raise Exception( " Test Duration {} seconds  is less than required ramp-up time {} seconds.Mininum recommended sustain time must be greater than {}Test Duration must be greater than the ramp-up time".format(test_duration_in_seconds,ramp_up_time))

###==========================================================================####
#Bild the test configuration in the controller from scratch 
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

#assingn the initiator and the responder agents to the desired network segmnets 
rest.assign_agents_udp_streaming(Initiator_mgmt_ip,responder_mgmt_ip)

#Turn off automatic setting on the IPrange of the client network segment 
rest.set_automatic_ip_range_inactive(1,1)
#Turn off automatic setting on the IPrange of the Server network segment 
rest.set_automatic_ip_range_inactive(2,1)

#Turn MSS to Auto on both initiator and responder
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
#This variable contains the path to the file which contains validation rules for detecting packet loss based on the steaming direction settings 
validator_path=""
for i in range(number_of_trials):
    i = i + 1
    print_selective(f"\n Trail # {i} \n")
    while(list_of_frame_size_in_bytes):
            
            print_selective(f"                                                                                ")
            print_selective(f"Frame size # { list_of_frame_size_in_bytes[-1]} \n")
            print_selective(f"                                                                               ")
            frame_size_in_bytes                     = list_of_frame_size_in_bytes.pop()
            
            #check for test tool bottle neck 
            #acheived_max_throughput =check_max_throughput(frame_size_in_bytes,max_allowable_througput_in_gbps,direction_of_stream)
            
            
            #assuming each UDP packet is carried in a separate Ethernet frame


            packet_rate                             =((initial_minimum_throughput_limit_in_gbps*pow(10,9))/8)/(frame_size_in_bytes* number_of_streams)
            udp_payload                             = frame_size_in_bytes-(Ethernet_header_size_in_bytes + IP_header_size_in_bytes + UDP_header_size_in_bytes)
            min_target_throughput_in_Bps            = packet_rate*frame_size_in_bytes * number_of_streams
            
            if(direction_of_stream == 'ClientToServer' ):
                rest.set_udp_client_stream_payload_size(udp_payload)
                rest.set_udp_client_stream_packet_rate(packet_rate)
                validator_path="./RFC-2544-throughput/RFC-2544-throughput-validator-C-S"
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
                

            #start the test
            run_test()
            print_selective(f"Validating the configured minimum throughput first")
            target_throughput_acheived     = collect_stats_validate_throughput("../test_results", "RFC-2544-udp-streaming-throughput",validator_path,False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,min_target_throughput_in_Bps,tolerance,direction_of_stream,packet_loss_tolerance )
            #print_selective(f"In process of validating the configured minimum throughput first")
            if( not target_throughput_acheived):
                print_selective(f"\nYour specified minimum throughput limit with frame size of {frame_size_in_bytes} Bytes could not be acheived !\n . You may need to re-run the test in case you suspect this as an intermitent network issue.\nYou may also to adjust the minimum throughput limit or the tolerance value and re-run test.\nYou can also try increasing the number of streams")
                if( list_of_frame_size_in_bytes ):
                    print_selective(f"Continuing with next frame size")
                    continue
                         
            else:
       

                    initial_target_throughput_in_Bps   = (initial_target_throughput_in_gbps*pow(10,9)/8)
                    theoritical_packet_rate            = ( (line_rate_for_the_media_in_gbps * pow(10,9))/8 )/frame_size_in_bytes
                    packet_rate                        = ( (initial_target_throughput_in_gbps * pow(10,9))/8 )/(frame_size_in_bytes * number_of_streams)
                    
                    #set up packet rates based on the stream direction
                    if(direction_of_stream == 'ClientToServer' ):
                        rest.set_udp_client_stream_packet_rate(packet_rate)
                    if(direction_of_stream == 'ServerToClient' ):
                        rest.set_udp_server_stream_packet_rate(packet_rate)
                    if(direction_of_stream == 'Bidirectional'):
                        rest.set_udp_client_stream_packet_rate(packet_rate/2)
                        rest.set_udp_server_stream_packet_rate(packet_rate/2)
                        
                    #start search for best throughput
                    binary_search_for_optimal_throughput("../test_results", "RFC-2544-udp-streaming-throughput",validator_path ,False,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_gbps ,max_allowable_througput_in_gbps,initial_minimum_throughput_limit_in_gbps ,tolerance, direction_of_stream,packet_loss_tolerance  )
        
    #Restore the list for next trial 
    list_of_frame_size_in_bytes = store_list_of_frame_size          
    
    if ( i == number_of_trials) :
         print_selective(f"The Test has ended . All Trails are completed")
         rename_file_with_timestamp('selective_report_.log')
