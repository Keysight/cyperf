import sys
sys.path.append("..")
from lib.REST_WRAPPER import *
from RESTasV3 import RESTasV3
from lib.Statistics import Statistics

# CyPerf API test suite iterating through all strikes, each test may have a variable number of strikes with B2B agents

#Test details
test_duration = 60
attack_rate = 10
max_concurrent_attack = 10
iteration_count = 0
strikes_per_test = 300

results_path = "/path/to/save/logs"

rest = RESTasV3(sys.argv[1])
all_strikes = rest.get_strikes()
black_list = ["rudy", "slowloris", "smtp", "ftp", "strike microsoft internet explorer 9/11 mshtml remote code execution"]

c2s_exploits_ids = [strike["id"] for strike in all_strikes if strike["Metadata"]["Direction"] == "c2s" 
                                                            and ("exploit" in strike["Description"].lower() or "exploit" in strike["Connections"][0]["DisplayName"].lower())
                                                            and all(item not in strike["Connections"][0]["DisplayName"].lower() for item in black_list)]
c2s_exploits_sublist_ids = [c2s_exploits_ids[i:i+strikes_per_test] for i in range(0, len(c2s_exploits_ids), strikes_per_test)]

s2c_exploits_ids = [strike["id"] for strike in all_strikes if strike["Metadata"]["Direction"] == "s2c" 
                                                            and ("exploit" in strike["Description"].lower() or "exploit" in strike["Connections"][0]["DisplayName"].lower())
                                                            and all(item not in strike["Connections"][0]["DisplayName"].lower() for item in black_list)]
s2c_strikes_sublist_ids = [s2c_exploits_ids[i:i+strikes_per_test] for i in range(0, len(s2c_exploits_ids), strikes_per_test)]

malware_ids = [strike["id"] for strike in all_strikes if "malware" in strike["Description"].lower()
                                                                or "malware" in strike["Connections"][0]["DisplayName"].lower() 
                                                                or strike["Metadata"]["References"][-1]["Type"] == "MD5"]
malware_sublist_ids = [malware_ids[i:i+strikes_per_test] for i in range(0, len(malware_ids), strikes_per_test)]

print("-------------------------------Starting Strikes Config tests-------------------------------")

print("-------------------------------C2S strikes tests-------------------------------")
for i in range(0, len(c2s_exploits_sublist_ids)):
    test_name = f"C2S_Exploits_Test_{i+1}"
    print(f"-------------------------------{test_name}-------------------------------")
    #Create session with custom name
    rest.setup()
    rest.save_config(test_name)
    rest.add_attack_profile()

    #Apply test objectives
    rest.set_attack_profile_timeline(duration=test_duration,objective_value=attack_rate, max_concurrent_attacks=max_concurrent_attack, iteration_count=iteration_count)
    
    #Add attacks
    rest.add_customize_attack_by_id(c2s_exploits_sublist_ids[i])
    rest.rename_custom_attack(f"C2S_Exploits_{i*strikes_per_test+1}-{i*strikes_per_test+len(c2s_exploits_sublist_ids[i])}")

    #Assign agents and run test
    rest.assign_agents()
    rest.start_test(600)
    rest.wait_test_finished()

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

print("-------------------------------S2C strikes tests-------------------------------")
for i in range(0, len(s2c_strikes_sublist_ids)):
    test_name = f"S2C_Exploits_Test_{i+1}"
    print(f"-------------------------------{test_name}-------------------------------")
    #Create session
    rest.setup()
    rest.save_config(test_name)
    rest.add_attack_profile()

    #Apply test objectives
    rest.set_attack_profile_timeline(duration=test_duration,objective_value=attack_rate, max_concurrent_attacks=max_concurrent_attack, iteration_count=iteration_count)

    #Add attacks
    rest.add_customize_attack_by_id(s2c_strikes_sublist_ids[i])
    rest.rename_custom_attack(f"S2C_Exploits_{i*strikes_per_test+1}-{i*strikes_per_test+len(s2c_strikes_sublist_ids[i])}")

    #Assign agents and run test
    rest.assign_agents()
    rest.start_test(600)
    rest.wait_test_finished()
    
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


print("-------------------------------Malware strikes tests-------------------------------")
for i in range(0, len(malware_sublist_ids)):
    test_name = f"Malware_Test_{i+1}"
    print(f"-------------------------------{test_name}-------------------------------")
    #Create session
    rest.setup()
    rest.save_config(test_name)
    rest.add_attack_profile()

    #Apply test objectives
    rest.set_attack_profile_timeline(duration=test_duration,objective_value=attack_rate, max_concurrent_attacks=max_concurrent_attack, iteration_count=iteration_count)

    #Add attacks
    rest.add_customize_attack_by_id(malware_sublist_ids[i])
    rest.rename_custom_attack(f"Malware_{i*strikes_per_test+1}-{i*strikes_per_test+len(malware_sublist_ids[i])}")

    #Assign agents and run test
    rest.assign_agents()
    rest.start_test(600)
    rest.wait_test_finished()
    
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