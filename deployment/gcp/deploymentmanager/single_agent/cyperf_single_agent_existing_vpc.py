#Copyright Keysight Technologies 2021.

#IMPORTANT: If the Software includes one or more computer programs bearing a Keysight copyright notice and in source code format (“Source Files”), such Source Files are subject to the terms and conditions of the Keysight Software End-User License Agreement (“EULA”) www.Keysight.com/find/sweula and these Supplemental Terms. BY USING THE SOURCE FILES, YOU AGREE TO BE BOUND BY THE TERMS AND CONDITIONS OF THE EULA INCLUDING THESE SUPPLEMENTAL TERMS. IF YOU DO NOT AGREE TO THESE TERMS AND CONDITIONS, DO NOT COPY OR DISTRIBUTE THE SOURCE FILES.
#1.	Additional Rights and Limitations. Keysight grants you a limited, non-exclusive license, without a right to sub-license, to copy and modify the Source Files solely for use with Keysight products, or systems that contain at least one Keysight product. You own any such modifications and Keysight retains all right, title and interest in the underlying Source Files. All rights not expressly granted are reserved by Keysight.
#2.            General. Capitalized terms used in these Supplemental Terms and not otherwise defined herein shall have the meanings assigned to them in the EULA. To the extent that any of these Supplemental Terms conflict with terms in the EULA, these Supplemental Terms control solely with respect to the Source Files.

def GenerateConfig(context):
  
  #varaible definations

  management_subnetwork = context.properties['management_subnetwork']

  management_subnetwork_project = context.properties['management_subnetwork_project']
  
  test_subnetwork = context.properties['test_subnetwork']

  test_subnetwork_project = context.properties['test_subnetwork_project']

  auth_username = context.properties['authUsername']

  auth_password = context.properties['authPassword']

  #auth_fingerprint = context.properties['authFingerprint']
  
  region = context.properties['region']
  
  zone = context.properties['zone']
 
  service_account_email  = context.properties['serviceAccountEmail']

  agent_base_name = context.env['deployment'] + '-cyperf-agent-'
  
  controller = context.properties['controllerip']

  sslkey = 'cyperf:' + '<Replace with ssh public key.>'


  resources = []
  
  # cyperf agents
  
  for val in range(1, int(context.properties['agentCount']) + 1):
 
    COMPUTE_AGENT_NAME = agent_base_name + str(val)
    resources.append({
      "name": COMPUTE_AGENT_NAME,
      "type": "compute.v1.instance",
      "properties": {
          "zone": zone,
          #"machineType": 'zones/' + zone + '/machineTypes/c2-standard-4',
          "machineType": 'zones/' + zone + '/machineTypes/' + context.properties['agentMachineType'],
          "metadata": {
              "kind": "compute#metadata",
              "items": [{
                      "key": "ssh-keys",
                      "value": sslkey,
                  }, {
                      'key': 'startup-script',
                      'value': ''.join(['#!/bin/bash\n',
                          'cd /home/cyperf/\n',
                          'cyperfagent configuration reload\n',
                          '/bin/bash image_init_gcp.sh %s --username \"%s\" --password \"%s\" --fingerprint \"\" >> Appsec_init_gcp_log' % (controller, auth_username, auth_password)

                      ])
                  }
  
              ],
          },
          "tags": {
              "items": ["cyperf-agents"]
          },
          "disks": [{
              "kind": "compute#attachedDisk",
              "type": "PERSISTENT",
              "mode": "READ_WRITE",
              "deviceName": "boot",
              "boot": True,
              "autoDelete": True,
              "initializeParams": {
                  "sourceImage": 'projects/' + 'kt-nas-cyperf-dev' + '/global/images/' + context.properties['agentSourceImage'],
                  "diskType": 'zones/' + zone + '/diskTypes/pd-standard',
                  "diskSizeGb": "10",
              },
              "diskEncryptionKey": {},
          }],
          "networkInterfaces": [
  
              {
                  "kind": "compute#networkInterface",
                  "subnetwork": 'projects/' + management_subnetwork_project + '/regions/' + region + '/subnetworks/' + management_subnetwork,
                  "accessConfigs": [{
                      "kind": "compute#accessConfig",
                      "name": "External NAT",
                      "type": "ONE_TO_ONE_NAT",
                      "networkTier": "PREMIUM",
                  }],
                  "aliasIpRanges": [],
              }, {
                  "kind": "compute#networkInterface",
                  "subnetwork": 'projects/' + test_subnetwork_project + '/regions/' + region + '/subnetworks/' + test_subnetwork,
                  "accessConfigs": [{
                      "kind": "compute#accessConfig",
                      "name": "External NAT",
                      "type": "ONE_TO_ONE_NAT",
                      "networkTier": "PREMIUM",
                  }],
                  "aliasIpRanges": [],
              },
          ],
          "description": "",
          "labels": {},
          "scheduling": {
              "onHostMaintenance": "MIGRATE",
              "nodeAffinities": [],
          },
          "reservationAffinity": {
              "consumeReservationType": "ANY_RESERVATION"
          },
          "serviceAccounts": [{
              "email": service_account_email,
              "scopes": ["https://www.googleapis.com/auth/cloud-platform"],
          }],
          "shieldedInstanceConfig": {},
          "confidentialInstanceConfig": {},
  
      },
      "metadata": {
          "dependsOn": [
          ],
  
      }
    })
  
  #[END use_template_with_variables]
  return {
      "resources": resources
}
