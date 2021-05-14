import sys
sys.path.append("..")
from lib.REST_WRAPPER import rest, create_new_config, create_attack_profile, run_test, collect_stats


# CyPerf API test with 1 Attack profile, 2 Strikes, custom playlist and B2B agents
test_duration = 60
create_new_config()
create_attack_profile(
    attacks=["Portal XSS Attack on Apache server", "eBanking Attack on Chrome browser"],
    objective_value=50,
    max_concurrent_attacks=5,
    duration=test_duration,
    ssl="TLSv1.2")
rest.set_attack_custom_playlist(
    attackName="Portal XSS Attack on Apache server 1",
    actionName="Login",
    paramName="Login username",
    fileName="Strike SQLi Vector Detect MSSQL.csv"
)
rest.set_attack_custom_playlist(
    attackName="Portal XSS Attack on Apache server 1",
    actionName="Login",
    paramName="Login password",
    fileName="Strike SQLi Vector Detect MSSQL.csv"
)
rest.assign_agents()
run_test()
collect_stats("../test_results", "test_attack_profile_1_strike_custom_playlist")
