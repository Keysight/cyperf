import sys
sys.path.append("..")
from cyperf.utils.rest_api_wrapper.lib.REST_WRAPPER_trail import rest, create_new_config, create_attack_profile, create_traffic_profile, run_test, collect_stats


# CyPerf API test with 1 Attack profile, 1 Strike, 1 Traffic profile, 1 App, and B2B agents
test_duration = 60
create_new_config()
create_attack_profile(
    attacks=["Portal XSS Attack on Apache server"],
    objective_value=50,
    max_concurrent_attacks=5,
    duration=test_duration,
    ssl="tls12Enabled",
    ssl_status=True)
create_traffic_profile(
    apps=["Portal Chrome to Apache"],
    objective="Throughput",
    objective_value=10,
    objective_unit="Mbps",
    duration=test_duration,
)
agents_IPs = rest.get_agents_ips()
rest.assign_agents_by_ip(agents_ips=agents_IPs[0], network_segment=1)
rest.assign_agents_by_ip(agents_ips=agents_IPs[1], network_segment=2)
run_test()
collect_stats("../test_results", "test_attack_profile_1_strike")
