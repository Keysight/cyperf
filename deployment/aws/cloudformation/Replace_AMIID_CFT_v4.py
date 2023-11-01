####################################################################################
# Author - Kaushik Biswas Date- 2/2/2022

# This python script -
# Fetch CyPerf Marketplace AMI ID. 
# Update AMI ID for gitgub cloudformation template.

# Pre-requisite -
# Install awscli, python3, boto3.
# User need to configure awscli with their cli credential before executing this script.

# How to execute this script -
# python3 <python file name>
#####################################################################################

import urllib
import json
import fnmatch
import os
import sys
import boto3

#reload(sys)
#sys.setdefaultencoding('utf8')

# Replace CyPerf Image names published in marketplace & path for CFTs
########################################################################################################################################################################
agent_ami_name = "image-cyperf-agent-1-0-1191-master-tiger-1-0-3-614-10cb6682-8f45-4471-8f02-a4e12a7d5fb3"
application_ami_name = "cyperf-mdw-1-0-11767-releasecyperf26-92384358-5015-4a4b-aed2-8113e28d871a"
broker_ami_name = "CyPerf-Broker-2-6-0-3-39e836aa-d8d2-48e0-bf8a-a016f09c3373"
#directory path for CFTs which need AMI ID update
directory_path_of_cfts = "/Users/kabiswas/posting-public-git/cyperf/deployment/aws/cloudformation"
##########################################################################################################################################################################

class replaceAMIId():

    region_list = ['us-east-2', 'us-west-2', 'us-west-1', 'us-east-1', 'ap-south-1', 'ap-southeast-2', 'ap-northeast-2', 'ap-southeast-1', 'ap-northeast-1', 'ca-central-1', 'eu-central-1', 'eu-west-1', 'eu-west-2', 'eu-west-3', 'eu-north-1', 'sa-east-1']

    def __init__(self, replaceDir, fileExt):
        self.replaceDir = replaceDir
        self.fileExt = fileExt
        self.New_amiIDAgent = {}
        self.New_amiIDApplication = {}
        self.New_amiIDRemoteBroker = {}

        for reg in self.region_list:
           ec2_client = boto3.client('ec2', region_name=reg)

           # Response for Marketplace Agent AMI
           response_agent = ec2_client.describe_images(Filters=[{'Name': 'name', 'Values': [agent_ami_name]}])
           response_agent = response_agent.get('Images')

           # Response for Marketplace Contoller AMI
           response_app = ec2_client.describe_images(Filters=[{'Name': 'name', 'Values': [application_ami_name]}])
           response_app = response_app.get('Images')

           # Response for Marketplace Controller-proxy AMI
           response_broker = ec2_client.describe_images(Filters=[{'Name': 'name', 'Values': [broker_ami_name]}])
           response_broker = response_broker.get('Images')

           # Get AMI ID for Agent
           for i in response_agent:
              agent_image_id = i.get('ImageId')
              self.New_amiIDAgent[reg] = agent_image_id
              if agent_image_id == '':
                 raise Exception("Unable to find image id with name: " + agent_ami_name)
       
           # Get AMI ID for Controller
           for i in response_app:
              app_image_id = i.get('ImageId')
              self.New_amiIDApplication[reg] = app_image_id
              if app_image_id == '':
                 raise Exception("Unable to find image id with name: " + app_ami_name)

           # Get AMI ID for Controller-proxy
           for i in response_broker:
              broker_image_id = i.get('ImageId')
              self.New_amiIDRemoteBroker[reg] = broker_image_id
              if broker_image_id == '':
                 raise Exception("Unable to find image id with name: " + broker_ami_name)
        print("==================================================")
        print("Marketplace CyPerf Agent AMI-", self.New_amiIDAgent)
        print("==================================================")
        print("Marketplace CyPerf Controller AMI-", self.New_amiIDApplication)
        print("==================================================")
        print("Marketplace CyPerf Controller-proxy AMI-", self.New_amiIDRemoteBroker)
        print("==================================================")

    # This method replace existing AMI IDs@region
    def findReplace(self, directory, filePattern):
        for path, dirs, files in os.walk(os.path.abspath(directory)):
            for filename in fnmatch.filter(files, filePattern):
                print(filename)
                filepath = os.path.join(path, filename)
                with open(filepath, "r", encoding="utf-8") as jsonFile:
                    self.cft_dict = json.load(jsonFile)
                    if 'Mappings' in self.cft_dict:
                        print("Region mapping exits for template " + filename)  
                        for reg in self.region_list:
                            self.cft_dict['Mappings']['RegionMap'][reg]['AMIxAGENT'] = self.New_amiIDAgent[reg]
                            self.cft_dict['Mappings']['RegionMap'][reg]['AMIxAPPLICATION'] = self.New_amiIDApplication[reg]
                            self.cft_dict['Mappings']['RegionMap'][reg]['AMIxBROKER'] = self.New_amiIDRemoteBroker[reg]
                    else:
                        print("Region mapping not exits for template " + filename)                       
                with open(filepath, "w", encoding="utf-8") as jsonFile:
                    json.dump(self.cft_dict, jsonFile, indent = 4)
    # This method invoke findReplace method with parent directory of json template
    def replaceAMI(self):
        self.findReplace(self.replaceDir, self.fileExt)

AMIObj = replaceAMIId(directory_path_of_cfts, "*.json")
AMIObj.replaceAMI()
