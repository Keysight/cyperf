import sys, os
sys.path.append("..")
from lib.REST_WRAPPER import create_traffic_profile, run_test
from RESTasV3 import RESTasV3
from lib.Statistics import Statistics

# CyPerf API sample script to create new CyPerf applications using flows extracted from multiple capture files (pcap and pcapng).
# Name of the capture file will be used as name for new Cyperf app


capture_folder = "../sample_captures"
results_path = "/var/lib/jenkins/public_github/cyperf/utils/rest_api_wrapper/test_results"
objective = "Simulated users"
objective_value = 100
objective_unit =None
test_duration = 60
apps_per_test = 5


def find_pcap_files(directory):
    """Search for files with .pcap and .pcapng extensions in the given directory and subdirectories."""
    pcap_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(('.pcap', '.pcapng')):
                pcap_files.append(os.path.join(root, file))
    if not pcap_files:
        raise FileNotFoundError("No .pcap or .pcapng files found in the directory.")
    return pcap_files


if __name__ == "__main__":
    rest = RESTasV3(ipAddress=sys.argv[1])
    print("----------------------Starting to import new apps in CyPerf----------------------")

    try:
        pcap_list = find_pcap_files(capture_folder)
        print("Found the following files:")
        for file in pcap_list:
            print(file)
    except FileNotFoundError as e:
        print(e)
    
    new_cyperf_apps = []
    for capture_file in pcap_list:
        capture_name = capture_file.split("/")[-1].split(".")[0]
        app_flow_ids_exchanges = []

        #Upload local capture into CyPerf Controller
        response = rest.upload_capture(capture_file)
        response = rest.wait_event_success(apiPath=response["url"], timeout=300)
        response = rest._RESTasV3__sendGet(response["resultUrl"], 200).json()

        #Get all the capture flows and exachange packets
        capture_id = response["resourceURL"].split("/")[-1]
        capture_details = [capture_info for capture_info in rest.get_captures()["data"] if capture_info["id"]==capture_id]

        #Colect all flows id and exachanges from capture file then crete the app
        for flow in capture_details[0]["flows"]:
            app_flow_ids_exchanges.append({"app_flow_id": flow["id"], "exchanges_list":[f"{i}" for i in range(len(flow["exchanges"]))]})
        rest.create_app(app_name=capture_name, 
                              action_name=f"{capture_name} single action", 
                              capture_id=capture_id, 
                              app_flow_ids_exchanges=app_flow_ids_exchanges)
        new_cyperf_apps.append(capture_name)

    print("----------------------Starting to run a simple test with new added apps----------------------")
    for app in new_cyperf_apps:
        #Create new test session
        rest.setup()
        rest.save_config(app)

        #Apply test objectives
        rest.add_traffic_profile()
        rest.add_application(app)
        rest.set_primary_objective(objective)
        rest.set_traffic_profile_timeline(
            duration=test_duration,
            objective_value=objective_value,
            objective_unit=objective_unit
        )

        #Assign agents and run test
        rest.assign_agents()
        rest.start_test()
        rest.wait_test_finished()

        #Download stats and validate objectives
        rest.get_all_stats(f"{results_path}/{app}")
        config_type = rest.get_config_type()
        stats = Statistics(f"{results_path}/{app}")
        stats_failure_list = stats.validate_mdw_stats(config_type)
        if len(stats_failure_list) > 0:
            print("Following stats failed validation: {}".format(stats_failure_list))
        else:
            print("All stats PASSED validation, going to delete the session...")
            rest.delete_current_session()
