#!/bin/bash

###Setup instructions###
###Place bash file in /usr/bin with update.sh name. You will need to create the bin subdirectory.

###Run commands:

###sudo chmod +x update.sh                     to make executable

###alias update="update.sh"                       to create alias. Add to .bashrc file.

#################################################################

SLEEP=2s
now=$(date)

echo -e "\e[1;34m Step 1: Updating apt and flatpak packages. Don't Mix Danger, Handle with Care. \e[0m"  

sudo apt update

flatpak update -y

echo -e "\e[1;34m Step 2: Repairing Flatpacks. Groovy. \e[0m"  

sleep $SLEEP

sudo flatpak repair

echo -e "\e[1;34m Step 3: Upgrading apt packages. So no more runnin. I aim to misbehave. \e[0m"

sleep $SLEEP

sudo apt upgrade -y  
sudo apt full-upgrade -y  

echo -e "\e[1;34m Step 4: Cleaning up apt and flatpak. Don't Panic. \e[0m"  

sleep $SLEEP
 
sudo apt-get autoremove

flatpak uninstall --unused -y

echo -e "\e[1;34m Step 5: Workshed upgrade script is finished running. Exiting now. Shop smart, Shop S-Mart! \e[0m"
echo -e "\e[44m                                                                                                                                              \e[0m"
echo -e "\e[44m                                                                                                                                              \e[0m"

sleep $SLEEP

sudo date >> "/home/$USER/updatelog.txt"

echo -e "\e[1;34m The system time and date is: \e[0m"
echo -e "\e[1;34m $now \e[0m"

sudo cat "/home/$USER/updatelog.txt"

echo -e "\e[44m                                                                                                                                              \e[0m"      

echo -e "\e[44m                                                                                                                                              \e[0m"

sleep .2s

echo -e "\e[44m                                                                                                                                              \e[0m"

sleep $SLEEP

fastfetch -l maid                                                                                                                                                           

exit

