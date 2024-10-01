import sys
sys.path.append("..")
from lib.REST_WRAPPER import *
from RESTasV3 import RESTasV3

# CyPerf API to download the CSV files of the test results from the results tab, then execute a cleanup of all the results

#Prerequisites: Ensure that no test is in progress when executing this script.

csvFolder = "/path/to/save/logs"
download_all_csv_from_controller = True
delete_all_test_results = True

rest = RESTasV3(sys.argv[1])

if download_all_csv_from_controller:
    all_test_ids = rest.get_results_test_ids()
    for test_id in all_test_ids:
        test_name = rest.get_test_display_name(test_id)
        csvLocation = csvFolder+ "/" + test_name + "_" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        os.makedirs(csvLocation)
        rest.save_csv_result(test_id, csvLocation)
else:
    print("The backup of the CSV file is being skipped")

if delete_all_test_results:
     #Removing results for an active session is not allowed.
    rest.delete_all_browse_results(delete_all_active_session=False)
else:
    print("The deletion of all test results is being skipped")

