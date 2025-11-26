#!/bin/bash

# DAW Uninstallation / Cleanup Script
# Description: Removes all components installed by the DAW setup script.
#              Use this to "reset" the system for testing.

##############################
# Configuration Variables
##############################

# Target user (same logic as install script)
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="/home/$TARGET_USER"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Helper function for logging
log() {
    echo -e "${RED}[UNINSTALL] $1${NC}"
}

# Ensure script is run with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use sudo."
   exit 1
fi

log "Starting Cleanup Process for user: $TARGET_USER"
sleep 2

##############################
# 1. Remove Applications & Binaries
##############################

# --- Remove REAPER ---
log "Removing REAPER..."
rm -rf /opt/REAPER
rm -f /usr/local/bin/reaper
rm -f "$USER_HOME/.local/share/applications/reaper-native.desktop"

# --- Remove Yabridge ---
log "Removing Yabridge..."
# Run yabridgectl clear just in case to unlink plugins
if command -v yabridgectl &> /dev/null; then
    sudo -u "$TARGET_USER" yabridgectl clear 2>/dev/null
fi
rm -rf /opt/yabridge*
rm -f /usr/local/bin/yabridge
rm -f /usr/local/bin/yabridgectl

# --- Remove Ratatouille ---
log "Removing Ratatouille..."
# Remove Standalone binary
rm -f /usr/local/bin/Ratatouille
# Remove LV2 Plugin (Standard install path for 'sudo make install')
rm -rf /usr/lib/lv2/Ratatouille.lv2
rm -rf /usr/local/lib/lv2/Ratatouille.lv2
# Remove Desktop shortcut
rm -f "$USER_HOME/.local/share/applications/ratatouille-standalone.desktop"

# --- Remove Scarlett Focus GUI ---
log "Removing Scarlett Focus GUI..."
# Default install location for this tool is usually /usr/local/bin or /usr/bin
rm -f /usr/local/bin/alsa-scarlett-gui
rm -f /usr/bin/alsa-scarlett-gui
# Remove its desktop file (usually installed to /usr/share/applications or /usr/local/share/applications)
rm -f /usr/share/applications/alsa-scarlett-gui.desktop
rm -f /usr/local/share/applications/alsa-scarlett-gui.desktop
# Remove source folder if it was left behind
rm -rf "$USER_HOME/alsa-scarlett-gui"

##############################
# 2. Remove Packages (apt/flatpak)
##############################

log "Uninstalling Flatpak Apps..."
flatpak uninstall -y --noninteractive org.guitarix.Guitarix
flatpak uninstall -y --noninteractive org.rncbc.qpwgraph
flatpak uninstall -y --noninteractive ar.com.tuxguitar.TuxGuitar

log "Uninstalling APT Packages..."
# List of packages from your install script
# NOTE: We use 'apt remove' here. Use 'apt purge' if you want to delete config files too.
PACKAGES_TO_REMOVE=(
    "wine-stable"
    "jackd2"
    "qjackctl"
    "pavucontrol"
    "nala"
)

# Optional: Remove build dependencies? 
# Uncomment the next line if you want to remove the compilers/headers too (Aggressive cleanup)
# PACKAGES_TO_REMOVE+=("libgtk-4-dev" "libasound2-dev" "libssl-dev" "lv2-dev" "build-essential")

apt remove -y "${PACKAGES_TO_REMOVE[@]}"
apt autoremove -y

##############################
# 3. Restore System Configurations
##############################

log "Removing PortAudio Configuration..."
rm -f /etc/ld.so.conf.d/portaudio.conf
ldconfig

##############################
# 4. Cleanup Directories (Optional)
##############################

log "Cleaning up VST Directories..."
# Only removing empty directories to be safe. 
# If you want to WIPE plugins, remove the rmdir and use rm -rf (Careful!)

rmdir "$USER_HOME/.vst" 2>/dev/null
rmdir "$USER_HOME/.vst3" 2>/dev/null
rmdir "$USER_HOME/VSTPlugins" 2>/dev/null
rmdir "$USER_HOME/VST3" 2>/dev/null

##############################
# Done
##############################
log "Uninstall Complete. System should be clean."
log "Note: User data/preferences in ~/.config/REAPER or ~/.config/yabridge were NOT deleted."