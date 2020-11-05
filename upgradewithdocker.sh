#!/bin/bash

set -eu -o pipefail # fail on error , debug all lines

LOG_LOCATION=/root/
exec > >(tee -i $LOG_LOCATION/dockercnode.log)
exec 2>&1


# For output readability
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
COLOR_RESET=$(tput sgr0)



new_version_tag=$(curl -s https://api.github.com/repos/coti-io/coti-node/releases/latest | jq ".tag_name")
#Remove the front and end double quote
new_version_tag=${new_version_tag#"\""}
new_version_tag=${new_version_tag%"\""}
#new_version_tag=1.4.1 for example

echo "Latest version is $new_version_tag"

echo "Welcome to the COTI docker upgrader .  We will begin to ask you a series of questions.  Please have to hand:"
echo "✅ Your Ubuntu Username"
read -n 1 -r -s -p $'Press enter to begin...\n'
read -p "What is your ubuntu username (use coti if unsure) ?: " username

apt-get update -y && sudo apt-get upgrade -y


cd /home/$username/docker/

#wget -O https://raw.githubusercontent.com/coti-io/coti-node/dev/docker-compose.yml && chmod +x docker-compose.yml
#full_node_properties_file=/home/$username/docker/data/fullnode1.properties

#########################################
# Create a temporary docker command file
#########################################

tempfile="/home/$username/docker/tempdocker.sh"
echo "cd /home/$username/docker" > $tempfile
echo "VERSION=$new_version_tag.RELEASE docker-compose pull fullnode" >> $tempfile
echo "VERSION=$new_version_tag.RELEASE docker-compose up -d" >> $tempfile
chmod +x $tempfile
echo "Running docker-compose commands..."
$tempfile
sleep 1
rm $tempfile
#docker logs --tail 100 -f docker_fullnode_1


echo "Waiting 30 seconds to check the logs..."
sleep 30
count_node_up=$(docker logs --tail 500 docker_fullnode_1 | grep -c "COTI FULL NODE IS UP")

echo "The phrase COTI NODE IS UP has been spotted $count_node_up times"

if [[ $count_node_up -gt 0 ]];
then

cat << "NODEUPEOF"

 ██████╗ ██████╗ ████████╗██╗    ███╗   ██╗ ██████╗ ██████╗ ███████╗    ██╗███████╗    ██╗   ██╗██████╗ ██╗
██╔════╝██╔═══██╗╚══██╔══╝██║    ████╗  ██║██╔═══██╗██╔══██╗██╔════╝    ██║██╔════╝    ██║   ██║██╔══██╗██║
██║     ██║   ██║   ██║   ██║    ██╔██╗ ██║██║   ██║██║  ██║█████╗      ██║███████╗    ██║   ██║██████╔╝██║
██║     ██║   ██║   ██║   ██║    ██║╚██╗██║██║   ██║██║  ██║██╔══╝      ██║╚════██║    ██║   ██║██╔═══╝ ╚═╝
╚██████╗╚██████╔╝   ██║   ██║    ██║ ╚████║╚██████╔╝██████╔╝███████╗    ██║███████║    ╚██████╔╝██║     ██╗
 ╚═════╝ ╚═════╝    ╚═╝   ╚═╝    ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝    ╚═╝╚══════╝     ╚═════╝ ╚═╝     ╚═╝

NODEUPEOF

echo "${GREEN}Your node is registered and running on the COTI Network ${COLOR_RESET}"
else
echo "${RED}Please check the logs below. We have been unable to determine if the node has started ${COLOR_RESET}"
docker logs --tail 500 docker_fullnode_1
fi
