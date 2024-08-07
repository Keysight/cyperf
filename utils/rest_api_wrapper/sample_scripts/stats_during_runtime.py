import sys, time
sys.path.append("..")
from lib.REST_WRAPPER import rest, create_new_config, create_traffic_profile, run_test, collect_stats


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
rest.start_test()
start_time = time.time()
real_time_stats = []
while time.time()-start_time < test_duration:
    real_time_stats.append({})
    for stat in rest.get_available_stats_name():
        real_time_stats[-1][stat] = rest.get_stats_values(statName=stat)
print(real_time_stats)
print('Number of read in {} seconds is {}'.format(test_duration,len(real_time_stats)))
rest.wait_test_finished()
collect_stats("../test_results", "stats_during_runtime")
