import sys
sys.path.append("..")
from lib.REST_WRAPPER import rest, create_new_config, run_test, collect_stats


# CyPerf API test with 1 imported test config, Primary/Secondary objectives, SSL enabled and B2B agents
test_duration = 60
create_new_config("../test_configs/b2b_portal_chrome_to_apache.zip")
rest.set_primary_objective(objective="Throughput")
rest.set_test_duration(test_duration)
rest.add_secondary_objective()
rest.add_secondary_objective_value(objective="Simulated users", objective_value=5)
rest.set_traffic_profile_client_tls(version="tls12Enabled", status=True)
rest.set_traffic_profile_server_tls(version="tls12Enabled", status=True)
rest.assign_agents()
rest.enable_disable_tls_traffic_profile()
run_test()
collect_stats("../test_results", "test_imported_test_config_seconday_objective")
