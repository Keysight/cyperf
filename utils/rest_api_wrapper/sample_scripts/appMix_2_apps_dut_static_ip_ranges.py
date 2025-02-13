import sys
sys.path.append("..")
from cyperf.utils.rest_api_wrapper.lib.REST_WRAPPER_trail import rest, create_new_config, create_traffic_profile, run_test, collect_stats


# CyPerf API test with 1 Traffic profile, 3 Apps, Throughput objective, 1 DUT, static IP network ranges and B2B agents
test_duration = 60
create_new_config()
create_traffic_profile(
    apps=["Portal Chrome to Apache", "eBanking Chrome to Apache", "Social Network Chrome to Apache"],
    objective="Throughput",
    objective_value=10,
    objective_unit="Mbps",
    duration=test_duration,
)
rest.assign_agents()
rest.set_dut_host(host="1.2.3.4")
rest.set_https_health_check_port(port=8443)
rest.set_ip_range_automatic_ip(ip_auto=False, network_segment=1)
rest.set_ip_range_ip_start(ip_start="10.20.30.1", network_segment=1)
rest.set_ip_range_automatic_ip(ip_auto=False, network_segment=2)
rest.set_ip_range_ip_start(ip_start="10.20.30.2", network_segment=2)
run_test()
collect_stats("../test_results", "test_traffic_profile_1_app")
