import os
import sys
import time
import datetime
from RESTasV3 import RESTasV3
from .Statistics import Statistics
import pandas as pd
import logging 
import pprint

#from logger_config import selective_logger
from logger_config import selective_logger1
from logger_config import selective_logger2


def rename_file_with_timestamp(file_path):
    """
    Renames a file by appending a timestamp suffix to it.
    Args:
        file_path (str): The path to the file to be renamed.
    Returns:
        str: The new file path with the timestamp suffix.
    """
    # Get the file name and extension
    file_name, file_extension = os.path.splitext(file_path)
    # Generate a timestamp suffix
    timestamp_suffix = datetime.datetime.now().strftime("_%Y%m%d_%H%M%S")
    # Create the new file path with the timestamp suffix
    new_file_path = f"{file_name}{timestamp_suffix}{file_extension}"
    # Rename the file
    os.rename(file_path, new_file_path)
    return new_file_path

def remove_first_last(lst):
    if len(lst) > 2:
        return lst[2:-2]
    else:
        return []
####

# Define a function to print to the selective logger
def print_selective1(message, *args, width=120):
    formatted_message = f"{message.format(*args):<{width}}"
    selective_logger1.info(formatted_message)

def print_dictionary(dictionary):
    # Pretty-print the dictionary
    pretty_dict = pprint.pformat(dictionary)
    # Log the formatted dictionary
    #logger.info("Dictionary:")
    for line in pretty_dict.splitlines():
        selective_logger2.info(line)


mdw_address = sys.argv[1]
rest = RESTasV3(ipAddress=mdw_address)


def create_new_config(config_path=None):
    """
    Creates an empty CyPerf config with network assigned (or Imports a custom config)

    config_path (str): path to the zip config file to be imported
    """
    config = config_path if config_path else None
    rest.setup(config)


def create_traffic_profile(apps, objective, objective_value, objective_unit, duration, ssl=None):
    """
    Adds a traffic profile in the current test configuration

    apps (list): the application to be added to the traffic profile (i.e. HTTP App)
    objective (str): the objective type of the traffic profile (i.e. Throughput, Simulated Users, CPS)
    objective_value (int): the value of the configured objective
    duration (int): the total time (sec.) for the objective to run
    ssl (str): the SSL version
    """

    rest.add_traffic_profile()
    for app in apps:
        rest.add_application(app)
    rest.set_primary_objective(objective)
    rest.set_traffic_profile_timeline(
        duration=duration,
        objective_value=objective_value,
        objective_unit=objective_unit
    )
    if ssl:
        rest.set_traffic_profile_client_tls(version=ssl)
        rest.set_traffic_profile_server_tls(version=ssl)


def create_attack_profile(attacks, objective_value, max_concurrent_attacks, duration, iteration_count=0, ssl=None, ssl_status=False):
    """
    Creates an attack profile in the current test configuration

    attacks (list): the attack to be added to the attack profile (i.e. eShop Attack on Chrome browser)
    objective_value (int): the value of the attacks per seconds objective
    max_concurrent_attacks (int): the maximum no. of concurrent attacks to run
    duration (int): the total time (sec.) for the objective to run
    iteration_count (int): the number of iterations the attack profile will execute
    ssl (str): the SSL version
    """

    rest.add_attack_profile()
    for attack in attacks:
        rest.add_attack(attack)
    rest.set_attack_profile_timeline(
        duration=duration,
        objective_value=objective_value,
        max_concurrent_attacks=max_concurrent_attacks,
        iteration_count=iteration_count
    )
    if ssl:
        rest.set_attack_profile_client_tls(version=ssl, status=ssl_status)
        rest.set_attack_profile_server_tls(version=ssl, status=ssl_status)


def run_test():
    """
    Start the CyPerf test config and wait for it to finish
    """

    rest.start_test()
    rest.wait_test_finished()


def delete_test():
    """
    Deletes the current CyPerf session
    """

    rest.delete_current_session()


def collect_stats(results_folder, test_name, config_path,perform_validation):
    """
    Collects the test results resources as CSV files

    results_folder (str): path where to store the tests results
    test_name (str): the name of the test
    """
    print("I am in function : collect stats ")
    print(config_path)
    results_path = os.path.join(results_folder, test_name) + "_" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    if not os.path.exists(results_path):
        os.makedirs(results_path)
    print("Saving CSV test resources to path {}".format(results_path))
    rest.get_all_stats(results_path)

    if perform_validation:
        validate_stats(results_path)
    else:
        print( "perform validation is false")
        custom_validate_stats(results_path,config_path)
        
