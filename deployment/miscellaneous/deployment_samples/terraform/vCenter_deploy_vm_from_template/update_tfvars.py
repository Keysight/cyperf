#!/usr/bin/env python3
import os
import json

def GetVMName(vmPrefix, vmIndex):
    return "{\n\t"+"\thostname ="+" \""+vmPrefix+"_"+str(vmIndex)+"\"\n \t}"

def UpdateVMNames(tfVarFile, vmCount, vmPrefix):
    line="vm_name = [\n"
    file_obj.write(line)
    count=1
    for i in range(1, vmCount):
        line="\t{0},\n".format(GetVMName(vmPrefix, count))
        file_obj.write(line)
        count=count+1
    line="\t{0}\n]".format(GetVMName(vmPrefix, count))
    file_obj.write(line)

if os.path.exists("userConfigurations.json"):
    file_obj=open("terraform.tfvars",'w')
    #print("json file exists")
    with open("userConfigurations.json") as json_obj:
        input_data=json.load(json_obj)
        # print(input_data)
        for raw_key,raw_value in input_data.items():
            # print(raw_key,raw_value,"\n")
            line=str(raw_key)+" = "+ "\""+str(raw_value)+"\""+"\n"
            # print(raw_key)
            if (raw_key!="vm_count" and raw_key!="vm_prefix") :
                file_obj.write(line)
            elif (raw_key=='vm_count'):
                number_of_vms=int(raw_value)
            elif (raw_key=='vm_prefix'):
                vm_prefix=raw_value
                
            # file_obj.close()
        UpdateVMNames(file_obj, number_of_vms, vm_prefix)
        file_obj.close()
else:
    print("userConfigurations.json file not found ")
