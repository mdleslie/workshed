#!/bin/bash

now=$(date)


echo

echo -e "\e[1;32m Step 1: Updating packages. \e[0m"  
sudo apt-get update

flatpak update -y

echo

echo -e "\e[1;32m Step 2: Repairing Hudsucker Flatpacks for Framework laptop. \e[0m"  
sudo flatpak repair

echo

echo -e "\e[1;32m Step 3: Upgrading packages. \e[0m"  
sudo apt-get upgrade -y  
sudo apt-get dist upgrade -y  
sudo apt-get update

echo

echo -e "\e[1;32m Step 4: Cleaning up. \e[0m"  
sudo apt-get clean  
sudo apt-get autoclean  
sudo apt-get autoremove

flatpak uninstall --unused -y

echo -e "\e[1;32m Step 5: Script is finished running on Framework. Exiting now. Shop smart, Shop S-Mart! \e[0m"
neofetch

echo -e "\e[1;32m The system time and date is: \e[0m" 
echo -e "\e[1;32m $now \e[0m"

exit

