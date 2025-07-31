## Kubernetes Setup on Ubuntu 24.04 (with Docker Runtime)

This guide walks through the complete process of preparing an Ubuntu 24.04 system to act as a Kubernetes node using Docker and `cri-dockerd`, along with Calico and Multus for deploying CyPerf Agents using external test interface. It also includes cleanup/reset instructions if needed.

---

### Step 1: Disable Swap

Kubernetes requires swap to be turned off.

```bash
sudo vim /etc/fstab
```

* Comment out the swap line by adding a `#` at the beginning.

Reboot:

```bash
sudo reboot
```

---

### Step 2: Switch to Root

```bash
sudo su
```

---

### Step 3: Install Docker

Follow the official Docker installation instructions:
🔗 [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

Then reboot:

```bash
sudo reboot
```

---

### Step 4: Install `cri-dockerd`

Download and install the `.deb` package from:
🔗 [Mirantis cri-dockerd Releases](https://github.com/Mirantis/cri-dockerd/releases)

```bash
sudo dpkg -i <cri-dockerd-package.deb>
```

**Note:** We have used v0.3.17 for our testing.

Then reboot:

```bash
sudo reboot
```

---

### Step 5: Install Kubernetes Components

Install `kubeadm`, `kubelet`, and `kubectl` as per official guide:
🔗 [Install kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

Reboot:

```bash
sudo reboot
```

---

### Step 6: Initialize the Kubernetes Cluster

```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket=unix:///var/run/cri-dockerd.sock
```

> **Note:** If it gets stuck, pull the images manually:

```bash
kubeadm config images pull --cri-socket=unix:///var/run/cri-dockerd.sock
```

Then rerun the `kubeadm init` command.

---

### Step 7: Set Up kubectl Access

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

### Step 8: Check for Port Binding Errors

Use the following command to check if port **10259** is already in use:

```bash
sudo netstat -tulpn | grep 10259
```

> **Note:** Port **10259** is the default secure port used by the `kube-scheduler`.

#### Why this matters

If this port is already occupied by another process (such as an old instance of `kube-scheduler` or an unrelated service), trying to start the scheduler will result in a **port binding error**.


#### Resolving Port Conflicts

If you find that the port is in use, you have two options:

1. **Kill the conflicting process**:

   ```bash
   sudo kill <PID>
   ```

   Replace `<PID>` with the process ID found in the `netstat` output.

2. **Change the port in the kube-scheduler configuration**:

   * Edit the scheduler manifest (usually located at `/etc/kubernetes/manifests/kube-scheduler.yaml`)
   * Look for the `--secure-port` flag and change its value
   * Save and wait for the scheduler to restart

---

### Step 9: Install Calico CNI

Download the manifest:

```bash
curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml -o calico.yaml
```

Edit `calico.yaml` and set:

```yaml
CALICO_IPV4POOL_IPIP: "CrossSubnet"
```

(Optionally) add from Loxilb DPDK docs:

```yaml
"ipam": {
  "type": "calico-ipam"
},
"container_settings": {
  "allow_ip_forwarding": true
}
```

Apply it:

```bash
kubectl apply -f ./calico.yaml
```

Reboot:

```bash
sudo reboot
```

---

### Step 10: Verify Node Readiness

```bash
kubectl get nodes
```

---

### Step 11: Deploy Multus CNI

```bash
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
```

---

### Step 12: Allow Pod Scheduling on Control Plane

```bash
kubectl describe node <node-name> | less
```

If you see:

```
Taints: node-role.kubernetes.io/control-plane:NoSchedule
```

Remove taint:

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

Confirm:

```bash
kubectl describe node <node-name> | less
```

Look for:

```
Taints: <none>
```

---

### Step 13: Update HugePages Support (Optional, for DPDK)

If using DPDK with `hugepages`, restart `kubelet` after allocating hugepages:

```bash
sudo systemctl restart kubelet
```

Check:

```bash
kubectl describe node <node-name>
```

Look for entries like:

```yaml
hugepages-2Mi: 8Gi
```

---

### Step 14: Deploy the Agent

Refer to these links for the YAML file:


🔗 [CyPerf with external test interface using dpdk](agent_examples/multus_multi_iface_dpdk.yaml)


🔗 [CyPerf with external test interface non dpdk](agent_examples/multus_multi_iface.yaml)

```bash
kubectl apply -f multus_multi_iface_dpdk.yaml
```
Or
```bash
kubectl apply -f multus_multi_iface.yaml
```


---

## 🔁 Reset Kubernetes Deployments (If Needed)

If you need to clean up and start over, follow these steps **with caution**:

---

### Step 1: Delete Deployed Resources

Delete the agent:

```bash
kubectl delete -f multus_multi_iface_dpdk.yaml
```

Delete Multus:

```bash
kubectl delete -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
```

Delete Calico:

```bash
kubectl delete -f ./calico.yaml
```

---

### Step 2: Monitor Existing Pods

Ensure everything has terminated:

```bash
kubectl get pods -A
```

Wait until all pods are gone.

---

### Step 3: Reset the Cluster

```bash
sudo kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock -f
```

> ⚠️ **Note:** Avoid resetting `kubeadm` frequently. This process destroys and recreates underlying pods and containers, which can lead to instability or broken deployments on subsequent inits.

---
