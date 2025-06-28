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
    log ERROR "Failed to install Fastfetch."
    exit 1
fi
echo '########################################' | lolcat

# Preconfigure Microsoft fonts and libdvd-pkg
log INFO "Preconfiguring Microsoft fonts and libdvd-pkg for unattended install."
display "$GREEN" "Setting up Microsoft fonts EULA and libdvd-pkg."

# Pre-accept Microsoft fonts EULA
if echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections; then
    log INFO "Microsoft fonts EULA pre-accepted."
else
    log ERROR "Failed to pre-accept Microsoft fonts EULA."
    exit 1
fi

# Install ttf-mscorefonts-installer and libdvd-pkg non-interactively
export DEBIAN_FRONTEND=noninteractive
if sudo apt-get -yq install ttf-mscorefonts-installer libdvd-pkg; then
    log INFO "Microsoft fonts and libdvd-pkg installed."

    # Execute the libdvdcss build script directly for unattended build
    display "$YELLOW" "Running libdvd-pkg build script for libdvdcss non-interactively..."
    if sudo bash /usr/lib/libdvd-pkg/b-i_libdvdcss.sh; then
        log INFO "libdvdcss build script executed successfully. libdvdcss should be installed."
    else
        log ERROR "Failed to execute libdvdcss build script. DVD playback might be affected."
        exit 1 # Exit if libdvdcss cannot be built, as it's critical for DVDs.
    fi
else
    log ERROR "Failed to install Microsoft fonts or libdvd-pkg."
    exit 1 # This is a critical step, so exit if it fails.
fi
unset DEBIAN_FRONTEND # Unset DEBIAN_FRONTEND after non-interactive operations
echo '########################################' | lolcat

# Pre-configure debconf settings for jackd2 to accept real-time priority.
log INFO "Preconfiguring Jackd2 with real-time priority for unattended install."
display "$GREEN" "Configuring Jackd2 for real-time audio and adding user to audio group."

# Set DEBIAN_FRONTEND for non-interactive installation
export DEBIAN_FRONTEND=noninteractive

# Pre-set debconf selections for jackd2
if echo "jackd2 jackd2/install_type boolean true" | sudo debconf-set-selections && \
   echo "jackd2 jackd2/rt_allow boolean true" | sudo debconf-set-selections && \
   echo "jackd2 jackd2/priority string 99" | sudo debconf-set-selections; then
    log INFO "Jackd2 debconf settings preconfigured."
else
    log ERROR "Failed to preconfigure Jackd2 debconf settings. Installation might prompt for input."
    # Continue, but note the potential for interruption.
fi

log INFO "Installing jackd2..."
# Explicitly use DEBIAN_FRONTEND=noninteractive for the apt install command
if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y jackd2; then
    log INFO "Jackd2 installed successfully."
    # Similar to libdvd-pkg, trigger any post-install setup for jackd2 if necessary.
    # While jackd2 doesn't have a direct equivalent to b-i_libdvdcss.sh,
    # ensuring debconf settings are applied *before* install is the key.
    # dpkg-reconfigure jackd2 might be an option if issues persist, but usually
    # setting debconf selections and installing handles it.
else
    log ERROR "Failed to install jackd2. Audio applications might be affected."
    exit 1 # This is a critical step, so exit if it fails.
fi

unset DEBIAN_FRONTEND # Unset DEBIAN_FRONTEND after non-interactive operations

# Add the current user to the 'audio' group.
if ! id -nG "$USER" | grep -qw "audio"; then
    log INFO "Adding user '$USER' to the 'audio' group."
    if sudo usermod -a -G audio "$USER"; then
        log INFO "Successfully added user '$USER' to audio group."
        display "$YELLOW" "Please log out and log back in for the 'audio' group membership to take effect for real-time audio."
    else
        log ERROR "Failed to add user '$USER' to audio group."
        exit 1 # Exit if user cannot be added to audio group, as real-time audio won't work.
    fi
else
    log INFO "User '$USER' is already in the 'audio' group."
fi
echo '########################################' | lolcat

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
    "com.mattermost.Desktop"
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

# Array to store the names of installed .deb packages and Flatpak applications
installed_deb_packages=()
installed_flatpak_apps=()

# Install .deb packages
log INFO "Installing .deb packages"
display "$GREEN" "Installing core .deb packages."
for package in "${deb_packages[@]}"; do
    if dpkg -s "$package" &> /dev/null; then # Use dpkg -s for more reliable check
        log INFO "$package is already installed, skipping."
    else
        log INFO "Attempting to install $package"
        if sudo nala install -y "$package"; then
            installed_deb_packages+=("$package")
            log INFO "Successfully installed $package"
        else
            log ERROR "Failed to install $package. Skipping to next package."
        fi
    fi
done
echo '########################################' | lolcat

# Install Flatpak applications
log INFO "Installing Flatpak applications"
display "$GREEN" "Installing Flatpak applications from Flathub."

# Ensure Flatpak is installed
if ! command -v flatpak &> /dev/null; then
    log INFO "Flatpak not found, attempting to install Flatpak."
    if ! sudo nala install -y flatpak; then
        log ERROR "Failed to install Flatpak. Cannot install Flatpak applications."
        exit 1 # Flatpak apps are a major part, exit if Flatpak itself fails
    fi
fi

# Add Flathub remote if not already present
if ! flatpak remotes | grep -q "flathub"; then
    log INFO "Adding Flathub remote."
    if flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
        log INFO "Successfully added Flathub remote."
    else
        log ERROR "Failed to add Flathub remote. Flatpak applications might not be installable."
        # Continue, but Flatpak installations will likely fail
    fi
else
    log INFO "Flathub remote already exists."
fi

for app in "${flatpak_apps[@]}"; do
    # Check if flatpak info for the app exists, indicating it's installed
    if flatpak info "$app" &> /dev/null; then
        log INFO "$app is already installed, skipping."
    else
        log INFO "Attempting to install Flatpak application: $app"
        if flatpak install -y --noninteractive flathub "$app" >> "$log_file" 2>&1; then
            installed_flatpak_apps+=("$app")
            log INFO "Successfully installed $app"
        else
            log ERROR "Failed to install Flatpak application: $app. Check $log_file for details. Skipping to next Flatpak app."
        fi
    fi
done
echo '########################################' | lolcat

# Generate installation report
log INFO "Generating installation report"
# Clear previous summary content
> "$update_summary"
if [ ${#installed_deb_packages[@]} -eq 0 ] && [ ${#installed_flatpak_apps[@]} -eq 0 ]; then
    log INFO "No new programs were installed in this run."
    echo "No new programs were installed in this run." >> "$update_summary"
else
    echo "--- Newly Installed Programs ---" >> "$update_summary"
    if [ ${#installed_deb_packages[@]} -gt 0 ]; then
        echo "" >> "$update_summary"
        echo "Installed .deb packages:" >> "$update_summary"
        printf '%s\
