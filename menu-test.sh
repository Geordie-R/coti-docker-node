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
echo "${YELLOW}TEST YELLOW${COLOR_RESET}"
echo "${GREEN}TEST GREEN${COLOR_RESET}"


#Functions

function get_user_answer_yn(){
  while :
  do
    read -p "$1 [y/n]: " answer
    answer="$(echo $answer | tr '[:upper:]' '[:lower:]')"
    case "$answer" in
      yes|y) return 0 ;;
      no|n) return 1 ;;
      *) echo  "${RED}Invalid Answer [yes/y/no/n expected]${COLOR_RESET}";continue;;
    esac
  done
}





if [ "$EUID" -ne 0 ]
  then echo "${RED}Please run as root user{COLOR_RESET}"
  exit
fi


#Parameters
#Install JQ which makes it easy to interpret JSON
apt-get update -y
apt-get install -y jq




cat << "MENUEOF"
███╗   ███╗███████╗███╗   ██╗██╗   ██╗
████╗ ████║██╔════╝████╗  ██║██║   ██║
██╔████╔██║█████╗  ██╔██╗ ██║██║   ██║
██║╚██╔╝██║██╔══╝  ██║╚██╗██║██║   ██║
██║ ╚═╝ ██║███████╗██║ ╚████║╚██████╔╝
╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝
MENUEOF

shopt -s globstar dotglob

PS3='Please choose what action you would like below: '
newinstall="Install a new Coti Docker Node"
upgrade="Upgrade an already setup Coti Docker Node"
cancelit="Cancel"
options=("$newinstall" "$upgrade" "$cancelit")
asktorestart=0
select opt in "${options[@]}"
do
    case $opt in
        "$newinstall")
        action="newinstall"
        echo "You chose a fresh install of Coti Node"
        sleep 1
        ./installwithdocker.sh


        break
            ;;
        "$upgrade")
            echo "You chose to UPGRADE the docker node"
        action="upgrade"
        sleep 1
        ./upgradewithdocker.sh

        break
            ;;
       "$cancelit")
            echo "${RED}You chose to cancel going any further${COLOR_RESET}"

        action="cancel"
        exit 1
break
            ;;
        "Quit")
            exit 1
break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
