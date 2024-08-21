#!/bin/bash

mkdir -p /home/$USER/logs

SLEEP=2s
now=$(date +"%Y-%m-%d %H:%M:%S")
log_file="/home/$USER/logs/update_log.txt"
update_summary="/home/$USER/logs/update_summary_$(date +"%Y%m%d_%H%M%S").txt"

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

# Check if system is pending a reboot
if [ -f /var/run/reboot-required ]; then
    log WARNING "A system reboot is required. Please reboot before running this script."
    exit 1
fi

# Error handling
set -e
trap 'log ERROR "An error occurred. Exit code: $?"' ERR

log INFO "Starting update script"

# Check if lolcat is installed
if ! command -v lolcat &> /dev/null; then
    log WARNING "lolcat is not installed. Installing lolcat."
    display "Installing lolcat. It is nice."
    sudo apt update && sudo apt install -y lolcat
fi

# Check if nala is installed
if ! command -v nala &> /dev/null; then
    log WARNING "nala is not installed. Installing nala."
    display "Installing Nala. Because it is better than apt."
    sudo apt update && sudo apt install -y nala
fi

# Checking available Hard drive space.
available_space=$(df -h $HOME | awk 'NR==2 {print $4}')
available_space_numeric=$(echo $available_space | sed 's/[^0-9.]//g')
available_space_unit=$(echo $available_space | sed 's/[0-9.]//g')

case $available_space_unit in
    [Gg]*) multiplier=1 ;;
    [Mm]*) multiplier=0.001 ;;
    [Kk]*) multiplier=0.000001 ;;
    *) multiplier=1000 ;;
esac

available_space_gb=$(echo "$available_space_numeric * $multiplier" | bc)

if (( $(echo "$available_space_gb < 5" | bc -l) )); then
    echo "WARNING!!! Less than 5GB of free space available. Clean up disk space before updating!"
    exit 1
fi

# Prompt for sudo password early
echo "This script requires sudo privileges. Enter password for $USER now."
sleep .2s
if sudo -v; then
    echo "Sudo access granted. Starting update process..."
else
    echo "Failed to obtain sudo privileges. Exiting."
    exit 1
fi

log INFO "Updating packages"
display "Updating packages. Don't Mix Danger, Handle with Care!"
nala_update=$(sudo nala update 2>&1)
flatpak_update=$(flatpak update -y 2>&1)
echo "$nala_update" >> "$log_file"
echo "Nala update:" >> "$update_summary"
echo "$nala_update" >> "$update_summary"
echo "$flatpak_update" >> "$log_file"
echo "Flatpak update:" >> "$update_summary"
echo "$flatpak_update" >> "$update_summary"

# Pop specific upgrade
log INFO "Updating Pop!_OS specific components"
display "Upgrades specific to Pop OS!"
pop_os_update=$(sudo pop-upgrade release upgrade 2>&1)
echo "Pop!_OS update:" >> "$update_summary"
echo "$pop_os_update" >> "$update_summary"
echo "$pop_os_update" >> "$log_file"

sleep $SLEEP

log INFO "Repairing Flatpaks"
display "Repairing Flatpacks. Groovy."
sleep $SLEEP
flatpak_repair=$(sudo flatpak repair 2>&1)
echo "Flatpak repair:" >> "$update_summary"
echo "$flatpak_repair" >> "$update_summary"
echo "$flatpak_repair" >> "$log_file"

sleep $SLEEP

log INFO "Upgrading apt packages"
display "Upgrading apt packages. So no more runnin. I aim to misbehave."
sleep $SLEEP
nala_upgrade=$(sudo nala upgrade -y 2>&1)
apt_upgrade=$(sudo apt full-upgrade -y 2>&1)
echo "Nala upgrade:" >> "$update_summary"
echo "$nala_upgrade" >> "$update_summary"
echo "Apt full-upgrade:" >> "$update_summary"
echo "$apt_upgrade" >> "$update_summary"
echo "$nala_upgrade" >> "$log_file"
echo "$apt_upgrade" >> "$log_file"

sleep $SLEEP

log INFO "Cleaning up"
display "Cleaning up. Don't Panic."
sleep $SLEEP
nala_autoremove=$(sudo nala autoremove -y 2>&1)
flatpak_uninstall=$(flatpak uninstall --unused -y 2>&1)
echo "Nala autoremove:" >> "$update_summary"
echo "$nala_autoremove" >> "$update_summary"
echo "Flatpak unused uninstall:" >> "$update_summary"
echo "$flatpak_uninstall" >> "$update_summary"
echo "$nala_autoremove" >> "$log_file"
echo "$flatpak_uninstall" >> "$log_file"

sleep $SLEEP

log INFO "Updating audit file"
display "Updating audit file now. You heard about Pluto? That's messed up, right?"
echo "$now - Update completed" >> "/home/$USER/logs/update_audit.txt"

sleep $SLEEP

log INFO "System desktop: $XDG_SESSION_DESKTOP"
display "Your current system desktop is: $XDG_SESSION_DESKTOP"

sleep $SLEEP

log INFO "Windowing system: $XDG_SESSION_TYPE"
display "Your current windowing system is: $XDG_SESSION_TYPE"

sleep $SLEEP

sudo date >> "$log_file"

log INFO "Update summary saved to $update_summary"
display "Update summary saved to $update_summary"

# Updates were successful or failed.
if [ $? -eq 0 ]; then
    log INFO "All updates completed successfully"
    display "All updates successful. Who Dey!"
else
    log ERROR "Some updates failed. Check the logs for details."
    display "Some updates have failed. Check logs for details."
fi

sudo cat "/home/$USER/logs/update_audit.txt" | tail -10 | lolcat

sleep $SLEEP

# Reboot request if kernal has been upgraded.
if [ -f /var/run/reboot-required ]; then
    log WARNING "A system reboot is required after the updates."
    display "A reboot is required for upgrade."
fi

log INFO "Update script finished"
display "Workshed upgrade script is finished running. Shop smart, Shop S-Mart!"

sleep $SLEEP

figlet Workshed | lolcat -a -d 3

exit 0