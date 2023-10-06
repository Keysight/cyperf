#!/bin/bash


helpFunction()
{
   echo ""
   echo "Usage: $0 -c controllerip -a agentcount -i singleinterface -n externalconnect"
   echo -e "\t-c Controller IP where Agent will be registered"
   echo -e "\t-a Agent count for this deployment"
   echo -e "\t-i Single inteface for management and test traffic. Set SINGLE if single management and test interface OR SEPARATE "
   echo -e "\t-n If Test interface need host interface binding. Set NO if not required OR YES if required. Make sure host has enough interfaces for allocating to each Agent "
   exit 1 # Exit script after printing help
}

while getopts "c:a:i:n:" opt
do
   case "$opt" in
      c ) CONTROLLER_IP="$OPTARG" ;;
      a ) AGENT_COUNT="$OPTARG" ;;
      i ) INTERFACE_TYPE="$OPTARG" ;;
      n ) HOST_INIT_BIND="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$CONTROLLER_IP" ] || [ -z "$AGENT_COUNT" ] || [ -z "$INTERFACE_TYPE" ] || [ -z "$HOST_INIT_BIND" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

echo "INTERFACE_TYPE $INTERFACE_TYPE"
if  [[ "$INTERFACE_TYPE" != "SINGLE" ]] && [[ "$INTERFACE_TYPE" != "SEPARATE" ]]
then
   echo "Expercted value of -i parameter is SINGLE and SEPARATE";
   helpFunction
fi

if  [ "$HOST_INIT_BIND" != "YES" ] && [ "$HOST_INIT_BIND" != "NO" ] 
then
   echo "Expercted value of -n parameter is YES OR NO";
   helpFunction
fi

# Begin script in case all parameters are correct
echo "CONTROLLER_IP - $CONTROLLER_IP"
echo "AGENT_COUNT - $AGENT_COUNT"
echo "INTERFACE_TYPE - $INTERFACE_TYPE"
echo "HOST_INIT_BIND - $HOST_INIT_BIND"


attachBridge()
{  
   if [[ $INTERFACE_TYPE == "SEPARATE" ]]; then 
      if [[ $HOST_INIT_BIND == "YES" ]]; then
      k=1
         for i in $(seq 1 $AGENT_COUNT); do
         var1=`sudo docker inspect CyPerfAgent${i} | grep -iw "Pid" |awk '{split($2,b,","); print b[1]}'`
         echo "CyPerfAgent${i} process ID $var1"
         if [[ $AGENT_COUNT -gt 0 ]]; then
            ip a | grep -q eth${k} &> /dev/null
            if [[ $? -ne 0 ]]; then
               echo -e "Invalid eth device: eth${k}"
               exit 1
            fi
            ip link set dev eth${k} up
            echo "Assign an extenal interface from host to container"
            echo "ip link set eth${k} netns $var1 name eth1"
            ip link set eth${k} netns $var1 name eth1 &> /dev/null
            echo "Waiting for 10 sec..."
            sleep 10
            if [[ $? -ne 0 ]]; then
               echo  "eth${k} failed to connect at CyPerf Agent CyPerfAgent${i}"
            fi
            k=$((k + 1))
         fi
         done
      else
         if [[ $HOST_INIT_BIND == "NO" ]]; then
         for j in $(seq 1 $AGENT_COUNT); do
            echo "Connecting bridge test-network to CyPerf Agent CyPerfAgent${j}"
            sudo docker network connect "test-network" "CyPerfAgent${j}" &> /dev/null
            sleep 5
            if [ $? -ne 0 ]; then
               echo  "Bridge test-network failed to connect at CyPerf Agent CyPerfAgent${j}"
            fi
         done
         fi
      fi
   fi
}

createDockerBrige()
{
  if [[ $INTERFACE_TYPE == "SEPARATE" ]]; then  
    var1=`sudo docker network ls | grep management-network`
    var2=`sudo docker network ls | grep test-network`
    if [[ ${#var1} -gt 0 ]]; then
        echo  "Bridge with name management-network already exists."
    else
        echo  "Creating a new Bridge with name management-network"
        sudo docker network create --subnet=192.168.0.1/24 "management-network" &> /dev/null
    fi
    if [[ ${#var2} -gt 0 ]]; then
        echo  "Bridge with name test-network already exists."
    else
        echo  "Creating a new Bridge with name test-network"
        sudo docker network create --subnet=192.168.0.2/24 "test-network" &> /dev/null
    fi
  else
    var1=`sudo docker network ls | grep management-network`
    if [[ ${#var1} -gt 0 ]]; then
        echo  "Bridge with name management-network already exists."
    else
        echo  "Creating a new Bridge with name management-network"
        sudo docker network create --subnet=192.168.0.1/24 "management-network" &> /dev/null
    fi
  fi
}


createCyPerfAgent()
{
  for i in $(seq 1 $AGENT_COUNT); do
    var1=`sudo docker ps -a | grep CyPerfAgent${i}`
    if [[ ${#var1} -gt 0 ]]; then
        echo  "Container with name CyPerfAgent${i} already exists."
        echo  "Stopping existing  CyPerfAgent${i} container"
        sudo docker stop CyPerfAgent${i} &> /dev/null
        echo "Waiting for 20 sec..."
        sleep 20
        echo  "Removing existing CyPerfAgent${i} conatainer"
        sudo docker rm CyPerfAgent${i} &> /dev/null
        echo "Waiting for 10 sec..."
        sleep 10
        echo  "Recreating a new container with name CyPerfAgent${i}"
        sudo docker create --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name CyPerfAgent${i} --network=management-network -e AGENT_CONTROLLER=$CONTROLLER_IP -e AGENT_TAGS="AgentType=DockerCyPerfAgent${i}" public.ecr.aws/keysight/cyperf-agent:latest &> /dev/null
        echo "Waiting for 30 sec...to complete container creation"
        sleep 30
    else
        echo  "Creating a new container with name CyPerfAgent${i}"
        sudo docker create --cap-add=NET_ADMIN --cap-add=IPC_LOCK --name CyPerfAgent${i} --network=management-network -e AGENT_CONTROLLER=$CONTROLLER_IP -e AGENT_TAGS="AgentType=DockerCyPerfAgent${i}" public.ecr.aws/keysight/cyperf-agent:latest &> /dev/null
        echo "Waiting for 30 sec...to complete container creation"
        sleep 30
        if [ $? -ne 0 ]; then
           echo  "CyPerf Agent container creation failed."
        fi
   fi 
  done
}

startCyPerfAgent()
{
    for i in $(seq 1 $AGENT_COUNT); do
        sudo docker start "CyPerfAgent${i}"
    done
}

#Main 
#=====
# create docker bridge
createDockerBrige

# create VLM conatiner
createCyPerfAgent

# Attach each brigde to each VLM
attachBridge

#Start CyPerf Agents
startCyPerfAgent
