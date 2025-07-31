⚠️ Notice: Development on the RESTasV3 API wrapper has been frozen ⚠️

We strongly encourage you to switch to the [new API wrapper](https://github.com/Keysight/cyperf-api-wrapper), which is actively maintained and aligned with the latest features introduced in CyPerf.
Please note that this legacy wrapper includes updates only up to CyPerf 7.0 release and will no longer receive further improvements or support for newly added capabilities.
To get started with the new REST API wrapper, refer to the [README](https://github.com/Keysight/cyperf-api-wrapper/blob/main/README.md) of the new wrapper.

# CyPerf REST API Wrapper

# Introduction
This tool is a wrapper of the CyPerf REST API.
If offers support to run sample scripts to help you get started with the CyPerf REST API.

# Pre-requisites
- Python3.6+ (added to PATH)

# Getting started
0. [Optional] Install, create and activate virtual env (Windows example)
    - pip install virtualenv
    - cd [cyperf_api] 
    - virtualenv --python python.exe venv
    - .\venv\Scripts\activate
1. Install requirements
    - pip install -r requirements.txt
2. Set your API credentials in the resources\configuration.py file
    - WAP_USERNAME
    - WAP_PASSWORD
3. Go to the sample_scripts\ folder and run a CyPerf test
    python [sample_test].py [CONTROLLER_IP_ADDRESS]

# Known limitations
(i) The CyPerf Application API functionality is not fully covered by this REST API Wrapper framework.
Please check the CyPerf Application API - Reference Guide to gain access to all the existing API paths, methods and models.

