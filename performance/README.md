# Enhance traffic performance by enabling DPDK (Data Plane Development Kit)
## Introduction
CyPerf automatically detects several dependencies for DPDK (such as driver, NIC type) and tries to enable it by default on a fresh deployment. In CyPerf Controller UI, **Agent Management** page shows  the auto-detected status in **DPDK Supported*% column. The following sections contain information about the prerequisites for deployments and also explain the debugging steps if DPDK is not used automatically even if platform requirements are satisfied.
For the current CyPerf 3.0 release DPDK support for ESXi and Azure platform only.

- [DPDK on ESXi](https://www.vmware.com/content/dam/digitalmarketing/vmware/en/pdf/techpaper/intel-dpdk-vsphere-solution-brief-white-paper.pdf)
- [DPDK in Azure](https://learn.microsoft.com/en-us/azure/virtual-network/setup-dpdk?tabs=redhat)


### Troubleshooting
 
1. DPDK on ESXi not running

- Check icen driver verison and upgrade if required to support dpdk.

    This is only for Eagle/Intel e810 NICs:

    a. Enable and Login to ESXi shell and check nic info:
    ```
    esxcli network nic list
    esxcli network nic get -n vmnicX [replace X with the nic number]

    #Note: default icen version: 1.0.0.10-1vmw.702.0.0.17867351 (ice.pkg 1.3.4.0)
    ```


    b. Download icen driver package from https://customerconnect.vmware.com/downloads/get-download?downloadGroup=DT-ESXI70-INTEL-ICEN-1840

    i. Extract the *_package.zip file

    ii. Inside the extracted folder there will be another *.zip file
            
    iii. Upload this zip to the datastore in esxi

    iv. Enter maintenance mode from ESXi UI

    v. In the esxi shell run the following command to install the new icen driver (source: https://kb.vmware.com/s/article/2005205#Update_Manager):
    ```
    esxcli software vib update -d /vmfs/volumes/[datastore path to the file]/Intel-icen_1.8.4.0-1OEM.700.1.0.15843807_19474799.zip
    ```
        
    vi. Reboot the ESXi from UI

    vii. Enable SSH and Login to ESXi shell and check nic info: 
    ```      
    esxcli network nic get -n vmnicX [replace X with the nic number]

    # Note: New icen version:  1.8.4.0-1OEM.700.1.0.15843807 (ice.pkg 1.3.28.0)
    ```

    viii. Enable PCI passthrough from UI: Mange -> Hardware -> Select correct bus address -> Toggle passthrough

    ix. Add the PCI device to the CyPerf agents

3. Deploy agents on ESXi and enabling DPDK:

    a. Deploy agent OVAs on ESXi [Recommended CPU count: 24, Recommended Memory: 16GB]

    b. Enable PCI passthrough on the NIC from UI: Mange -> Hardware -> Select correct bus address -> Toggle passthrough

    c. Turn off the Agents and ddd the NIC from UI: Edit Setting -> Add other device -> PCI Device -> Select the correct Device and Bus ID

    d. (Optioanl) Set Huge pages and NUMA Affinity from UI: Edit Setting -> VM Options -> Advanced -> Edit Configuratio -> Add Parameters -> Add the following configuration:
                    sched.mem.lpage.enable1GPage = TRUE
                    numa.nodeAffinity = 0 [the NUMA# for the appropriate NIC]
    Click on OK and Save the changes

    e. (Optional) You can increase the count of CPU or increase the memory to achieve better performance from UI using VM's Edit Setting

    f. Turn on the VM

    g. Set the correct test interface using: cyperfagent interface set ens[XXX]

    h. Enable DPDK using: cyperfagent stack set ixstack (To disable DPDK use: cyperfagent stack set ixstack-raw)

    i. Add the agents to MDW and start a test
4. How to enable/disable DPDK mode

This can be done from CyPerf Controller UI. Go to **Agent Management**, select agent(s) and toggle DPDK enable/disbale state using the **Manage DPDK** button at the bottom of the table.
   
## Known Limitations
1. For the current CyPerf 3.0 release DPDK not support for AWS and GCP.



