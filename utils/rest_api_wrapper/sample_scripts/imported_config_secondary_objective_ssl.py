import sys
sys.path.append("..")
from lib.REST_WRAPPER import rest, create_new_config, run_test, collect_stats


# CyPerf API test with 1 imported test config, Primary/Secondary objectives, SSL enabled and B2B agents
test_duration = 60
create_new_config("../test_configs/B2B_MyPortal.json")
rest.set_test_duration(test_duration)
rest.set_primary_objective(objective="Throughput")
rest.add_secondary_objective()
rest.add_secondary_objective_value(objective="Simulated users", objective_value=5)
rest.set_traffic_profile_client_tls(version="TLSv1.2")
rest.set_traffic_profile_server_tls(version="TLSv1.2")
rest.assign_agents()
run_test()
collect_stats("../test_results", "test_imported_test_config_seconday_objective")