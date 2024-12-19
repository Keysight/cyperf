import sys, time
sys.path.append("..")
from lib.REST_WRAPPER import rest

# CyPerf API to insert a sleep action after each strike from a custom attack

# Prerequisites:
#   - This script will work only for custom attacks.
#   - Configure application profile with only 1 app having only 1 action and then manual insert a "sleep" after this action
#   - Each custom attack profile must contain firstly these 2 actions (app action 1 and "sleep) from the app profile and then the custom strikes
#   - To run the script execute: "python add_sleep_custom_attack_profile.py <Middleware IP> <SessionID> <Sleep time in milliseconds>"

config = rest.get_session_config(sessionId=sys.argv[2])
rest.sessionID = sys.argv[2]
sleep_time = sys.argv[3]

for attack in config["Config"]["AttackProfiles"][0]["Attacks"]:
    start_insert_sleep_position = 3
    nr_of_actions = len(attack["Tracks"][0]["Actions"])
    for action in attack["Tracks"][0]["Actions"]:
        if int(action["Index"]) <= 2:
            continue
        attack_id = int(attack["id"])
        rest.insert_attack_action_at_exact_position(attack_id=attack_id, action_id="Sleep",
                                                    insert_at_position=start_insert_sleep_position)
        rest.set_attack_action_value(attack_id=attack_id, action_index=nr_of_actions+1,value=sleep_time)
        nr_of_actions+=1
        start_insert_sleep_position += 2