###Soumo- Collect stats validate throughput for RFC 2544##
def collect_stats_validate_throughput(results_folder, test_name, config_path,perform_validation,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance,direction_of_stream,packet_loss_tolerance):
    """
    Collects the test results resources as CSV files

    results_folder (str): path where to store the tests results
    test_name (str): the name of the test
    """
    #from .logger import logger
    results_path = os.path.join(results_folder, test_name) + "_" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    if not os.path.exists(results_path):
        os.makedirs(results_path)
    print("Saving CSV test resources to path {}".format(results_path))
    rest.get_all_stats(results_path)
    
    #check if the test tool is capable of the generating TX throughput utilizing compute power  :
    capable_of_tx_tput= validate_max_throughput(results_path,config_path,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance,direction_of_stream)
    if (not capable_of_tx_tput):
                raise Exception("Test cannot continue as the Tx throughput is not acheivable")




    #perform validation will do baseline validation ; If perform validation is False then it will do custom validation
    if perform_validation:
        validate_stats(results_path)#this will validate packet drop 
    else:
       
        validation_passed_status=custom_validate_stats(results_path,config_path)
        packet_loss_tol_validation = packet_loss_ratio(results_path,config_path,packet_loss_tolerance,direction_of_stream)
        #If the custom Validation passes then continue with throughput validation 
        if(validation_passed_status and packet_loss_tol_validation ):
           

            flag=validate_throughput(results_path,config_path,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance,direction_of_stream)
            if ( flag):
                
                return flag # now stop the trail for the frame size 
            else:
                print_selective1("\nNeed to continue -  Binary search to find the best possible throughput ****** ")
                return flag
        # if statistics validation failed continue with binary algorithm to check with reduced throughput 
        else:
            #print_selective1( "As Packet Loss is detected ,  throughput validation will not be performed.")
            if(not validation_passed_status):
                print_selective1( "As statistics validation failed, throughput validation will not be performed.")
            if( not packet_loss_tol_validation ):
                print_selective1( "As Packet Loss is detected ,  throughput validation will not be performed.")
            #print(" The next iteration of test for the same frame Size will continue running with throughput halfed ")
            return (validation_passed_status and packet_loss_tol_validation)






def custom_validate_stats(results_path,config_path):
    """
    Custom Validates the test results resources using a generic baseline validation

    results_path (str): path of the CSV tests results
    """
    #print("************* Custom statistics validation will be enforced ***************************")
    #print("***************************************************************************************")
    config_type = rest.get_config_type()
    stats = Statistics(results_path)
    stats_failure_list = stats.validate_mdw_stats(config_type,config_path)
    if len(stats_failure_list) > 0:
        print("Following stats failed validation: {}".format(stats_failure_list))
        return False
    else:
        print(f"******************All stats PASSED validation********************************")
        #print('*****************************************************************************')
        return True

###soumo##
def packet_loss_ratio(results_path, config_path ,packet_loss_tolerance, direction_of_stream):

    config_type = rest.get_config_type()
    stats = Statistics(results_path)

    file1 = 'client-streaming-statistics.csv'
    file2 = 'server-streaming-statistics.csv'
    file1 = os.path.join(stats.csvs_path, file1)
    file2 = os.path.join(stats.csvs_path, file2)
    # Read CSV files
    df1 = pd.read_csv(file1)
    df2 = pd.read_csv(file2)
    if ( direction_of_stream == 'ClientToServer'):
        sent_packets = df1['Sent Packets'].iloc[-1]
        lost_packets = df2['Lost Packets'].iloc[-1]
        percent_loss = str((lost_packets / sent_packets) * 100)+ '%'
        if (( lost_packets / sent_packets) <= packet_loss_tolerance ):
            return True
        else :
            print_selective1(f"\nClient to Server packet loss beyond tolerance limits. Loss %  = {percent_loss}")
            return False
    
    if ( direction_of_stream == 'ServerToClient'):
        sent_packets = df2['Sent Packets'].iloc[-1]
        lost_packets = df1['Lost Packets'].iloc[-1]
        percent_loss = str((lost_packets / sent_packets) * 100)+ '%'
        if (( lost_packets / sent_packets) <= packet_loss_tolerance ):
            return True
        else :
            print_selective1(f"\nServer to Client packet loss beyond tolerance limits. Loss %  = {percent_loss}")
            return False

    if ( direction_of_stream == 'Bidirectional'):
        c_sent_packets = df1['Sent Packets'].iloc[-1]
        s_lost_packets = df2['Lost Packets'].iloc[-1]
        s_sent_packets = df2['Sent Packets'].iloc[-1]
        c_lost_packets = df1['Lost Packets'].iloc[-1]

        c_s_packet_loss = s_lost_packets/ c_sent_packets
        s_c_packet_loss = c_lost_packets / s_sent_packets
        c_s_packet_loss_percent = str(c_s_packet_loss*100)+ '%'
        s_c_packet_loss_percent = str(s_c_packet_loss * 100 ) + '%'
        if ( c_s_packet_loss <= packet_loss_tolerance and s_c_packet_loss <= packet_loss_tolerance ):
            return True
        else :
            print_selective1(f"Packet Loss beyond tolerance limits.\nClient to server Loss %  = {c_s_packet_loss_percent } & server to client Loss %  = {s_c_packet_loss_percent}")
            return False


