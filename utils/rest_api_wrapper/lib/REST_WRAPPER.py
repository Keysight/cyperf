import os
import sys
import time
import datetime
from RESTasV3 import RESTasV3
from .Statistics import Statistics

mdw_address = sys.argv[1]
rest = RESTasV3(ipAddress=mdw_address)


def create_new_config(config_path=None):
    """
    Creates an empty CyPerf config with network assigned (or Imports a custom config)

    config_path (str): path to the zip config file to be imported
    """
    config = config_path if config_path else None
    rest.setup(config)


def create_traffic_profile(apps, objective, objective_value, objective_unit, duration, ssl=None):
    """
    Adds a traffic profile in the current test configuration

    apps (list): the application to be added to the traffic profile (i.e. HTTP App)
    objective (str): the objective type of the traffic profile (i.e. Throughput, Simulated Users, CPS)
    objective_value (int): the value of the configured objective
    duration (int): the total time (sec.) for the objective to run
    ssl (str): the SSL version
    """

    rest.add_traffic_profile()
    for app in apps:
        rest.add_application(app)
    rest.set_primary_objective(objective)
    rest.set_traffic_profile_timeline(
        duration=duration,
        objective_value=objective_value,
        objective_unit=objective_unit
    )
    if ssl:
        rest.set_traffic_profile_client_tls(version=ssl)
        rest.set_traffic_profile_server_tls(version=ssl)


def create_attack_profile(attacks, objective_value, max_concurrent_attacks, duration, iteration_count=0, ssl=None, ssl_status=False):
    """
    Creates an attack profile in the current test configuration

    attacks (list): the attack to be added to the attack profile (i.e. eShop Attack on Chrome browser)
    objective_value (int): the value of the attacks per seconds objective
    max_concurrent_attacks (int): the maximum no. of concurrent attacks to run
    duration (int): the total time (sec.) for the objective to run
    iteration_count (int): the number of iterations the attack profile will execute
    ssl (str): the SSL version
    """

    rest.add_attack_profile()
    for attack in attacks:
        rest.add_attack(attack)
    rest.set_attack_profile_timeline(
        duration=duration,
        objective_value=objective_value,
        max_concurrent_attacks=max_concurrent_attacks,
        iteration_count=iteration_count
    )
    if ssl:
        rest.set_attack_profile_client_tls(version=ssl, status=ssl_status)
        rest.set_attack_profile_server_tls(version=ssl, status=ssl_status)


def run_test():
    """
    Start the CyPerf test config and wait for it to finish
    """

    rest.start_test()
    rest.wait_test_finished()


def delete_test():
    """
    Deletes the current CyPerf session
    """

    rest.delete_current_session()


def collect_stats(results_folder, test_name, perform_validation=True):
    """
    Collects the test results resources as CSV files

    results_folder (str): path where to store the tests results
    test_name (str): the name of the test
    """

    results_path = os.path.join(results_folder, test_name) + "_" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    if not os.path.exists(results_path):
        os.makedirs(results_path)
    print("Saving CSV test resources to path {}".format(results_path))
    rest.get_all_stats(results_path)

    if perform_validation:
        validate_stats(results_path)


def validate_stats(results_path):
    """
    Validates the test results resources using a generic baseline validation

    results_path (str): path of the CSV tests results
    """

    config_type = rest.get_config_type()
    stats = Statistics(results_path)
    stats_failure_list = stats.validate_mdw_stats(config_type)
    if len(stats_failure_list) > 0:
        print("Following stats failed validation: {}".format(stats_failure_list))
    else:
        print("All stats PASSED validation")


def wait_for_eula(timeout=600):
    init_timeout = timeout
    count = 2

    while timeout > 0:
        response = rest.get_automation_token()
        if "KEYSIGHT SOFTWARE END USER LICENSE AGREEMENT" in response.text.upper():
            print("Keysight EULA has was prompted")
            return True
        else:
            time.sleep(count)
            timeout -= count
    else:
        raise Exception("CyPerf controller did not properly boot after timeout {}s".format(init_timeout))


def get_all_apps_from_mdw(preferred_browser_http_apps=None):
    """
    Collect all available applications from the controller and return the outpus in list format

    preferred_browser_http_apps (str): specify the browser name to gather exclusively HTTPS-based apps for it
    """
    take = 100
    skip = 0
    app_list = rest.get_applications_by_pages(take=take, skip=skip)
    rounds =  int(app_list['totalCount']/take)
    all_browsers = ["Chrome", "Firefox", "Internet Explorer", "Microsoft Edge"]
    browsers_to_search = ["Chrome", "Firefox", "Internet Explorer", "Microsoft Edge"] if preferred_browser_http_apps is None else [preferred_browser_http_apps]
    browsers_apps = []
    other_apps = []
    restricted_list = ["DNS Flood"] #ISGAPPSEC2-30650
    for i in range(rounds+1):
        for app in app_list['data']:
            for browser in browsers_to_search:
                if browser in app['Name'] and app['Name'] not in restricted_list:
                    browsers_apps.append(app['Name'])
                    break
            if app['Name'] not in browsers_apps and not(any(True for browser in all_browsers if browser in app['Name'])) and app['Name'] not in restricted_list:
                other_apps.append(app['Name'])
        skip += take
        app_list = rest.get_applications_by_pages(take=take, skip=skip)
    
    print(f"HTTP-based apps:\n{browsers_apps}")
    print(f"Non- HTTP-based apps:\n{other_apps}")
    return other_apps, browsers_apps
