#!/bin/bash

###Setup instructions###
###Place bash file in /usr/bin with update.sh name. You will need to create the bin subdirectory.

###Run commands:

###sudo chmod +x update.sh                     to make executable

###alias update="update.sh"                       to create alias. Add to .bashrc file.

#################################################################


SLEEP=2s
now=$(date)

# Define the log file path
log_file="/home/$USER/update_log.txt"

# Function to log and display messages
log_and_display() {
  echo -e "$1" | lolcat | tee -a "$log_file"
}

# Check if lolcat is installed
if ! command -v lolcat &> /dev/null; then
    log_and_display "\e[1;31m lolcat is not installed. Installing lolcat...\e[0m"
    sudo apt update && sudo apt install -y lolcat
fi

log_and_display "Step 1: Updating apt and flatpak packages. Don't Mix Danger, Handle with Care!"  

sudo nala update

flatpak update -y

echo -e "\e[44m                                            \e[0m"

log_and_display "Step 2: Repairing Flatpacks. Groovy."  

sleep $SLEEP

sudo flatpak repair

echo -e "\e[44m                                            \e[0m"

log_and_display "Step 3: Upgrading apt packages. So no more runnin. I aim to misbehave."

sleep $SLEEP

sudo nala upgrade -y  
sudo apt full-upgrade -y  

echo -e "\e[44m                                            \e[0m"

log_and_display "Step 4: Cleaning up apt and flatpak. Don't Panic."  

sleep $SLEEP
 
sudo nala autoremove -y

flatpak uninstall --unused -y

echo -e "\e[44m                                            \e[0m"

log_and_display "Step 5: Updating audit file now. You heard about Pluto? That's messed up, right?"

sudo date >> "/home/$USER/updatelog.txt"

echo -e "\e[44m                                            \e[0m"

sleep $SLEEP

echo -e "\e[44m                                            \e[0m"

log_and_display "The system desktop is:"
echo $XDG_SESSION_DESKTOP

log_and_display"The windowing system is:"
echo $XDG_SESSION_TYPE

echo -e "\e[44m                                            \e[0m"

log_and_display "Step 5: Workshed upgrade script is finished running. Shop smart, Shop S-Mart!"

figlet Workshed | lolcat -a -d 3

sleep $SLEEP

exit
