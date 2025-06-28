#!/bin/bash

# Pop OS/Ubuntu Setup Script - Corrected Version
# Author: workshed mdltruck556@gmail.com
# Description: Automated setup script for fresh Pop OS.

# Define the log file path
log_file="/home/$USER/install_log.txt"
# Define the update summary file path
update_summary="/home/$USER/install_summary.txt"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# List of .deb packages to install
deb_packages=(
    "fortune-mod"
    "cowsay"
    "ubuntu-restricted-extras"
    "ffmpeg"
    "mpv"
    "mediainfo"
    "vlc"
    "libssl-dev"
    "libexpat1-dev"
    "libgl1-mesa-dev"
    "libgstreamer1.0-dev"
    "libgstreamer-plugins-base1.0-dev"
    "libgstreamer-plugins-bad1.0-dev"
    "gstreamer1.0-plugins-bad"
    "gstreamer1.0-qt5"
    "gstreamer1.0-plugins-ugly"
    "gstreamer1.0-plugins-good"
    "gstreamer1.0-libav"
    "libavcodec-extra"
    "chromium-codecs-ffmpeg-extra"
    "nfs-common"
    "cifs-utils"
    "gamemode"
    "lutris"
    "steam"
    "cpu-x"
    "python3"
    "python3-pip"
    "figlet"
    "fonts-inter"
    "mangohud"
    "ncdu"
    "pydf"
    "ffmpegthumbnailer"
    "bind9-dnsutils"
    "inetutils-traceroute"
    "whois"
    "nmap"
    "btop"
    "cmake"
    "libcairo2-dev"
    "libx11-dev"
    "lv2-dev"
    "nasm"
    "obs-studio"
    "qjackctl"
)

# List of Flatpak applications to install
flatpak_apps=(
    "net.cozic.joplin_desktop"
    "com.synology.SynologyDrive"
    "com.brave.Browser"
    "org.kde.kdenlive"
    "fr.handbrake.ghb"
    "io.missioncenter.MissionCenter"
    "org.telegram.desktop"
    "com.bitwarden.desktop"
    "io.github.aandrew_me.ytdn"
    "org.localsend.localsend_app"
    "io.github.shiftey.Desktop"
    "com.github.tchx84.Flatseal"
    "eu.betterbird.Betterbird"
    "net.davidotek.pupgui2"
    "com.vscodium.codium"
    "org.jdownloader.JDownloader"
    "com.github.qarmin.czkawka"
    "org.darktable.Darktable"
    "com.google.Chrome"
    "io.github.flattool.Warehouse"
    "fm.reaper.Reaper"
    "org.guitarix.Guitarix"
    "com.discordapp.Discord"
    "org.kde.haruna"
    "com.github.IsmaelMartinez.teams_for_linux"
    "com.github.taiko2k.tauonmb"
    "com.makemkv.MakeMKV"
    "org.inkscape.Inkscape"
    "ar.com.tuxguitar.TuxGuitar"
    "com.rtosta.zapzap"
    "us.zoom.Zoom"
    "com.dropbox.Client"
    "org.rncbc.qpwgraph"
)


# Check if lolcat is installed, install if not
if ! command -v lolcat &> /dev/null; then
    echo -e "${YELLOW}lolcat not found, installing it now...${NC}"
    sudo apt update > /dev/null 2>&1 # Ensure apt cache is updated for lolcat
    sudo apt install lolcat -y
    if ! command -v lolcat &> /dev/null; then
        echo -e "${RED}Failed to install lolcat. Proceeding without colorful output.${NC}"
    fi
fi

# Function to log messages to file and optionally to syslog
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$log_file"
    # Using 'logger' requires rsyslog or systemd-journald to be running.
    # It's generally fine, but keep in mind it logs to system-wide logs.
    logger -p user."$level" "$message"
}

# Function to display colorful messages and log them
display() {
    local color=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Log to file first
    echo "[$timestamp] [DISPLAY] $message" >> "$log_file"

    # Display with color, using lolcat if available and stdout is a terminal
    if command -v lolcat &> /dev/null && [ -t 1 ]; then
        echo -e "${color}$message${NC}" | lolcat
    else
        echo -e "${color}$message${NC}"
    fi
}

# Function to optionally pipe output to lolcat if stdout is a terminal
lol() {
    if [ -t 1 ] && command -v lolcat &> /dev/null; then
        "$@" | lolcat
    else
        "$@"
    fi
}

# Helper function for safe curl operations
safe_curl() {
    local url="$1"
    local output="$2"
    local description="${3:-file}"

    log INFO "Attempting to download $description from $url to $output"
    if curl -sL "$url" -o "$output"; then
        if [[ -s "$output" ]]; then
            log INFO "Successfully downloaded $description from $url"
            return 0
        else
            log ERROR "Downloaded $description is empty from $url. Removing empty file."
            rm -f "$output"
            return 1
        fi
    else
        log ERROR "Failed to download $description from $url (curl exit code: $?). Removing incomplete file."
        rm -f "$output"
            return 1
    fi
}

# Error handling: Exit immediately if a command exits with a non-zero status.
set -e
# Trap to log errors during execution.
trap 'log ERROR "An error occurred during script execution. Exit code: $?"' ERR

