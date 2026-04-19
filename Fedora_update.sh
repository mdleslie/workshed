#!/bin/bash

START_TIME=$SECONDS

mkdir -p /home/$USER/logs

SLEEP=2s
now=$(date +"%Y-%m-%d %H:%M:%S")
log_file="/home/$USER/logs/update_log.txt"
update_summary="/home/$USER/logs/update_summary_$(date +"%Y%m%d_%H%M%S").txt"
FAILED_MANAGERS=()

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

# Wrapper function for error handling per manager
run_update() {
    local name=$1
    local cmd=$2
    log_and_display INFO "Starting $name updates..."
    
    if eval "$cmd" 2>&1 | tee -a "$log_file" | tee -a "$update_summary"; then
        log_and_display INFO "$name updates completed successfully."
    else
        log_and_display ERROR "$name updates failed."
        FAILED_MANAGERS+=("$name")
    fi
    sleep $SLEEP
}

# --- Pre-flight Checks ---

# 1. Check for Reboot Requirement
if [ -f /var/run/reboot-required ]; then
    log_and_display WARNING "A system reboot is required. Please reboot before running this script."
    exit 1
fi

# 2. Disk Space Check (Btrfs-safe version)
available_space_kb=$(df --output=avail $HOME | tail -1)

# Convert KB to GB (Btrfs reports in 1K blocks by default here)
available_space_gb=$(echo "scale=2; $available_space_kb / 1024 / 1024" | bc)

if (( $(echo "$available_space_gb < 5" | bc -l) )); then
    log_and_display WARNING "Less than 5GB free ($available_space_gb GB). Clean up disk space!"
    exit 1
fi

# 3. Sudo Refresh
log_and_display INFO "Refreshing sudo credentials..."
sudo -v || { log_and_display ERROR "Sudo failed. Exiting."; exit 1; }

# --- Update Execution ---

# 1. System Repos (DNF)
run_update "DNF (System)" "sudo dnf upgrade --refresh -y"

# 2. Flatpak
if command -v flatpak &> /dev/null; then
    # Ensure Flathub is enabled so updates actually find mirrors
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    run_update "Flatpak" "flatpak update -y"
else
    log_and_display WARNING "Flatpak not found. Skipping."
fi

# 3. Snap
if command -v snap &> /dev/null; then
    log_and_display INFO "Checking Snapd service..."
    # On Fedora, snapd.seeded is sometimes needed for the first run
    sudo systemctl enable --now snapd.socket
    run_update "Snap" "sudo snap refresh"
else
    log_and_display WARNING "Snap (snapd) is not installed. Use 'sudo dnf install snapd' to enable."
fi

# 4. Pipx (yt-dlp)
if command -v pipx &> /dev/null; then
    run_update "Pipx" "pipx upgrade-all"
fi

# --- Maintenance & Cleanup ---
log_and_display INFO "Running system maintenance..."

# Repair Flatpak & Cleanup
sudo flatpak repair 2>&1 | tee -a "$log_file"
flatpak uninstall --unused -y 2>&1 | tee -a "$log_file"

# DNF Housekeeping
sudo dnf autoremove -y 2>&1 | tee -a "$log_file"
sudo dnf clean packages -y 2>&1 | tee -a "$log_file"

# Firmware
log_and_display INFO "Checking for Firmware Updates..."
sudo fwupdmgr get-updates -y && sudo fwupdmgr update -y

# COSMIC/RPM check
log_and_display INFO "Logging installed COSMIC components..."
rpm -qa | grep cosmic >> "$update_summary"

# --- Finalization ---
TOTAL_SECONDS=$((SECONDS - START_TIME))
ELAPSED_TIME=$(printf '%dh:%dm:%ds\n' $((TOTAL_SECONDS/3600)) $((TOTAL_SECONDS%3600/60)) $((TOTAL_SECONDS%60)))

log_and_display INFO "Update summary saved to $update_summary"
log_and_display INFO "Total Duration: $ELAPSED_TIME"

if [ ${#FAILED_MANAGERS[@]} -eq 0 ]; then
    log_and_display INFO "ALL updates completed successfully! 🎉"
    echo "$now - Success (Duration: $ELAPSED_TIME)" >> "/home/$USER/logs/update_audit.txt"
else
    log_and_display ERROR "The following managers failed: ${FAILED_MANAGERS[*]}"
    echo "$now - Failed: ${FAILED_MANAGERS[*]} (Duration: $ELAPSED_TIME)" >> "/home/$USER/logs/update_audit.txt"
fi