def validate_max_throughput(results_path,config_path,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance,direction_of_stream):
    throughput_fluctuation_count=0
    config_type = rest.get_config_type()
    stats = Statistics(results_path)
   
    file1 = 'client-application-user-count.csv'
    file2 = 'traffic-agents-l23-instant.csv'
    file1 = os.path.join(stats.csvs_path, file1)
    file2 = os.path.join(stats.csvs_path, file2)
    # Read CSV files
    df1 = pd.read_csv(file1)
    df2 = pd.read_csv(file2)
    #find the timestamps where the active streams becomes equal to the Simulated users 
    indices =df1[df1['User Count Per Second'] ==  number_of_streams].index
    
    #create a list of timestamps that should be reffered when calculating the throughput 
    ts_list = df1.iloc[indices, 0].tolist()
    #adjust ts_list by removing the first and the last element , to ensure a buffer and synchronization to account for active streams to stabilize 
    ts_list=remove_first_last(ts_list)
    
    #initialize dictionaries to store the points in time where you observe TX deviation 
    client_deviation    = {}
    server_deviation    = {}

    #count the number of fluctuatuions in throughput in sustain time  
    throughput_fluctuation_count = 0
    
    throughput_value_client_Tx = 0
    throughput_value_server_Tx = 0
   
    deviation_at_client_from_configured_throughput = 0
    deviation_at_server_from_configured_throughput = 0
    
    #make a buffer , discard the value of the first time stamp in sustain time  
    for ts in ts_list[0:-1]:
        # Match the values and fetch the value 
        
        throughput_value_client_Tx = df2.loc[(df2['Timestamp epoch ms'] == ts) & (df2['IP'] == Initiator_mgmt_ip), 'Bytes Sent Per Second'].iloc[0]
        throughput_value_server_Tx = df2.loc[(df2['Timestamp epoch ms'] == ts) & (df2['IP'] == responder_mgmt_ip), 'Bytes Sent Per Second'].iloc[0]

        #check if this value is within tolerance level % of the configured thoughput ( units Bytes per second(Bps) ) 
        if( direction_of_stream =='ClientToServer' ):
            deviation_at_client_from_configured_throughput  = (initial_target_throughput_in_Bps - throughput_value_client_Tx )/ initial_target_throughput_in_Bps
            if( (deviation_at_client_from_configured_throughput ) > tolerance):
                throughput_fluctuation_count= throughput_fluctuation_count + 1
                client_deviation[ts] = str( (deviation_at_client_from_configured_throughput) * 100)+"%"

        if( direction_of_stream ==' ServerToClient' ):
            deviation_at_server_from_configured_throughput  = ( initial_target_throughput_in_Bps - throughput_value_server_Tx)/ initial_target_throughput_in_Bps
            if( (deviation_at_server_from_configured_throughput) > tolerance) :
               throughput_fluctuation_count= throughput_fluctuation_count + 1
               server_deviation[ts] = str( (deviation_at_server_from_configured_throughput) * 100)+"%" 
        
        if( direction_of_stream =='Bidirectional' ):
            deviation_at_client_from_configured_throughput = ( ((initial_target_throughput_in_Bps)/2) - ( throughput_value_client_Tx ))/initial_target_throughput_in_Bps
            deviation_at_server_from_configured_throughput = ( ((initial_target_throughput_in_Bps)/2) -  (throughput_value_server_Tx))/ initial_target_throughput_in_Bps
            
            if( (deviation_at_client_from_configured_throughput ) > tolerance or (deviation_at_server_from_configured_throughput) > tolerance) :
                throughput_fluctuation_count = throughput_fluctuation_count + 1 
                client_deviation[ts] = str( (deviation_at_client_from_configured_throughput) * 100)+"%"
                server_deviation[ts] = str( (deviation_at_server_from_configured_throughput) * 100)+"%"
                
        
    #Print the outcome of the results before scheduling the next Run of the test 
    if (throughput_fluctuation_count ==0 ):
        tol=str(tolerance*100)+"%"
        #print_selective1(f"*****Test set up capable to generate TX throughput - Ready to proceed with validations *****************")
        tput_gbps=(initial_target_throughput_in_Bps*8)/pow(10,9)
        #print_selective1(f"The Tx throughput of {tput_gbps} gbps was acheived considering the throughput fluctuation tolerance level of {tol}\n")
        #print_selective1(f"********************************************************************************************")
        return True
    else:
        tol=str(tolerance*100)+"%"
        tput_gbps=(initial_target_throughput_in_Bps*8)/pow(10,9)
        print_selective1(f"******************************************* Analysis **********************************************")
        print_selective1(f"The TX throughput of {tput_gbps} gbps could not be generated considering the tolerance level of {tol}")
        print_selective1(f"The reason for not able to attain the desired TX throughput required for test may be the following")
        #print_selective1(f"1. The NIC driver at the initiator may be dropping packets  \n")
        print_selective1(f"[1].More compute may be required for agents to acheive the Tx throughput. Check by assigning additional  CPU cores to the agents")
        print_selective1(f"[2].You may want to increase the number of streams in the parameters.yaml")


        #print_selective1(f"There is no packet loss . There may be throughput fluctuations  \n")
        if(throughput_fluctuation_count> 0 ):
            if(direction_of_stream == 'ClientToServer'):
              print_selective1(f"***** Timestamped TX throughput fluctions at client  from configured value ***********************************\n")
              print_dictionary(client_deviation)
              print_selective1(f"***********************************Test is aborted *********************************************** \n")
              rename_file_with_timestamp('selective_report_.log')

            if(direction_of_stream == 'ServerToClient'):
              print_selective1(f"\n***** Timestamped TX throughput fluctions at server  from configured value  ********************************\n")
              print_dictionary(server_deviation)
              print_selective1(f"***********************************Test is aborted *********************************************** \n")
              rename_file_with_timestamp('selective_report_.log')


            if(direction_of_stream == 'Bidirectional'):
               print_selective1(f"***** Timestamped TX throughput fluctions at client  from configured value ****************************\n")
               print_dictionary(client_deviation)
               print_selective1(f"\n***** Timestamped TX throughput fluctions at server  from configured value  *************************\n")
               print_dictionary(server_deviation) 
               print_selective1(f"***********************************Test is aborted *************************************** \n")
               rename_file_with_timestamp('selective_report_.log')

        
        return False





