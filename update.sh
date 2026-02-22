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

# Function to log and display messages
log_and_display() {
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    level=$1
    message="$timestamp: [$level] $2"
    echo "$message" | lolcat
    echo "$message" >> "$log_file"
    logger -p user.$level "$2"
}

# Check if system is pending a reboot
if [ -f /var/run/reboot-required ]; then
    log_and_display WARNING "A system reboot is required. Please reboot before running this script."
    exit 1
fi

# Error handling
set -e
trap 'log_and_display ERROR "An error occurred. Exit code: $?"' ERR

log_and_display INFO "Starting update script"

# Check if lolcat is installed
if ! command -v lolcat &> /dev/null; then
    log_and_display WARNING "lolcat is not installed. Installing lolcat."
    sudo apt install -y lolcat
fi

# Check if nala is installed
if ! command -v nala &> /dev/null; then
    log_and_display WARNING "nala is not installed. Installing nala."
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
    log_and_display WARNING "Less than 5GB of free space available. Clean up disk space before updating!"
    exit 1
fi

# Prompt for sudo password early
log_and_display INFO "This script requires sudo privileges. Enter password for $USER now."
if sudo -v; then
    log_and_display INFO "Sudo access granted. Starting update process..."
else
    log_and_display ERROR "Failed to obtain sudo privileges. Exiting."
    exit 1
fi

log_and_display INFO "Updating packages"
sleep 2s
sudo nala update -v 2>&1 | tee -a "$log_file" | tee -a "$update_summary"
flatpak update -y --verbose 2>&1 | tee -a "$log_file" | tee -a "$update_summary"

# Snap package updates
log_and_display INFO "Updating Snap packages"
if command -v snap &> /dev/null; then
    sleep 2s
    sudo snap refresh 2>&1 | tee -a "$log_file" | tee -a "$update_summary"
else
    log_and_display WARNING "Snap is not installed or the daemon is not running. Skipping."
fi

# Pop specific upgrade
log_and_display INFO "Updating Pop!_OS specific components"
sleep 2s
sudo pop-upgrade release upgrade 2>&1 | tee -a "$log_file" | tee -a "$update_summary"

# yt dlp specific upgrade
log_and_display INFO "Updating yt-dlp specific components"
sleep 2s
pipx upgrade yt-dlp

sleep $SLEEP

log_and_display INFO "Repairing Flatpaks"
sleep $SLEEP
sudo flatpak repair --verbose 2>&1 | tee -a "$log_file" | tee -a "$update_summary"

sleep $SLEEP

log_and_display INFO "Upgrading apt packages"
sleep $SLEEP
sudo nala full-upgrade -y -v 2>&1 | tee -a "$log_file" | tee -a "$update_summary"

sleep $SLEEP

log_and_display INFO "Cleaning up"
sleep $SLEEP
sudo nala autoremove -y -v 2>&1 | tee -a "$log_file" | tee -a "$update_summary"
flatpak uninstall --unused -y --verbose 2>&1 | tee -a "$log_file" | tee -a "$update_summary"

sleep $SLEEP

log_and_display INFO "Updating audit file"
echo "$now - Update completed" >> "/home/$USER/logs/update_audit.txt"

sleep $SLEEP

log_and_display INFO "System desktop: $XDG_SESSION_DESKTOP"
log_and_display INFO "Windowing system: $XDG_SESSION_TYPE"

sleep $SLEEP

sudo date >> "$log_file"

log_and_display INFO "Update summary saved to $update_summary"

# Updates were successful or failed.
if [ $? -eq 0 ]; then
    log_and_display INFO "All updates completed successfully"
else
    log_and_display ERROR "Some updates failed. Check the logs for details."
fi

sleep $SLEEP

sudo cat "/home/$USER/logs/update_audit.txt" | tail -10 | lolcat

sleep $SLEEP

# Reboot request if kernel has been upgraded.
if [ -f /var/run/reboot-required ]; then
    log_and_display WARNING "A system reboot is required after the updates."
fi

log_and_display INFO "Update script finished"

sleep $SLEEP

figlet Workshed | lolcat -a -d 3

exit 0
