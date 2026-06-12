#!/bin/bash
set -o pipefail # REQUIRED: Ensures failed updates aren't masked by 'tee'

START_TIME=$SECONDS
SLEEP=1 

mkdir -p "$HOME/logs"

now=$(date +"%Y-%m-%d %H:%M:%S")
log_file="$HOME/logs/update_log.txt"
update_summary="$HOME/logs/update_summary_$(date +"%Y%m%d_%H%M%S").txt"
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
    # Note: Ensure lolcat is installed or this will fail
    echo "$message" | lolcat 2>/dev/null || echo "$message"
    echo "$message" >> "$log_file"
    logger -p user.$level "$2"
}

# Wrapper function for error handling
run_update() {
    local name=$1
    local cmd=$2
    log_and_display INFO "Starting $name..."
    
    # FIX: Raw output goes ONLY to the log file. Summary file gets a clean status.
    if eval "$cmd" 2>&1 | tee -a "$log_file"; then
        log_and_display INFO "$name completed successfully."
        echo "✅ $name: SUCCESS" >> "$update_summary"
    else
        log_and_display ERROR "$name failed."
        FAILED_MANAGERS+=("$name")
        echo "❌ $name: FAILED" >> "$update_summary"
    fi
    sleep "$SLEEP"
}

# --- Pre-flight Checks ---

if [ -f /var/run/reboot-required ]; then
    log_and_display WARNING "A system reboot is required. Please reboot before running this script."
    exit 1
fi

# Sudo Refresh - Do this BEFORE disk check in case df needs elevated perms on some systems
log_and_display INFO "Refreshing sudo credentials..."
sudo -v || { log_and_display ERROR "Sudo failed. Exiting."; exit 1; }

# Disk Space Check
# FIX: explicitly check the root (/) partition instead of $HOME
available_space_gb=$(df "/" --output=avail -BG | tail -1 | sed 's/[^0-9]//g')
if [ "$available_space_gb" -lt 5 ]; then
    log_and_display WARNING "Less than 5GB free ($available_space_gb GB) on root. Clean up disk space!"
    exit 1
fi

# --- Update Execution ---

# 1. System Repos (Nala)
run_update "Nala (System Upgrade)" "sudo nala update && sudo nala full-upgrade -y"

# 2. Flatpak
run_update "Flatpak (Updates)" "flatpak update -y"

# 3. Snap
run_update "Snap (Refresh)" "sudo snap refresh"

# 4. Pipx
run_update "Pipx (Apps)" "pipx upgrade-all"

# --- Maintenance & Cleanup ---
log_and_display INFO "Running system maintenance..."

# Repair Flatpaks
run_update "Flatpak Repair" "sudo flatpak repair"

# Cleanup Nala and Flatpak
log_and_display INFO "Removing orphaned packages..."
sudo nala autoremove -y >> "$log_file" 2>&1
flatpak uninstall --unused -y >> "$log_file" 2>&1

# COSMIC & Firmware
log_and_display INFO "Logging COSMIC Component Versions..."
dpkg -l | grep cosmic | awk '{print $2, $3}' >> "$update_summary"

log_and_display INFO "Checking for Firmware Updates..."
# Non-interactive firmware check; note: update may require a reboot
sudo fwupdmgr get-updates && sudo fwupdmgr update -y

# --- Finalization ---

TOTAL_SECONDS=$((SECONDS - START_TIME))
ELAPSED_TIME=$(printf '%dh:%dm:%ds\n' $((TOTAL_SECONDS/3600)) $((TOTAL_SECONDS%3600/60)) $((TOTAL_SECONDS%60)))

log_and_display INFO "Update summary saved to $update_summary"
log_and_display INFO "Total Duration: $ELAPSED_TIME"

if [ ${#FAILED_MANAGERS[@]} -eq 0 ]; then
    log_and_display INFO "ALL updates completed successfully! 🎉"
    echo "$now - Success (Duration: $ELAPSED_TIME)" >> "$HOME/logs/update_audit.txt"
else
    log_and_display ERROR "The following managers failed: ${FAILED_MANAGERS[*]}"
    echo "$now - Failed: ${FAILED_MANAGERS[*]} (Duration: $ELAPSED_TIME)" >> "$HOME/logs/update_audit.txt"
fi