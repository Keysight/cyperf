import os
import sys
import datetime
from RESTasV3 import RESTasV3
from .Statistics import Statistics

controller_address = sys.argv[1]
rest = RESTasV3(ipAddress=controller_address)


def create_new_config(config_path=None):
    """
    Creates an empty CyPerf config with network assigned (or Imports a custom config)

    config_path (str): path to the json config file to be imported
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


def create_attack_profile(attacks, objective_value, max_concurrent_attacks, duration, iteration_count=0, ssl=None):
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
        rest.set_attack_profile_client_tls(version=ssl)
        rest.set_attack_profile_server_tls(version=ssl)


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

