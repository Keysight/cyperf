#Copyright Keysight Technologies 2021.

#IMPORTANT: If the Software includes one or more computer programs bearing a Keysight copyright notice and in source code format (“Source Files”), such Source Files are subject to the terms and conditions of the Keysight Software End-User License Agreement (“EULA”) www.Keysight.com/find/sweula and these Supplemental Terms. BY USING THE SOURCE FILES, YOU AGREE TO BE BOUND BY THE TERMS AND CONDITIONS OF THE EULA INCLUDING THESE SUPPLEMENTAL TERMS. IF YOU DO NOT AGREE TO THESE TERMS AND CONDITIONS, DO NOT COPY OR DISTRIBUTE THE SOURCE FILES.
#1.	Additional Rights and Limitations. Keysight grants you a limited, non-exclusive license, without a right to sub-license, to copy and modify the Source Files solely for use with Keysight products, or systems that contain at least one Keysight product. You own any such modifications and Keysight retains all right, title and interest in the underlying Source Files. All rights not expressly granted are reserved by Keysight.
#2.            General. Capitalized terms used in these Supplemental Terms and not otherwise defined herein shall have the meanings assigned to them in the EULA. To the extent that any of these Supplemental Terms conflict with terms in the EULA, these Supplemental Terms control solely with respect to the Source Files.

