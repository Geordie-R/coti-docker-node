#This is not downloaded by default.  This code is here in case someone wants to stop and removal ALL of their docker images on a VPS.
#DO NOT RUN THIS IF YOU DO NOT UNDERSTAND THE IMPLICATIONS

docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker images -q)
