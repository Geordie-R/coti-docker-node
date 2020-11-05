#!/bin/bash

set -eu -o pipefail # fail on error , debug all lines

LOG_LOCATION=/root/
exec > >(tee -i $LOG_LOCATION/cnode.log)
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

read -n 1 -r -s -p $'Press enter to continue...\n'

echo "Welome to the COTI docker installer .  We will begin to ask you a series of questions.  Please have to hand:"
echo "✅ Your SSH Port No"
echo "✅ Your Ubuntu Username"
echo "✅ Your email address"
echo "✅ Your server hostname from Godaddy or namecheap etc e.g. coti.mynode.com"
echo "✅ Your wallet private key"
echo "✅ Your wallet seed key"
read -n 1 -r -s -p $'Press enter to begin...\n'

read -p "What is your ssh port number (likely 22 if you do not know)?: " portno
read -p "What is your ubuntu username (use coti if unsure) ?: " username
read -p "What is your email address?: " email
read -p "What is your server host name e.g. mynode.mydomain.com?: " servername
read -p "What is your wallet private key?: " pkey
read -p "What is your wallet seed?: " seed


if [[ $portno == "" ]] || [[ $username == "" ]] || [[ $email == "" ]] || [[ $servername == "" ]] || [[ $pkey == "" ]] || [[ $seed == "" ]];
then
echo "Some details were not provided.  Script is now exiting.  Please run again and provide answers to all of the questions"
exit 1
fi



exec 3<>/dev/tcp/icanhazip.com/80
echo -e 'GET / HTTP/1.0\r\nhost: icanhazip.com\r\n\r' >&3
while read i
do
 [ "$i" ] && serverip="$i"
done <&3

serverurl=https://$servername

#########################################
# Create $username user if needed
#########################################

if id "$username" >/dev/null 2>&1; then
        echo "user exists"
else
        echo "user does not exist...creating"
        adduser --gecos "" --disabled-password $username
        adduser $username sudo



fi


apt-get update -y && sudo apt-get upgrade -y

echo "Downloading docker-compose.yml"

mkdir -p /home/$username/docker/data/
cd /home/$username/docker/
wget https://raw.githubusercontent.com/coti-io/coti-node/dev/docker-compose.yml && chmod +x docker-compose.yml


echo "Installing docker and other software..."
#Install docker
 sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

echo "Adding gpg key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

echo "Adding repository for docker..."
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
echo "Installing docker..."
sudo apt-get install docker-ce docker-ce-cli containerd.io

#software-properties pre-req of certbot
apt-get install nginx ufw nano git -y
add-apt-repository ppa:certbot/certbot -y
apt-get install certbot python-certbot-nginx -y


ufw limit $portno
ufw allow 80
ufw allow 443
ufw allow 7070
ufw --force enable

#########################################
# Create fullnode1.properties file
#########################################

cat <<EOF >/home/$username/docker/data/fullnode1.properties
network=TestNet
server.ip=$serverip
server.port=7070
server.url=$serverurl
application.name=FullNode
logging.file.name=FullNode1
database.folder.name=rocksDB1
resetDatabase=false
global.private.key=$pkey
fullnode.seed=$seed
minimumFee=0.01
maximumFee=100
fee.percentage=1
zero.fee.user.hashes=9c37d52ae10e6b42d3bb707ca237dd150165daca32bf8ef67f73d1e79ee609a9f88df0d437a5ba5a6cf7c68d63c077fa2c63a21a91fc192dfd9c1fe4b64bb959
kycserver.public.key=c10052a39b023c8d4a3fc406a74df1742599a387c58bcea2a2093bd85103f3bd22816fa45bbfb26c1f88a112f0c0b007755eb1be1fad3b45f153adbac4752638
kycserver.url=https://cca.coti.io
node.manager.ip=52.59.142.53
node.manager.port=7090
node.manager.propagation.port=10001
allow.transaction.monitoring=true
whitelist.ips=127.0.0.1,0:0:0:0:0:0:0:1
data.path='./data/'
EOF


#########################################
# Download Clusterstamp
#########################################

FILE=/home/$username/docker/data/FullNode1_clusterstamp.csv
if [ -f "$FILE" ]; then
    echo "${YELLOW}$FILE already exists, no need to download the clusterstamp file{COLOR_RESET}"
else
    echo "${YELLOW}$FILE does not exist, downloading the clusterstamp now...{COLOR_RESET}"
    wget -q --show-progress --progress=bar:force 2>&1 https://www.dropbox.com/s/rpyercs56zmay0z/FullNode1_clusterstamp.csv -P /home/$username/docker/data/
fi

chown $username /home/$username/docker/data/FullNode1_clusterstamp.csv
chgrp $username /home/$username/docker/data/FullNode1_clusterstamp.csv
chown $username /home/$username/docker/data/fullnode1.properties
chgrp $username /home/$username/docker/data/fullnode1.properties

#########################################
# Cerbot / Certificates
#########################################

certbot certonly --nginx --non-interactive --agree-tos -m $email -d $servername

#########################################
# Create NGINX coti_fullnode.conf file
#########################################

cat <<'EOF' >/etc/nginx/sites-enabled/coti_fullnode.conf
server {
    listen      80;
    return 301  https://$host$request_uri;
}server {
    listen      443 ssl;
    listen [::]:443;
    server_name
    ssl_certificate
    ssl_key
    ssl_session_timeout 5m;
    gzip on;
    gzip_comp_level    5;
    gzip_min_length    256;
    gzip_proxied       any;
    gzip_vary          on;
    gzip_types
        text/css
        application/json
        application/x-javascript
        text/javascript
        application/javascript
        image/png
        image/jpg
        image/jpeg
        image/svg+xml
        image/gif
        image/svg;location  / {
        proxy_redirect off;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_pass http://127.0.0.1:7070;
    }
}
EOF

#########################################
# Replace SSL Cert Info Inside NGINX
#########################################

sed -i "s/server_name/server_name $servername;/g" /etc/nginx/sites-enabled/coti_fullnode.conf
sed -i "s:ssl_certificate:ssl_certificate /etc/letsencrypt/live/$servername/fullchain.pem;:g" /etc/nginx/sites-enabled/coti_fullnode.conf
sed -i "s:ssl_key:ssl_certificate_key /etc/letsencrypt/live/$servername/privkey.pem;:g" /etc/nginx/sites-enabled/coti_fullnode.conf

service nginx restart

#########################################
# Create a temporary docker command file
#########################################
read -n 1 -r -s -p $'Press enter to begin docker pull fullnode command...\n'
tempfile="/home/$username/docker/tempdocker.sh"
echo "VERSION=$new_version_tag.RELEASE docker-compose pull fullnode" > $tempfile
sleep 2
echo "VERSION=$new_version_tag.RELEASE docker-compose up -d" >> $tempfile
chmod +x $tempfile
echo "Running docker-compose commands..."
$tempfile

#docker logs --tail 100 -f docker_fullnode_1


echo "Waiting for Coti Node to Start"
sleep 5


docker logs --tail -f docker_fullnode_1 | while read line; do

#tail -f /home/coti/coti-fullnode/logs/FullNode1.log | while read line; do
echo $line
echo $line | grep -q 'COTI FULL NODE IS UP' && break;
done
sleep 2
echo "${GREEN}Your node is registered and running on the COTI Network${RESET_COLOR}"