def GenerateConfig(context):
  
  #varaible definations
  management_network = context.env['deployment'] + '-cyperf-management-network'
  
  management_subnetwork = context.env['deployment'] + '-cyperf-management-subnetwork'
  
  management_network_cidr = context.properties['managementNetworkCIDR']
  
  test_network = context.env['deployment'] + '-cyperf-test-network'
  
  test_subnetwork = context.env['deployment'] + '-cyperf-test-subnetwork'
  
  test_network_cidr = context.properties['testNetworkCIDR']
  
  region = context.properties['region']
  
  zone = context.properties['zone']
  
  service_account_email  = context.properties['serviceAccountEmail']
  
  agent_base_name = context.env['deployment'] + '-cyperf-agent-'
  
  controller = context.env['deployment'] + '-cyperf-controller'

  sslkey = 'cyperf:' + '<Replace with ssh public key.>'


  resources = []
  
  ## cyperf Management network
  resources.append({
      "name": management_network,
      "type": "compute.v1.network",
      "properties": {
          "autoCreateSubnetworks": False,
          "routingConfig": {
              "routingMode": "REGIONAL"
          },
          "description": "managemnet network ",
          "mtu": 1460
  
      },
  })# cyperf Management subnetwork
  resources.append({
      "name": management_subnetwork,
      "type": "compute.v1.subnetwork",
      "properties": {
          "enableFlowLogs": False,
          "ipCidrRange": management_network_cidr,
          "network": 'global/networks/' + management_network,
          #'$ref(' + context.env['deployment'] + 'cyperf-management-network' + '.SelfLink)
          "privateIpGoogleAccess": True,
          "region": region,
          "secondaryIpRanges": []
      },
      "metadata": {
          "dependsOn": [
              management_network,
              test_network
          ]
      },
  })# cyperf Test Network
  resources.append({
      "name": test_network,
      "type": "compute.v1.network",
      "properties": {
          "autoCreateSubnetworks": False,
          "routingConfig": {
              "routingMode": "REGIONAL"
          },
          "description": "test network ",
          "mtu": 1460
  
      },
  })# cyperf Test Subnetwork
  resources.append({
          "name": test_subnetwork,
          "type": "compute.v1.subnetwork",
          "properties": {
              "enableFlowLogs": False,
              "ipCidrRange": test_network_cidr,
              "network": 'global/networks/' + test_network,
              #'$ref(' + context.env['deployment'] + 'cyperf-test-network' + '.SelfLink)
              "privateIpGoogleAccess": True,
              "region": region,
              "secondaryIpRanges": []
          },
          "metadata": {
              "dependsOn": [
                  management_network,
                  test_network
              ]
          },
  
      },
  
  )# cyperf Firewall
  resources.append({
      "name": context.env['deployment'] + 'vpc-mngt-firewall',
      "type": "compute.v1.firewall",
      "properties": {
          "network": 'global/networks/' + management_network,
          #'$ref(' + context.env['deployment'] + 'cyperf-management-network' + '.SelfLink)
          "priority": 100,
          "sourceRanges": ["0.0.0.0/0"],
          "destinationRanges": [],
  
          "allowed": [{
              "IPProtocol": "all"
          }, ],
          "direction": "INGRESS",
          "disabled": False,
          "enableLogging": False
      },
      "metadata": {
          "dependsOn": [
              management_network
  
  
          ]
      },
  })
  resources.append({
      "name": context.env['deployment'] + 'vpc-test-firewall',
      "type": "compute.v1.firewall",
      "properties": {
          "network": 'global/networks/' + test_network,
          #'$ref(' + context.env['deployment'] + 'test-network' + '.SelfLink)
          "priority": 100,
          "sourceRanges": ["0.0.0.0/0"],
          "destinationRanges": [],
  
          "allowed": [{
                  "IPProtocol": "all"
              }
  
          ],
          "direction": "INGRESS",
          "disabled": False,
          "enableLogging": False
      },
      "metadata": {
          "dependsOn": [
  
              test_network
          ]
      }
  })# cyperf Routes
  resources.append(
  
      {
          "name": context.env['deployment'] + 'default-internet-route-for-mngt',
          "type": "compute.v1.route",
          "properties": {
              "network": 'global/networks/' + management_network,
              #'$ref(' + context.env['deployment'] + 'cyperf-management-network' + '.SelfLink)
              "destRange": "0.0.0.0/0",
              "nextHopGateway": "global/gateways/default-internet-gateway",
              "priority": 100,
              "tags": []
          },
          "metadata": {
              "dependsOn": [
                  management_network
  
              ]
          },
      }
  )
  resources.append({
      "name": context.env['deployment'] + 'default-internet-route-for-test',
      "type": "compute.v1.route",
      "properties": {
          "network": 'global/networks/' + test_network,
          #'$ref(' + context.env['deployment'] + 'test-network' + '.SelfLink)
          "destRange": "0.0.0.0/0",
          "nextHopGateway": "global/gateways/default-internet-gateway",
          "priority": 100,
          "tags": []
      },
      "metadata": {
          "dependsOn": [
  
              test_network
  
          ]
      },
  })
        
  # cyperf Controller
  resources.append({
      "name": controller,
      "type": "compute.v1.instance",
      "properties": {
          "zone": zone,
          #"machineType": 'zones/' + zone + '/machineTypes/c2-standard-8',
          "machineType": 'zones/' + zone + '/machineTypes/' + context.properties['controllerMachineType'],
          "metadata": {
              "kind": "compute#metadata",
              "items": [{
                  "key": "ssh-keys",
                  "value": sslkey,
              }],
          },
          "tags": {
              "items": ["http-server", "https-server"]
          },
          "disks": [{
              "kind": "compute#attachedDisk",
              "type": "PERSISTENT",
              "boot": True,
              "mode": "READ_WRITE",
              "autoDelete": True,
              "deviceName": "boot",
              "initializeParams": {
                  "sourceImage": 'projects/' + 'kt-nas-cyperf-dev' + 'global/images/' + context.properties['controllerSourceImage'],
                  "diskType": 'zones/' + zone + '/diskTypes/pd-standard',
                  "diskSizeGb": "100",
                  "labels": {},
				   },
              "diskEncryptionKey": {},
          }],
          "networkInterfaces": [{
              "kind": "compute#networkInterface",
              "subnetwork": 'regions/' + region + '/subnetworks/' + management_subnetwork,
              "accessConfigs": [{
                  "kind": "compute#accessConfig",
                  "name": "External NAT",
                  "type": "ONE_TO_ONE_NAT",
                  "networkTier": "PREMIUM",
              }],
              "aliasIpRanges": [],
          }],
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
              management_subnetwork,
              test_subnetwork
          ]
      }
  })
  
  # cyperf agents
  
  for val in range(1, int(context.properties['agentCount']) + 1):
 
    CONTROLLER_NAME = controller
    print('debug\n')
    print('$(ref.%s.networkInterfaces[0].networkIP)' % CONTROLLER_NAME)
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
                          '/bin/bash image_init_gcp.sh $(ref.%s.networkInterfaces[0].networkIP) >> Appsec_init_gcp_log' % CONTROLLER_NAME
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
                  "sourceImage": 'projects/' + 'kt-nas-cyperf-dev' + 'global/images/' + context.properties['agentSourceImage'],
                  "diskType": 'zones/' + zone + '/diskTypes/pd-standard',
                  "diskSizeGb": "10",
              },
              "diskEncryptionKey": {},
          }],
          "networkInterfaces": [
  
              {
                  "kind": "compute#networkInterface",
                  "subnetwork": 'regions/' + region + '/subnetworks/' + management_subnetwork,
                  "accessConfigs": [{
                      "kind": "compute#accessConfig",
                      "name": "External NAT",
                      "type": "ONE_TO_ONE_NAT",
                      "networkTier": "PREMIUM",
                  }],
                  "aliasIpRanges": [],
              }, {
                  "kind": "compute#networkInterface",
                  "subnetwork": 'regions/' + region + '/subnetworks/' + test_subnetwork,
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
              "email": "290801949079-compute@developer.gserviceaccount.com",
              "scopes": ["https://www.googleapis.com/auth/cloud-platform"],
          }],
          "shieldedInstanceConfig": {},
          "confidentialInstanceConfig": {},
  
      },
      "metadata": {
          "dependsOn": [
              test_subnetwork,
              management_subnetwork,
              controller
          ],
  
      }
    })
  
  #[END use_template_with_variables]
  return {
      "resources": resources
}
