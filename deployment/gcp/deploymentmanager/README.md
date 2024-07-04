# About CyPerf Deployment Manager Templates 

## Introduction 

Welcome to the GitHub repository for Keysight CyPerf deployment guide using GCP Deployment Manager via the Cloud Shell. 

To start using CyPerf's Python templates and yaml configuration, please refer the **README** files in each individual directory and decide on which template to start with from the below list.

## Prerequisites
The prerequisites are:
- SSH Key pair for management access to CyPerf VM instances.
- GCP shared images. Exact image name will be published in Keysight download page.
- GCP service account with 'compute admin' and 'compute network admin' role.

### Specialized knowledge
Before you deploy this Python template, we recommend that you become familiar with the following GCP services.
- [GCP Projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
- [Cloud Deployment Manager](https://cloud.google.com/deployment-manager)
- [VPC network](https://cloud.google.com/vpc/docs/vpc)
- [Compute Engine](https://cloud.google.com/compute)
- [GCP Images](https://cloud.google.com/compute/docs/images)
- [ssh-keygen](https://www.ssh.com/academy/ssh/keygen)
- [service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts)

**Note:** If you are new to GCP, see [Getting Started with GCP](https://cloud.google.com/gcp/getting-started).

## GCP images
Following CyPerf images are publicly available
- For CyPerf Controller, keysight-cyperf-controller-4-0 (Family name)
- For CyPerf Agents, keysight-cyperf-agent-4-0 (Family name)
<<<<<<< HEAD
- For CyPerf Controller Proxy, keysight-cyperf-controller-proxy-4-0 (Family name)
=======
- For CyPerf Controller Proxy, keysight-cyperf-controller-proxy-3-0 (Family name)
>>>>>>> 817a464... updated with 4.0 release info

## Supported instance types 
- For CyPerf Controller, supported Machine type c2-standard-8.
- For CyPerf Agents, supported instance type c2-standard-4 and c2-standard-16.
- For CyPerf Controller Proxy e2-medium.

### List of Supported CyPerf deployment manager templates for GCP 

The following is a list of the current supported CyPerf deployment manager templates. Click the links to view the README files which include the topology diagrams.

### I. [Controller and Agent Pair](controller_and_agent_pair):
 

This template deploys:

- One CyPerf Controller, in a public subnet.

- Two CyPerf Agents, both having two interfaces each. Both Agent interfaces are in a Private subnet. 

### II. [Controller Proxy and Agent Pair](controller_proxy_and_agent_pair):


This template deploys:

- One CyPerf Controller Proxy, in a public subnet.

- Two CyPerf Agents, both having two interfaces each. Both Agent interfaces are in a Private subnet. 

## Troubleshooting and Known Issues 

### Known Limitations

### Troubleshooting
