Centralized Deployment & Configuration of AppSec Agents Using Third-Party Tools Like Terraform/Ansible etc.
======================
##prerequisite
User must have a vCenter setup and hypervisors need to add in that vCenter under a cluster.  

## Terraform
1. A standard deployment tool
2. Used here for deployment of OVA in VMware vCenter

## Ansible
1. A standard configuration management tool
2. Used here for configuring VMs deployed in ESXi/vCenter
3. Used here for configuring COTS hardware

## Prepare deployment setup over standard ubuntu 18.04
```
## Execute prepare_deployment_setup.py to prepare deployment setup 
./setup/prepare_deployment_setup.sh

#            OR
# Execute bellow one by one

1. sudo apt install ansible
2. sudo apt install sshpass
3. sudo apt-get install wget
4. #Install terraform by reffering https://learn.hashicorp.com/terraform/getting-started/install.html or
https://hostadvice.com/how-to/how-to-install-infrastructure-automation-software-terraform-on-ubuntu-18-04-centos-7/
5. Download govc from https://github.com/vmware/govmomi/tree/v0.19.0/govc
```

## Create Template in vCenter from AppSec OVA
```
#Copy required ova in the current directory
1. GOVC_URL=<vCenter username>:"<vCenter password>"@<vCenter IP>/sdk GOVC_INSECURE=1 govc import.ova -ds=<datastore name> -name=cyperfAgent_<build no>_template ./<cyperf ova>
2. GOVC_URL=<vCenter username>:"<vCenter password>"@<vCenter IP>/sdk GOVC_INSECURE=1 govc vm.markastemplate cyperfAgent_<build no>_template

example:
GOVC_URL=Administrator@vsphere.local:"Ixia2012!"@10.39.32.124/sdk GOVC_INSECURE=1 govc import.ova -ds=datastore1 -name=cyperfAgent_1.0.0.637_template ./<appsec_agent_1.0.0.637.ova
GOVC_URL=Administrator@vsphere.local:"Ixia2012!"@10.39.32.124/sdk GOVC_INSECURE=1 govc vm.markastemplate cyperfAgent_1.0.0.637_template
```

## Deploy VM from AppSec Template in vCenter using Terraform
```
1. cd ./terraform/vCenter_deploy_vm_from_template
2. update ./userConfigurations.json file with relevent information

Example: 
{
        "vsphere_vcenter": "<vCenter IP>",
        "vsphere_user": "<vCenter username>",
        "vsphere_password": "<vCenter password>",
        "vsphere_datacenter": "<data center name>",
        "vsphere_cluster": "<cluser name>",
        "vsphere_datastore": "<data store name>",
        "vsphere_src_template": "<source template name>",
        "vsphere_vswitch_mgmt": "<vSwitch name>",
        "vsphere_vswitch_test": "<vSwitch name>",
        "vsphere_vm_cpu_count": 2,
        "vsphere_vm_memory_mb": 4096,
        "vm_count": <number of VM want to deploy>,
        "vm_prefix" : "<Prefix name for deployed VM>"
}

3. python3 update_tfvars.py ----> Prepare terraform tfvar file.
4. terraform init --------------> (First time only) downloads required packages for the deployment environment
5. terraform plan --------------> (OPTIONAL) a dry-run to check what changes will be made
6. terraform apply -------------> Perform the deployment
7. python list_deployed_vm_ip_addresses.py > ../../ansible/hosts --> Store deployed VM IPs required by Ansible
8. python add_deployed_vm_ssh_public_keyss_in_localhost.py --------> Add SSH public keys of the deployed VMs in localhost

```

## Configure Deployed VM (from AppSec OVA) using Ansible
```
1. cd ./ansible
2. vi variables.yml ------------------------------------------------------------------> Update variables as needed
      
      VarController: "<CyPerf Controller>"
      VarManagementInterface: "<Management interface>"
      VarTestInterface: "<Test interface>"
      VarAppsecInstaller: "<CyPerf binary>" # this is needed only for H/W installtion

example:
	
	VarController: "10.39.34.197"
	VarManagementInterface: "ens160"
	VarTestInterface: "ens192"
	VarAppsecInstaller: "tiger_x86_64_ixos-8.50_linux_debug_1.0.0.487.deb"


3. ansible-playbook playbook_configure_appsec_ova_vm.yml -i ./hosts -u cyperf -k -K --> Configure the VMs (Enter password when prompted)
```

## Configure COTS Node(s) using Ansible
```
cd ./ansible
vi hosts ---------------------------------------> Update COTS IP addresses
ssh-keyscan {Node IP} >> ~/.ssh/known_hosts ----> Store VM SSH public keys in localhost
vi variables.yml -------------------------------> Update variables as needed
ansible-playbook playbook_configure_cots_hw.yml -i ./hosts -u cyperf -k -K ----------> Configure the COTs (Enter password when prompted)
```

## Mass update
```
1. cd ./ansible
2. vi variables.yml ------------------------------------------------------------------> Update variables as needed
      
      VarController: "<CyPerf Controller>"
      VarManagementInterface: "<Management interface>"
      VarTestInterface: "<Test interface>"
      VarAppsecInstaller: "<CyPerf binary>" # this is needed only for H/W installtion

example:
	
	VarController: "10.39.34.197"
	VarManagementInterface: "ens160"
	VarTestInterface: "ens192"
	VarAppsecInstaller: "tiger_x86_64_ixos-8.50_linux_debug_1.0.0.487.deb"


3. ansible-playbook playbook_mass_update.yml -i ./hosts -u cyperf -k -K --> Configure the VMs (Enter password when prompted)
```


## Reboot Node(s) using Ansible
```
ansible-playbook playbook_reboot_node.yml -i ./hosts -u cyperf -k -K
```

## Restart portmanager service in the Node(s) using Ansible
```
ansible-playbook playbook_restart_portmanager.yml -i ./hosts -u cyperf -k -K
```
