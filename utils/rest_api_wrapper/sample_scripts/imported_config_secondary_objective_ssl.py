import sys
sys.path.append("..")
from cyperf.utils.rest_api_wrapper.lib.REST_WRAPPER_trail import rest, create_new_config, run_test, collect_stats

#
# CyPerf API test with 1 imported test config, Primary/Secondary objectives, SSL enabled and B2B agents
test_duration = 60
#run_number=1
create_new_config()
rest.add_application("Baidu Microsoft Edge")
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
#run_test()
#collect_stats("../test_results", "Bidirectional_tput_user_constraint")
