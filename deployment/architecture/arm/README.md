### CyPerf Agent Installation on Ubuntu 20.04 VM (macOS Host)

#### Step 1: Install Required Packages on macOS

- brew install qemu
- brew install libvirt
- brew install virt-manager
- brew services start libvirt

#### Step 2: Download Ubuntu Server ISO
- Download the official Ubuntu 20.04.6 LTS Server (x86_64) [ISO or 22.04 ISO](https://releases.ubuntu.com/focal/ubuntu-20.04.6-live-server-amd64.iso) 
  
  **or**

#### Step 3: Launch Virtual Machine Manager
``` virt-manager -c "qemu:///session" --no-fork```

Create a new VM booting from the ISO image, choose x86_64 as CPU architecture, disk size 8GB, CPU/RAM as needed

#### Step 4: Create and Configure the Virtual Machine

- Boot Source: Use downloaded Ubuntu ISO
- CPU Architecture: x86_64
- Disk Size: 8 GB minimum
- CPU/RAM: Allocate as needed


#### Networking Setup
You have two options for networking:

##### Option 1: Usermode Networking (Simpler, NAT-ed)
Add two NICs, both using Usermode. Default: Can reach internet but not inbound reachable.
 

##### Option 2: Bridged Networking (Full Access on Host Network)

- macOS does not natively support bridging for QEMU. Consider switching to qemu:///system and configuring with bridge0 via pfctl or use tools like UTM or Colima for easier bridging on macOS.
- Alternatively, use Virt-Manager inside Linux VM or bare-metal Linux host for full bridging support.

#### Step 5: Install Ubuntu Server on the VM

Complete standard Ubuntu installation. After reboot, log in and proceed with network setup.

#### Step 6: Configure Networking in Ubuntu VM

##### Option A: Enable DHCP on Both NICs

1. Identify interfaces:
   ```ip a```

2. Edit Netplan config:
   ```sudo nano /etc/netplan/01-netcfg.yaml```
```
Example:
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: true
```
3. Apply changes:
   ```sudo netplan apply```

##### Option B: Static IP Configuration

1. Edit Netplan:
   ```sudo nano /etc/netplan/01-netcfg.yaml```
```
Example (enp0s8 with static IP):
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```
2. Apply settings:
   ```sudo netplan apply```

Step 7: Install CyPerf Agent

1. Download the .deb package Ex 6.0 [debian package](https://downloads.ixiacom.com/support/downloads_and_updates/public/KeysightCyPerf/releases/6.0/tiger_x86_64_ixos-8.50_combined_release_6.0.3.746.deb)
2. Copy the file into the VM:
   
   ```scp <agent.deb> username@<vm-ip>:~```
3. Install the agent:
   sudo apt install ./<agent.deb>

#### Step 8: Configure CyPerf Agent Controller
```cyperfagent controller set <controller-ip> ```
