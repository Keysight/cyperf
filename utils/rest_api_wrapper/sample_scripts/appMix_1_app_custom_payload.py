import sys
sys.path.append("..")
from cyperf.utils.rest_api_wrapper.lib.REST_WRAPPER_trail import rest, create_new_config, create_traffic_profile, run_test, collect_stats


# CyPerf API test with 1 Traffic profile, 1 App, Throughput objective, custom payload and B2B agents
test_duration = 60
create_new_config()
create_traffic_profile(
    apps=["Portal Chrome to Apache"],
    objective="Throughput",
    objective_value=10,
    objective_unit="Mbps",
    duration=test_duration,
)
rest.set_application_custom_payload(
    appName="Portal Chrome to Apache",
    actionName="Upload Image",
    paramName="Uploaded file",
    fileName="../resources/payload_file"
)
rest.assign_agents()
run_test()
collect_stats("../test_results", "test_traffic_profile_1_app_custom_payload")
