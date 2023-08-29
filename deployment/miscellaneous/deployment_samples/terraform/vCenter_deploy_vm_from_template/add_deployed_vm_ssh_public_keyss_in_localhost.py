#!/usr/bin/env python
#filter out inventory data
#for the next stage pipeline
import json
import subprocess
import os
from os.path import expanduser

debug = 0
inventory=[]

output_json_str = subprocess.check_output(['terraform', 'output', '-json', 'VM_ip'])

json_object = json.loads(output_json_str)

#inventory = list(json_object['value'])
inventory = json_object

home = expanduser("~")
sshkeypath = os.path.join(home, ".ssh")

sshkeypathExst = os.path.isdir(sshkeypath)
if sshkeypathExst == 0:
    os.mkdir(sshkeypath)

for item in inventory:
 command = "ssh-keyscan {0} >> ~/.ssh/known_hosts".format(item[0])
 print command
 os.system( command )
