#!/bin/bash


helpFunction()
{
   echo ""
   echo "Usage: $0 -c controllerip"
   echo -e "\t-c Controller IP where Agent will be registered"
   exit 1 # Exit script after printing help
}

while getopts "c:a:i:n:" opt
do
   case "$opt" in
      c ) CONTROLLER_IP="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$CONTROLLER_IP" ]
then
   echo "parameter is empty";
   helpFunction
fi

# Begin script in case all parameters are correct
echo "CONTROLLER_IP - $CONTROLLER_IP"


createDockerBrige()
{
    var1=`sudo docker network ls | grep test-network`
    if [[ ${#var1} -gt 0 ]]; then
        echo  "Bridge with name test-network already exists."
    else
        echo  "Creating a new Bridge with name test-network"
        errormessage=$( sudo docker network create --subnet=192.168.0.1/24 test-network 2>&1)
        if [ $? -ne 0 ]; then
           echo  "Docker network test-network creation failed- $errormessage "
           exit 1
        fi
    fi
}


createCyPerfAgent()
{
    # Client Container deployment
    var1=`sudo docker ps -a | grep ClientAgent`
    if [[ ${#var1} -gt 0 ]]; then
        echo  "Container with name ClientAgent already exists."
        echo  "Stopping existing  ClientAgent container"
        errormessage=$( sudo docker stop ClientAgent 2>&1)
        if [ $? -ne 0 ]; then
           echo  "docker stop ClientAgent failed- $errormessage "
           exit 1
        fi
        echo  "Removing existing ClientAgent conatainer"
        errormessage=$( sudo docker rm ClientAgent 2>&1)
        if [ $? -ne 0 ]; then
           echo  "docker remove ClientAgent failed- $errormessage "
           exit 1
        fi
        echo  "Recreating a new container with name ClientAgent"
        errormessage=$( sudo docker create --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ClientAgent --network=test-network -e AGENT_CONTROLLER=$CONTROLLER_IP -e AGENT_TAGS="AgentType=DockerCyPerfClient" public.ecr.aws/keysight/cyperf-agent:latest 2>&1)
        if [ $? -ne 0 ]; then
           echo  "docker ClientAgent creation failed- $errormessage "
           exit 1
        fi
    else
        echo  "Creating a new container with name ClientAgent"
        errormessage=$( sudo docker create --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ClientAgent --network=test-network -e AGENT_CONTROLLER=$CONTROLLER_IP -e AGENT_TAGS="AgentType=DockerCyPerfClient" public.ecr.aws/keysight/cyperf-agent:latest 2>&1)
        if [ $? -ne 0 ]; then
           echo  "docker ClientAgent creation failed- $errormessage "
           exit 1
        fi
    fi

    # Server Container deployment
    var2=`sudo docker ps -a | grep ServerAgent`
    if [[ ${#var1} -gt 0 ]]; then
        echo  "Container with name ServerAgent already exists."
        echo  "Stopping existing  ServerAgent container"
        errormessage=$( sudo docker stop ServerAgent 2>&1)
        if [ $? -ne 0 ]; then
           echo  "docker stop ServerAgent failed- $errormessage "
           exit 1
        fi
        echo  "Removing existing ServerAgent conatainer"
        errormessage=$( sudo docker rm ServerAgent 2>&1)
        if [ $? -ne 0 ]; then
           echo  "docker remove ServerAgent failed- $errormessage "
           exit 1
        fi
        echo  "Recreating a new container with name ServerAgent"
        errormessage=$( sudo docker create --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ServerAgent --network=test-network -e AGENT_CONTROLLER=$CONTROLLER_IP -e AGENT_TAGS="AgentType=DockerCyPerfServer" -p 80:80 -p 443:443 public.ecr.aws/keysight/cyperf-agent:latest 2>&1)
        if [ $? -ne 0 ]; then
           echo  "docker ServerAgent creation failed- $errormessage "
           exit 1
        fi
    else
        echo  "Creating a new container with name ServerAgent"
        errormessage=$( sudo docker create --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name ServerAgent --network=test-network -e AGENT_CONTROLLER=$CONTROLLER_IP -e AGENT_TAGS="AgentType=DockerCyPerfServer" -p 80:80 -p 443:443 public.ecr.aws/keysight/cyperf-agent:latest 2>&1)
        if [ $? -ne 0 ]; then
           echo  "docker ServerAgent creation failed- $errormessage "
           exit 1
        fi
    fi  
}

startCyPerfAgent()
{
    sudo docker start "ClientAgent"
    sudo docker start "ServerAgent"
    
}

#Main 
#=====
# create docker bridge
createDockerBrige

# create VLM conatiner
createCyPerfAgent

#Start CyPerf Agents
startCyPerfAgent
