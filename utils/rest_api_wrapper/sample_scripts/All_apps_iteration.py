import sys
sys.path.append("..")
from lib.REST_WRAPPER import *
from RESTasV3 import RESTasV3
from lib.Statistics import Statistics

# CyPerf API test suite iterating through all available unique apps, each test may have a variable number of apps with B2B agents

#Test details
objective = "Simulated users"
objective_value=100
objective_unit=None
test_duration = 60
apps_per_test = 5

results_path = "/path/to/save/logs"

non_http_based_apps, http_based_apps = get_all_apps_from_mdw(preferred_browser_http_apps="Chrome")
all_unique_apps = sorted(non_http_based_apps + http_based_apps, key=lambda x: x.lower())
all_unique_apps_sublist = [all_unique_apps[i: i+apps_per_test] for i in range(0,len(all_unique_apps), apps_per_test)]

print("-------------------------------Starting Apps Config tests-------------------------------")
for i in range(0, len(all_unique_apps_sublist)):
    test_name = f"Unique_Apps_{i*apps_per_test+1}-{i*apps_per_test+len(all_unique_apps_sublist[i])}"
    print(f"-------------------------------{test_name}-------------------------------")
    #Create session with custom name
    rest.setup()
    rest.save_config(test_name)

    #Apply test objectives
    create_traffic_profile(apps=all_unique_apps_sublist[i],
                           objective=objective,
                           objective_value=objective_value,
                           objective_unit=None,
                           duration=test_duration)

    #Assign agents and run test
    rest.assign_agents()
    run_test()

    #Download stats and validate objectives
    rest.get_all_stats(f"{results_path}/{test_name}")
    config_type = rest.get_config_type()
    stats = Statistics(f"{results_path}/{test_name}")
    stats_failure_list = stats.validate_mdw_stats(config_type)
    if len(stats_failure_list) > 0:
        print("Following stats failed validation: {}".format(stats_failure_list))
    else:
        print("All stats PASSED validation, going to delete the session...")
        rest.delete_current_session()
