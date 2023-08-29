#!/usr/bin/env python
#filter out inventory data
#for the next stage pipeline
import json
import subprocess
import os

debug = 0
inventory=[]

output_json_str = subprocess.check_output(['terraform', 'output', '-json', 'VM_ip'])

json_object = json.loads(output_json_str)

#inventory = list(json_object['value'])
inventory = json_object

for item in inventory:
 print item[0]