# Variable to track script completion and operations performed
script_completed="false"
bashrc_backed_up="false"
fstab_backed_up="false"
sudo_keeper_pid="" # Initialize sudo_keeper_pid

# Cleanup function to run on script exit (even on error)
cleanup() {
    log INFO "Performing final cleanup..."

    # Revert .bashrc if the script didn't complete successfully
    if [[ "$bashrc_backed_up" == "true" ]] && [[ "$script_completed" != "true" ]] && [[ -f ~/.bashrc.bak ]]; then
        mv ~/.bashrc.bak ~/.bashrc
        log WARNING "Reverted .bashrc to original state due to incomplete script run."
    fi

    # Kill sudo credential caching if running
    if [[ -n "${sudo_keeper_pid:-}" ]]; then
        kill "$sudo_keeper_pid" 2>/dev/null || true
        log INFO "Sudo credential caching process stopped (PID: $sudo_keeper_pid)."
    fi

    log INFO "Cleanup completed."
}

# Trap the EXIT signal to call the cleanup function
trap cleanup EXIT

# Function to cache sudo credentials (keep sudo session alive)
cache_sudo() {
    log INFO "Requesting sudo password to cache credentials for the script duration."
    if ! sudo -v; then # Request sudo password upfront
        log ERROR "Failed to obtain sudo privileges. Exiting script."
        exit 1
    fi
    # Keep sudo session alive in the background
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null ) &
    # Store the PID of the background process for later killing
    sudo_keeper_pid=$!
    log INFO "Sudo credential caching started (PID: $sudo_keeper_pid). Sudo will be kept alive."
}

# --- SCRIPT START ---
log INFO "Starting Pop OS/Ubuntu Setup Script"
display "$GREEN" "Let's go, it's showtime!"
sleep 2

lol figlet "Workshed"
echo '########################################' | lolcat
display "$GREEN" "This script will automate setting up a clean OS install."
sleep 2
echo '########################################' | lolcat

display "$BLUE" "Don't Mix Danger, Handle with Care! This script makes significant system changes."
sleep 3
display "$RED" "Review the script contents before proceeding."
sleep 3
echo '########################################' | lolcat

## User Authentication and Credential Management
log INFO "Entering User Authentication and Credential Management section."
display "$YELLOW" "Authenticating user and managing credentials."

# Cache sudo credentials for the duration of the script
cache_sudo

# --- OPTIONAL: Handle Other Credentials Securely (e.g., for NFS shares with authentication) ---
# For network shares that require a username and password (e.g., SMB/CIFS or some NFS setups),
# DO NOT hardcode credentials directly in the script.
#
# Recommendations for handling other credentials:
# 1. Prompt the user for credentials at runtime (least secure for automation, but most interactive).
# 2. Use a secrets management tool (e.g., HashiCorp Vault, KeePassXC, Gnome Keyring) to retrieve them.
# 3. Store credentials in a permission-restricted file (e.g., ~/.smbcredentials with 0600 permissions)
#    and read them from there. This is common for fstab entries for SMB/CIFS mounts.
#
# Example (conceptual, for demonstration for fstab):
# NFS in your script is using 'defaults' which implies no authentication.
# If you were mounting an SMB share that needed user/pass:
# read -sp "Enter SMB username: " smb_user
# echo
# read -sp "Enter SMB password: " smb_pass
# echo
# # Then use $smb_user and $smb_pass for the mount command or fstab entry.
# # Remember to clear variables after use if they held sensitive info.
# unset smb_user smb_pass
log INFO "Finished User Authentication and Credential Management section. Sudo active."
echo '########################################' | lolcat

# Update and upgrade system
log INFO "Updating and upgrading system"
display "$GREEN" "Preparing system before installing new applications."
sleep 2
if sudo apt update -y && sudo apt upgrade -y; then
    log INFO "System updated and upgraded successfully."
else
    log ERROR "Failed to update or upgrade the system."
    exit 1
fi
echo '########################################' | lolcat

# Install Nala
log INFO "Installing Nala"
display "$GREEN" "Adding curl and installing Nala, as it's often preferred over apt."
sleep 3
if ! command -v curl &> /dev/null; then
    log INFO "curl not found, installing curl."
    if ! sudo apt install curl -y; then
        log ERROR "Failed to install curl. Nala installation might fail."
        exit 1
    fi
fi

# Download and install Nala safely
if safe_curl "https://gitlab.com/volian/volian-archive/-/raw/main/install-nala.sh" "/tmp/install-nala.sh" "Nala installation script"; then
    log INFO "Executing Nala installation script."
    if sudo bash /tmp/install-nala.sh; then
        log INFO "Nala installation script executed successfully."
        rm -f /tmp/install-nala.sh
        if sudo nala update; then
            log INFO "Nala updated successfully."
        else
            log WARNING "Failed to update Nala after installation."
        fi
    else
        log ERROR "Nala installation script failed to execute. Exiting."
        rm -f /tmp/install-nala.sh
        exit 1
    fi
else
    log ERROR "Failed to download Nala installation script. Exiting."
    exit 1
fi
echo '########################################' | lolcat

# Install FastFetch
log INFO "Installing FastFetch"
display "$GREEN" "Installing Fastfetch from the zhangsongcui repo."
sleep 3
if sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch && sudo nala update && sudo nala install fastfetch -y; then
    log INFO "Fastfetch installed successfully."
else
