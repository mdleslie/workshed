#!/bin/bash

SLEEP=2s
now=$(date)

# Define the log file path
log_file="/home/$USER/update_log.txt"

# Function to log and display messages with error handling
log_and_display() {
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  message="$timestamp: $1"
  echo "$message" | lolcat
  echo "$message" >> "$log_file"
}

# Check if lolcat is installed
if ! command -v lolcat &> /dev/null; then
    log_and_display "lolcat is not installed. Installing lolcat."
    sudo apt update && sudo apt install -y lolcat
fi

log_and_display "Step 1: Updating packages. Don't Mix Danger, Handle with Care!"
sudo nala update && flatpak update -y

log_and_display "Step 2: Repairing Flatpacks. Groovy."
sleep $SLEEP
sudo flatpak repair

log_and_display "Step 3: Upgrading apt packages. So no more runnin. I aim to misbehave."
sleep $SLEEP
sudo nala upgrade -y && sudo apt full-upgrade -y

log_and_display "Step 4: Cleaning up. Don't Panic."
sleep $SLEEP
sudo nala autoremove -y
flatpak uninstall --unused -y

log_and_display "Step 5: Updating audit file now. You heard about Pluto? That's messed up, right?"
sudo date >> "/home/$USER/update_log.txt"

sleep $SLEEP

log_and_display "The system desktop is:"
echo $XDG_SESSION_DESKTOP

log_and_display "The windowing system is:"
echo $XDG_SESSION_TYPE

log_and_display "Step 5: Workshed upgrade script is finished running. Shop smart, Shop S-Mart!"
figlet Workshed | lolcat -a -d 3

sleep $SLEEP

exit