def validate_throughput(results_path,config_path,number_of_streams,Initiator_mgmt_ip,responder_mgmt_ip,initial_target_throughput_in_Bps,tolerance,direction_of_stream):
    
    throughput_fluctuation_count=0
    config_type = rest.get_config_type()
    stats = Statistics(results_path)
  
    
    file1 = 'client-application-user-count.csv'
    file2 = 'traffic-agents-l23-instant.csv'
    file1 = os.path.join(stats.csvs_path, file1)
    file2 = os.path.join(stats.csvs_path, file2)
    # Read CSV files
    df1 = pd.read_csv(file1)
    df2 = pd.read_csv(file2)
    #find the timestamps where the active streams becomes equal to the Simulated users 
    indices =df1[df1['User Count Per Second'] ==  number_of_streams].index
    
    #create a list of timestamps that should be reffered when calculating the throughput 
    ts_list = df1.iloc[indices, 0].tolist()
    #adjust ts_list by removing the first and the last element , to ensure a buffer and synchronization to account for active streams to stabilize 
    ts_list=remove_first_last(ts_list)
    
    
    client_deviation    = {}
    server_deviation    = {}
    c_s_deviation = {}
    s_c_deviation = {}
    deviation_c_s_v= 0
    deviation_s_c_v= 0
    throughput_deviation_c_s_count =0
    throughput_deviation_s_c_count =0 
    throughput_fluctuation_count = 0
    throughput_value_client_Tx = 0
    throughput_value_server_Rx = 0
    throughput_value_server_Tx = 0
    throughput_value_client_Rx = 0
    deviation_at_client_from_configured_throughput = 0
    deviation_at_server_from_configured_throughput = 0
    latency_deviation= .1
    #make a buffer , discard the value of the first time stamp in sustain time  
    for ts in ts_list[0:-1]:
        # Match the values and fetch the value 
        
        throughput_value_client_Tx = df2.loc[(df2['Timestamp epoch ms'] == ts) & (df2['IP'] == Initiator_mgmt_ip), 'Bytes Sent Per Second'].iloc[0]
        throughput_value_server_Rx = df2.loc[(df2['Timestamp epoch ms'] == ts) & (df2['IP'] == responder_mgmt_ip), 'Bytes Received Per Second'].iloc[0]
        
        throughput_value_client_Rx = df2.loc[(df2['Timestamp epoch ms'] == ts) & (df2['IP'] == Initiator_mgmt_ip), 'Bytes Received Per Second'].iloc[0]
        throughput_value_server_Tx = df2.loc[(df2['Timestamp epoch ms'] == ts) & (df2['IP'] == responder_mgmt_ip), 'Bytes Sent Per Second'].iloc[0]

        #check if this value is within tolerance level of 2% of the configured thoughput ( units Bytes per second(Bps) ) 
        if( direction_of_stream =='ClientToServer' ):
            deviation_at_client_from_configured_throughput  = (initial_target_throughput_in_Bps - throughput_value_client_Tx )/ initial_target_throughput_in_Bps
            deviation_at_server_from_configured_throughput  = (initial_target_throughput_in_Bps - throughput_value_server_Rx )/ initial_target_throughput_in_Bps
        
        if( direction_of_stream ==' ServerToClient' ):
            deviation_at_server_from_configured_throughput  = ( initial_target_throughput_in_Bps - throughput_value_server_Tx)/ initial_target_throughput_in_Bps
            deviation_at_client_from_configured_throughput  = ( initial_target_throughput_in_Bps - throughput_value_client_Rx)/ initial_target_throughput_in_Bps
        
        if( direction_of_stream =='Bidirectional' ):
            deviation_at_client_from_configured_throughput = ( initial_target_throughput_in_Bps - ( throughput_value_client_Tx + throughput_value_client_Rx))/initial_target_throughput_in_Bps
            deviation_at_server_from_configured_throughput = ( initial_target_throughput_in_Bps -  (throughput_value_server_Tx + throughput_value_server_Rx ))/ initial_target_throughput_in_Bps

        
        if( abs(deviation_at_client_from_configured_throughput ) > tolerance or abs(deviation_at_server_from_configured_throughput) > tolerance) :
           throughput_fluctuation_count = throughput_fluctuation_count + 1 
           client_deviation[ts] = str( abs(deviation_at_client_from_configured_throughput) * 100)+"%"
           server_deviation[ts] = str( abs(deviation_at_server_from_configured_throughput) * 100)+"%"
        
        if( abs(deviation_at_client_from_configured_throughput ) <= tolerance and abs(deviation_at_server_from_configured_throughput) <= tolerance) :
           #Deviation between send and recived at two ends of the probe must be within latency deviation
           if (direction_of_stream =='ClientToServer'):
                deviation_c_s_v=abs(throughput_value_client_Tx - throughput_value_server_Rx ) / throughput_value_client_Tx
                if ( abs(deviation_c_s_v) > latency_deviation ) :
                    throughput_deviation_c_s_count = throughput_deviation_c_s_count+1
                    #record the results in a dictionary 
                    print_selective1(f"At time = {ts} throughput_value_client_Tx = {throughput_value_client_Tx} & throughput_value_server_Rx ={throughput_value_server_Rx}") 
                    c_s_deviation[ts]= str( abs(deviation_c_s_v) * 100)+"%" 
           
           if (direction_of_stream =='ServerToClient'):
                deviation_s_c_v=abs(throughput_value_server_Tx - throughput_value_client_Rx ) / throughput_value_server_Tx
                if ( abs(deviation_s_c_v) > latency_deviation ) :
                    throughput_deviation_s_c_count = throughput_deviation_s_c_count+1
                    #record the results in a dictionary 
                    print_selective1(f"At time = {ts} throughput_value_server_Tx = {throughput_value_server_Tx} & throughput_value_client_Rx ={throughput_value_client_Rx}") 
                    s_c_deviation[ts]= str( abs(deviation_s_c_v) * 100)+"%" 

           if (direction_of_stream =='Bidirectional'):
                    deviation_s_c_v=abs(throughput_value_server_Tx - throughput_value_client_Rx ) / throughput_value_server_Tx
                    deviation_c_s_v=abs(throughput_value_client_Tx - throughput_value_server_Rx ) / throughput_value_client_Tx
                    if ( abs(deviation_c_s_v) > latency_deviation ) :
                        throughput_deviation_c_s_count = throughput_deviation_c_s_count+1
                        #record the results in a dictionary 
                        print_selective1(f"At time = {ts} throughput_value_client_Tx = {throughput_value_client_Tx} & throughput_value_server_Rx ={throughput_value_server_Rx}") 
                        c_s_deviation[ts]= str( abs(deviation_c_s_v) * 100)+"%"
                    
                    if ( abs(deviation_s_c_v) > latency_deviation ) :
                        throughput_deviation_s_c_count = throughput_deviation_s_c_count+1
                        print_selective1(f"At time = {ts} throughput_value_server_Tx = {throughput_value_server_Tx} & throughput_value_client_Rx ={throughput_value_client_Rx}") 
                        s_c_deviation[ts]= str( abs(deviation_s_c_v) * 100)+"%" 

    #Print the outcome of the results before scheduling the next Run of the test 
    if (throughput_fluctuation_count ==0 and throughput_deviation_c_s_count == 0 and throughput_deviation_s_c_count == 0 ):
        tol=str(tolerance*100)+"%"
        print_selective1(f"********************************** Result **********************************************************")
        tput_gbps=(initial_target_throughput_in_Bps*8)/pow(10,9)
        print_selective1(f"The throughput of {tput_gbps} gbps was acheived considering the throughput fluctuation tolerance level of {tol}\n")
        print_selective1(f"****************************************************************************************************")
        return True
    else:
        tol=str(tolerance*100)+"%"
        tput_gbps=(initial_target_throughput_in_Bps*8)/pow(10,9)
        print_selective1(f"*************** Result ***************")
        print_selective1(f"The throughput of {tput_gbps} gbps was not acheived considering the tolerance level of {tol} \n")
        print_selective1(f"There is no packet loss . There may be throughput fluctuations  \n")
        if(throughput_fluctuation_count> 0 ):
              print_selective1(f"***** Timestamped Throughput fluctions at client  from configured value *************************\n")
              #print_selective1(f"***************{tx_deviation}***********************")
              print_dictionary(client_deviation)
              print_selective1(f"\n*****Timestamped Throughput fluctions at server  from configured value  *************************\n")
              #print_selective1(f"***************{rx_deviation}***********************")
              print_dictionary(server_deviation)
        if( (direction_of_stream == 'ClientToServer'  or direction_of_stream == 'Bidirectional') and throughput_deviation_c_s_count > 0):
               #print_selective1(f"\n****** Client to Server - TX_RX_Deviation *****************************\n")
               #print_dictionary(c_s_deviation)
               #print_selective1(f"****************************************************")
               print("")
        if((direction_of_stream == 'ClientToServer' or direction_of_stream == 'Bidirectional')and throughput_deviation_s_c_count > 0):
               #print_selective1(f"\n****** server to client - TX_RX_Deviation *****************************\n")
               #print_dictionary(s_c_deviation)
               #print_selective1(f"****************************************************************************")
               print()
        #if( direction_of_stream == 'ClientToServer' and ( throughput_deviation_c_s_count or throughput_deviation_s_c_count )):

        
        return False

def validate_stats(results_path):
    """
    Validates the test results resources using a generic baseline validation

    results_path (str): path of the CSV tests results
    """

    config_type = rest.get_config_type()
    stats = Statistics(results_path)
    ###stats_failure_list = stats.validate_mdw_stats(config_type)
    stats_failure_list = stats.validate_mdw_stats(config_type,)
    if len(stats_failure_list) > 0:
        print("Following stats failed validation: {}".format(stats_failure_list))
    else:
        print("All stats PASSED validation")


def wait_for_eula(timeout=600):
    init_timeout = timeout
    count = 2

    while timeout > 0:
        response = rest.get_automation_token()
        if "KEYSIGHT SOFTWARE END USER LICENSE AGREEMENT" in response.text.upper():
            print("Keysight EULA has was prompted")
            return True
        else:
            time.sleep(count)
            timeout -= count
    else:
        raise Exception("CyPerf controller did not properly boot after timeout {}s".format(init_timeout))
