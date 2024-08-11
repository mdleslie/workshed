#!/bin/bash

SLEEP=2s
now=$(date +"%Y-%m-%d %H:%M:%S")
log_file="/home/$USER/update_log.txt"
update_summary="/home/$USER/update_summary.txt"

# Log rotation
if [ -f "$log_file" ]; then
    mv "$log_file" "${log_file}.1"
fi

# Function to log messages
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$log_file"
    logger -p user.$level "$message"
}

# Function to display colorful messages
display() {
    echo "$1" | lolcat
}

# Error handling
set -e
trap 'log ERROR "An error occurred. Exit code: $?"' ERR

log INFO "Starting update script"

# Check if lolcat is installed
if ! command -v lolcat &> /dev/null; then
    log WARNING "lolcat is not installed. Installing lolcat."
    sudo apt update && sudo apt install -y lolcat
fi

log INFO "Step 1: Updating packages"
display "Step 1: Updating packages. Don't Mix Danger, Handle with Care!"
nala_update=$(sudo nala update 2>&1)
flatpak_update=$(flatpak update -y 2>&1)
echo "Nala update:" >> "$update_summary"
echo "$nala_update" >> "$update_summary"
echo "Flatpak update:" >> "$update_summary"
echo "$flatpak_update" >> "$update_summary"

log INFO "Step 2: Repairing Flatpaks"
display "Step 2: Repairing Flatpacks. Groovy."
sleep $SLEEP
flatpak_repair=$(sudo flatpak repair 2>&1)
echo "Flatpak repair:" >> "$update_summary"
echo "$flatpak_repair" >> "$update_summary"

log INFO "Step 3: Upgrading apt packages"
display "Step 3: Upgrading apt packages. So no more runnin. I aim to misbehave."
sleep $SLEEP
nala_upgrade=$(sudo nala upgrade -y 2>&1)
apt_upgrade=$(sudo apt full-upgrade -y 2>&1)
echo "Nala upgrade:" >> "$update_summary"
echo "$nala_upgrade" >> "$update_summary"
echo "Apt full-upgrade:" >> "$update_summary"
echo "$apt_upgrade" >> "$update_summary"

log INFO "Step 4: Cleaning up"
display "Step 4: Cleaning up. Don't Panic."
sleep $SLEEP
nala_autoremove=$(sudo nala autoremove -y 2>&1)
flatpak_uninstall=$(flatpak uninstall --unused -y 2>&1)
echo "Nala autoremove:" >> "$update_summary"
echo "$nala_autoremove" >> "$update_summary"
echo "Flatpak unused uninstall:" >> "$update_summary"
echo "$flatpak_uninstall" >> "$update_summary"

log INFO "Step 5: Updating audit file"
display "Step 5: Updating audit file now. You heard about Pluto? That's messed up, right?"
echo "$now - Update completed" >> "/home/$USER/update_audit.txt"

sleep $SLEEP

log INFO "System desktop: $XDG_SESSION_DESKTOP"
display "The system desktop is: $XDG_SESSION_DESKTOP"

log INFO "Windowing system: $XDG_SESSION_TYPE"
display "The windowing system is: $XDG_SESSION_TYPE"

log INFO "Update script finished"
display "Step 5: Workshed upgrade script is finished running. Shop smart, Shop S-Mart!"
sleep $SLEEP


log INFO "Update summary saved to $update_summary"
display "Update summary saved to $update_summary"

sleep $SLEEP

figlet Workshed | lolcat -a -d 3

exit 0