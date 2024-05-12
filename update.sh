#!/bin/bash

###Setup instructions###
###Place bash file in /usr/bin with update.sh name

###Run commands:

###sudo chmod +x update.sh                     to make executable

###alias update="update.sh"                       to create alias

#################################################################


now=$(date)


echo

echo -e "\e[1;32m Step 1: Updating apt and flatpak packages. \e[0m"  
sudo apt-get update

flatpak update -y

echo

echo -e "\e[1;32m Step 2: Repairing Flatpacks. \e[0m"  
sudo flatpak repair

echo

echo -e "\e[1;32m Step 3: Upgrading apt packages. \e[0m"  
sudo apt-get upgrade -y  
sudo apt-get dist upgrade -y  
sudo apt-get update

echo

echo -e "\e[1;32m Step 4: Cleaning up apt and flatpak. \e[0m"  
sudo apt-get clean  
sudo apt-get autoclean  
sudo apt-get autoremove

flatpak uninstall --unused -y

echo -e "\e[1;32m Step 5: Workshed upgrade script is finished running. Exiting now. Shop smart, Shop S-Mart! \e[0m"
#neofetch
sudo date >> "/home/$USER/updatelog.txt"

echo -e "\e[1;32m The system time and date is: \e[0m"
sudo cat "/home/$USER/update.txt"
echo -e "\e[1;32m $now \e[0m"

exit

