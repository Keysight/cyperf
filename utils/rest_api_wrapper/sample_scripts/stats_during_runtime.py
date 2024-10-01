import sys, time
sys.path.append("..")
from lib.REST_WRAPPER import rest, create_new_config, create_traffic_profile, run_test, collect_stats
from pprint import pprint

# CyPerf API test with 1 Traffic profile, 1 App, Throughput objective, custom payload and B2B agents
test_duration = 30
create_new_config()
create_traffic_profile(
    apps=["Portal Chrome to Apache"],
    objective="Throughput",
    objective_value=10,
    objective_unit="Mbps",
    duration=test_duration,
)
rest.assign_agents()
rest.set_test_duration(test_duration)
rest.start_test()
start_time = time.time()
real_time_stats = {}
while time.time()-start_time < test_duration:
    for stat in rest.get_available_stats_name():
        real_time_stats[stat] = rest.get_stats_values(statName=stat)
        #take certain actions based on the live stats
   
print(real_time_stats)

print('Number of read in {} seconds is {}'.format(test_duration,len(real_time_stats)))
rest.wait_test_finished()
collect_stats("../test_results", "stats_during_runtime")
