import sys
sys.path.append("..")
from lib.REST_WRAPPER import *
from RESTasV3 import RESTasV3
from lib.Statistics import Statistics
from pprint import pprint

objective = "Simulated users"
objective_value=100
objective_unit=None
test_duration = 30
results_path = "/var/lib/jenkins/public_github/cyperf/utils/rest_api_wrapper/test_results/Automation_demo" + "_" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S")

controller_ip = sys.argv[1]
controller = RESTasV3(ipAddress=controller_ip)

# 1)	Pick a default config from the “Browse Config -> Performance “ and chose the “HTTP GET+POST Throughput (1MB Payload, 32K buffer)” config as our base config.  
controller.create_session_precanned_config(config_name="HTTP GET+POST Throughput (1MB Payload, 32K buffer)")
# 2)	Change the HTTP GET and POST size to 1280000 bytes.
app_actions = controller.get_application_actions(app_id=1) #get info about app id 1 (http app in UI)
controller.set_application_response_body(app_id=1, action_id=app_actions[0]['id'], param_id=0, value="1280000")
controller.set_application_response_body(app_id=1, action_id=app_actions[1]['id'], param_id=1, value="1280000")
# 3)	Change the TCP settings to have buffer to be 128000
controller.set_client_recieve_buffer_size_traffic_profile(value=128000)
controller.set_client_transmit_buffer_size_traffic_profile(value=128000)
# 4)	Change the objective to “Simulated Users” for 1000. 
controller.set_primary_objective(objective="Simulated users")
controller.set_traffic_profile_timeline(duration=test_duration,objective_value=objective_value,objective_unit=objective_unit)
# 5)	Change the network segment at client and server with:
#           a.	Name to be “Client Network” and Server Network”
controller.rename_network_segment(net_seg_id=1, name="Client Network")
controller.rename_network_segment(net_seg_id=2, name="Server Network")
#           b.	Change the IPs in the “IP Stack” to the IP addresses and count the same as in the “AP-3-NATS” config on both the client and server sides.
controller.set_ip_range_ip_start(ip_start="10.1.4.11", network_segment=1)
controller.set_ip_range_ip_increment(ip_increment="0.0.0.1", network_segment=1)
controller.set_ip_range_ip_count(count=60, network_segment=1)
controller.set_ip_range_gateway(gateway="10.1.4.1", network_segment=1)

controller.set_ip_range_ip_start(ip_start="10.1.2.11", network_segment=2)
controller.set_ip_range_ip_increment(ip_increment="0.0.0.1", network_segment=2)
controller.set_ip_range_ip_count(count=60, network_segment=2)
controller.set_ip_range_gateway(gateway="10.1.2.1", network_segment=2)
#           c.	Add the agent 10.0.0.11 management IP to client network and 10.0.0.12 to server network. 
controller.assign_agents_by_ip(agents_ips="10.38.166.195", network_segment=1)
controller.assign_agents_by_ip(agents_ips="10.38.166.42", network_segment=2)
#           d.	Add tags to the agent to classify 10.0.0.11 as “Client” and 10.0.0.12 as “Server” (This tagging wil help when you have a large number of agents to manage.
controller.assign_tag_to_agent(tag_list=["user:Client2"], agent_ip="10.38.166.195")
controller.assign_tag_to_agent(tag_list=["user:Server2"], agent_ip="10.38.166.42")
# 6)	Add four DUT networks, each with the IP address of the NAT. Disable the DUT for now.

controller.delete_dut(1)
for count in range(4):
    controller.add_dut()
    controller.set_active_dut_configure_host(hostname=f"10.0.1.10{count}", active=False, network_segment=count+1)

controller.set_dut_connections(connections=["1", "2", "3", "4"], network_segment=1)
controller.set_dut_connections(connections=["1", "2", "3", "4"], network_segment=2)
# 7)	Start the test. 
controller.start_test()
controller.wait_test_finished()
# 8)	In the results extract “Throughput” and “Latency” stats and put it in a CSV. 
controller.get_all_stats(csvLocation=results_path)

# 9)    Statistic validation
config_type = controller.get_config_type()
stats = Statistics(results_path)
stats_failure_list = stats.validate_mdw_stats(config_type)
if len(stats_failure_list) > 0:
    raise Exception("Following stats failed validation: {}".format(stats_failure_list))
else:
    print("All stats PASSED validation")


