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
    
    # Execute command and capture exit code
    if eval "$cmd" 2>&1 | tee -a "$log_file" | tee -a "$update_summary"; then
        log_and_display INFO "$name updates completed successfully."
    else
        log_and_display ERROR "$name updates failed."
        FAILED_MANAGERS+=("$name")
    fi
    sleep $SLEEP
}

# --- Pre-flight Checks ---

if [ -f /var/run/reboot-required ]; then
    log_and_display WARNING "A system reboot is required. Please reboot before running this script."
    exit 1
fi

# Check dependencies
for cmd in lolcat nala snap flatpak pipx; do
    if ! command -v $cmd &> /dev/null; then
        log_and_display WARNING "$cmd is missing. Attempting to install or skipping..."
        # (Add specific install logic here if desired, like your existing nala/lolcat checks)
    fi
done

# Disk Space Check
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
    log_and_display WARNING "Less than 5GB free ($available_space_gb GB). Clean up disk space!"
    exit 1
fi

# Sudo Refresh
log_and_display INFO "Refreshing sudo credentials..."
sudo -v || { log_and_display ERROR "Sudo failed. Exiting."; exit 1; }

# --- Update Execution ---

# 1. System Repos (Nala)
run_update "Nala Update" "sudo nala update -v"

# 2. Flatpak
run_update "Flatpak" "flatpak update -y --verbose"

# 3. Snap (For Upnote/Lunatask/Spotify and other snaps)
run_update "Snap" "sudo snap refresh"

# 4. Pop!_OS Components
run_update "Pop_OS Upgrade" "sudo pop-upgrade release upgrade"

# 5. Pipx (yt-dlp)
run_update "Pipx" "pipx upgrade yt-dlp"

# 6. Maintenance & Cleanup
log_and_display INFO "Running system maintenance..."

log_and_display INFO "Step 6a: Repairing Flatpaks (This may take a minute...)"
sudo flatpak repair --verbose 2>&1 | tee -a "$log_file"

log_and_display INFO "Step 6b: Finalizing upgrades..."
sudo nala full-upgrade -y -v 2>&1 | tee -a "$log_file"

log_and_display INFO "Step 6c: Removing orphaned packages..."
sudo nala autoremove -y -v 2>&1 | tee -a "$log_file"
flatpak uninstall --unused -y 2>&1 | tee -a "$log_file"

log_and_display INFO "Step 6d:  Checking COSMIC Component Versions..."
dpkg -l | grep cosmic | awk '{print $2, $3}' >> "$update_summary"

log_and_display INFO "Step 6e:  Checking for Firmware Updates..."
sudo fwupdmgr get-updates && sudo fwupdmgr update

# --- Finalization ---

# Calculate Duration
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
