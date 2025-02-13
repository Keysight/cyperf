# CyPerf REST API Wrapper

# Introduction
This tool is a wrapper of the CyPerf REST API.
If offers support to run sample scripts to help you get started with the CyPerf REST API.

# Pre-requisites
- Python3.6+ (added to PATH)

# Getting started
1. Set your API credentials in the resources\configuration.py file
    - WAP_USERNAME
    - WAP_PASSWORD

2. Populate the sample_scripts\RFC-2544-throughput\parameters.yaml  with the Required inputs. If you are unsure leave the feild values to defaults

3. Go to the sample_scripts\RFC-2544-throughput\ folder and run a CyPerf test
    python3 RFC-2544-throughput-ver23.py [CONTROLLER_IP_ADDRESS]

# Known limitations
(i) The CyPerf Application API functionality is not fully covered by this REST API Wrapper framework.
Please check the CyPerf Application API - Reference Guide to gain access to all the existing API paths, methods and models.
