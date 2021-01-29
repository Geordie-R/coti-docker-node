# Coti Docker Node - Beta - Test Branch
Here is an easy to use, coti docker node installer. We have branched the main to test a lower version.  Please ignore this branch

## Instructions

To either install a fresh coti docker node on a fresh VPS, or to upgrade your current coti docker node, it is the same instructions below.

Login to your VPS using the root user, or alternatively switch to your root user with ```su - root```

Then run the following

 ```
 mkdir -p ~/coti-docker-scripts
 cd ~/coti-docker-scripts
 wget https://raw.githubusercontent.com/Geordie-R/coti-docker-node/main/menu.sh && chmod +x menu.sh
 wget https://raw.githubusercontent.com/Geordie-R/coti-docker-node/main/installwithdocker.sh && chmod +x installwithdocker.sh
 wget https://raw.githubusercontent.com/Geordie-R/coti-docker-node/main/upgradewithdocker.sh && chmod +x upgradewithdocker.sh
 ./menu-test.sh
```

You will be given an easy to follow menu.  Choose the menu option you require and follow the prompts.  If you do not know any of the answers, leave the answer empty and it will terminate.

If you have any questions reach me on Discord or Telegram.

Also, if you have any feedback please let me know.

## Users who want to switch to docker from non-docker node.

If you are not using docker right now, but want to switch, I will be doing a script for this in the near future also.
