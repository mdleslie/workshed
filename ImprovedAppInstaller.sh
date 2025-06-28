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

# Function to log messages to file and optionally to syslog
# This function is used by 'log INFO', 'log ERROR', 'log WARNING'
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$log_file"
    # Using 'logger' requires rsyslog or systemd-journald to be running.
    # It's generally fine, but keep in mind it logs to system-wide logs.
    logger -p user.$level "$message"
}

# Function to display colorful messages and log them
# Fixed to avoid duplicate output when lolcat is available
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
# This function is intended to be used with command output, e.g., 'lol figlet Workshed'
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
    
    if curl -sL "$url" -o "$output"; then
        if [[ -s "$output" ]]; then
            log INFO "Successfully downloaded $description from $url"
            return 0
        else
            log ERROR "Downloaded $description is empty from $url"
            rm -f "$output"
            return 1
        fi
    else
        log ERROR "Failed to download $description from $url (curl exit code: $?)"
        rm -f "$output"
        return 1
    fi
}

# Error handling: Exit immediately if a command exits with a non-zero status.
set -e
# Trap to log errors during execution.
trap 'log ERROR "An error occurred. Exit code: $?"' ERR

# Variable to track script completion and operations performed
script_completed="false"
bashrc_backed_up="false"
fstab_backed_up="false"

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
        log INFO "Sudo credential caching process stopped."
    fi

    log INFO "Cleanup completed."
}

# Trap the EXIT signal to call the cleanup function
trap cleanup EXIT

# Function to cache sudo credentials (keep sudo session alive)
cache_sudo() {
    sudo -v # Request sudo password upfront
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null ) &
    # Store the PID of the background process for later killing if needed
    sudo_keeper_pid=$!
    log INFO "Sudo credential caching started (PID: $sudo_keeper_pid)."
}

# --- SCRIPT START ---
log INFO "Starting installation script"
display $GREEN "Let's go, it's showtime!"
sleep 3

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

display $GREEN "This script will automate setting up a clean OS install."
sleep 3
echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

display $BLUE "Don't Mix Danger, Handle with Care!"
sleep 2
display $RED "Don't Mix Danger, Handle with Care!"
sleep 3

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Cache sudo credentials
log INFO "Caching sudo credentials"
cache_sudo

# Update and upgrade system
log INFO "Updating and upgrading system"
display $GREEN "Preparing system before installing new applications."
sleep 2
sudo apt update -y
sudo apt upgrade -y

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Install Nala
log INFO "Installing Nala"
display $GREEN "Adding curl and installing Nala. Because it is better than apt."
sleep 3
sudo apt install curl -y

# Download and install Nala safely
if safe_curl "https://gitlab.com/volian/volian-archive/-/raw/main/install-nala.sh" "/tmp/install-nala.sh" "Nala installation script"; then
    sudo bash /tmp/install-nala.sh
    rm -f /tmp/install-nala.sh
    sudo nala update
else
    log ERROR "Failed to install Nala. Exiting."
    exit 1
fi

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Install FastFetch
log INFO "Installing FastFetch"
display $GREEN "Installing Fastfetch from the zhangsongcui repo."
sleep 3
sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
sudo nala update
sudo nala install fastfetch -y

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Preconfigure Microsoft fonts and libdvd-pkg
log INFO "Preconfiguring Microsoft fonts and libdvd-pkg"
# Ensure DEBIAN_FRONTEND is noninteractive for debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections
# For libdvd-pkg, the DEBIAN_FRONTEND must be set for the command itself
sudo DEBIAN_FRONTEND=noninteractive apt -yq install libdvd-pkg
sudo bash /usr/lib/libdvd-pkg/b-i_libdvdcss.sh
unset DEBIAN_FRONTEND

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Pre-configure debconf settings for jackd2 to accept real-time priority.
log INFO "Preconfiguring Jackd2 with real time priority."
echo "jackd2 jackd2/install_type boolean true" | sudo debconf-set-selections
echo "jackd2 jackd2/rt_allow boolean true" | sudo debconf-set-selections
echo "jackd2 jackd2/priority string 99" | sudo debconf-set-selections

echo "Installing jackd2..."
sudo apt-get install -y jackd2

# Add the current user to the 'audio' group. This is crucial for real-time
# audio processing with JACK. If the user is already in the group, it will
# not cause an error.
if ! id -nG "$USER" | grep -qw "audio"; then
    log INFO "Adding user '$USER' to the 'audio' group."
    if sudo usermod -a -G audio "$USER"; then
        log INFO "Successfully added user '$USER' to audio group."
        display $YELLOW "Please log out and log back in for the 'audio' group membership to take effect."
    else
        log ERROR "Failed to add user '$USER' to audio group."
        exit 1
    fi
else
    log INFO "User '$USER' is already in the 'audio' group."
fi

echo '########################################' | lolcat
echo '########################################' | lolcat
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
display $GREEN "Installing .deb packages."
for package in "${deb_packages[@]}"; do
    if dpkg -l | grep -qw "$package"; then
        log INFO "$package is already installed, skipping."
    else
        log INFO "Installing $package"
        if sudo nala install -y "$package"; then
            installed_deb_packages+=("$package")
            log INFO "Successfully installed $package"
        else
            log ERROR "Failed to install $package."
        fi
    fi
done

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Install Flatpak applications
log INFO "Installing Flatpak applications"
display $GREEN "Installing Flatpak applications."

# Ensure Flatpak is installed
if ! command -v flatpak &> /dev/null; then
    log INFO "Flatpak not installed, installing Flatpak"
    sudo nala install -y flatpak
fi

# Add Flathub remote if not already present
if ! flatpak remotes | grep -q "flathub"; then
    log INFO "Adding Flathub remote"
    if flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
        log INFO "Successfully added Flathub remote"
    else
        log ERROR "Failed to add Flathub remote"
        exit 1
    fi
else
    log INFO "Flathub remote already exists"
fi

for app in "${flatpak_apps[@]}"; do
    if flatpak list | grep -qw "$app"; then
        log INFO "$app is already installed, skipping."
    else
        log INFO "Installing $app"
        if flatpak install -y --noninteractive flathub "$app" >> "$log_file" 2>&1; then
            installed_flatpak_apps+=("$app")
            log INFO "Successfully installed $app"
        else
            log ERROR "Failed to install $app. Check log for details."
        fi
    fi
done

echo '########################################' | lolcat
echo '########################################' | lolcat
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
        printf '%s\n' "${installed_deb_packages[@]}" >> "$update_summary"
    fi
    if [ ${#installed_flatpak_apps[@]} -gt 0 ]; then
        echo "" >> "$update_summary"
        echo "Installed Flatpak applications:" >> "$update_summary"
        printf '%s\n' "${installed_flatpak_apps[@]}" >> "$update_summary"
    fi
fi
log INFO "Installation summary saved to $update_summary"
display $GREEN "Installation summary saved to $update_summary"

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Create update script
log INFO "Creating update script"
display $GREEN "Creating and downloading the update.sh script."

update_script="/usr/bin/update.sh"
if safe_curl "https://raw.githubusercontent.com/mdleslie/workshed/workshed/update.sh" "$update_script" "update.sh script"; then
    sudo chmod +x "$update_script"
    log INFO "Successfully set up update.sh script with executable permissions."
else
    log ERROR "Failed to download and set up update.sh script."
    exit 1
fi

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Modify .bashrc file
log INFO "Modifying .bashrc file"
display $GREEN "Modifying .bashrc file to include useful aliases."

# Backup existing .bashrc
if cp ~/.bashrc ~/.bashrc.bak; then
    bashrc_backed_up="true"
    log INFO "Backed up ~/.bashrc to ~/.bashrc.bak."
else
    log ERROR "Failed to backup ~/.bashrc"
    exit 1
fi

# Download and append aliases
aliases_url="https://raw.githubusercontent.com/mdleslie/workshed/workshed/bash.rc%20aliases"
aliases_temp="/tmp/bash_aliases_temp"

if safe_curl "$aliases_url" "$aliases_temp" "bash aliases"; then
    echo -e "\n# Added by Pop OS/Ubuntu Setup Script" >> ~/.bashrc
    cat "$aliases_temp" >> ~/.bashrc
    rm -f "$aliases_temp"
    log INFO "Successfully added aliases to .bashrc."
    display $GREEN "To apply changes, run 'source ~/.bashrc' or start a new terminal session."
else
    log ERROR "Failed to download and add bash aliases."
    exit 1
fi

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Modify fstab file
log INFO "Modifying fstab file"
display $BLUE "Modifying fstab file to include NFS mount to Arkive."

# Create mount point
if sudo mkdir -p /mnt/Arkive; then
    log INFO "Created mount point /mnt/Arkive."
else
    log ERROR "Failed to create mount point /mnt/Arkive."
    exit 1
fi

# Backup existing fstab
if sudo cp /etc/fstab /etc/fstab.bak; then
    fstab_backed_up="true"
    log INFO "Backed up /etc/fstab to /etc/fstab.bak."
else
    log ERROR "Failed to backup /etc/fstab."
    exit 1
fi

# Download and append NFS mount entry
fstab_entry_url="https://raw.githubusercontent.com/mdleslie/workshed/workshed/fstab"
fstab_temp="/tmp/fstab_entry_temp"

if safe_curl "$fstab_entry_url" "$fstab_temp" "fstab entry"; then
    if sudo tee -a /etc/fstab < "$fstab_temp" > /dev/null; then
        rm -f "$fstab_temp"
        log INFO "Successfully added NFS mount entry to fstab."
        log INFO "Successfully modified fstab. Manual verification of mounts is recommended."
    else
        log ERROR "Failed to append NFS entry to /etc/fstab."
        exit 1
    fi
else
    log ERROR "Failed to download NFS mount fstab entry."
    exit 1
fi

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Add Band Maid logo for fastfetch
log INFO "Adding Band Maid logo for fastfetch"
display $GREEN "Adding new logo for fastfetch. An impossibly hard rocking maid logo."

# Create directory for fastfetch logos
if mkdir -p ~/.local/share/fastfetch/logos; then
    log INFO "Created fastfetch logos directory."
else
    log ERROR "Failed to create fastfetch logos directory."
    exit 1
fi

if safe_curl "https://raw.githubusercontent.com/mdleslie/workshed/workshed/maid" ~/.local/share/fastfetch/logos/maid "Band Maid logo"; then
    log INFO "Successfully downloaded Band Maid logo."
else
    log ERROR "Failed to download Band Maid logo."
    exit 1
fi

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Add config for Pipewire
log INFO "Adding configuration for Pipewire"
display $GREEN "Adding configuration for Pipewire. Setting sample rate and buffer size."

# Create the pipewire config directory
if mkdir -p ~/.config/pipewire/; then
    log INFO "Created Pipewire config directory."
else
    log ERROR "Failed to create Pipewire config directory."
    exit 1
fi

config_path=~/.config/pipewire/pipewire.conf
if safe_curl "https://raw.githubusercontent.com/mdleslie/workshed/workshed/pipewire.conf" "$config_path" "Pipewire config"; then
    log INFO "Successfully downloaded Pipewire config to $config_path."
else
    log ERROR "Failed to download Pipewire config."
    exit 1
fi

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Cleanup
log INFO "Performing final system cleanup"
sudo nala autoremove -y
sudo nala clean

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Script completion
script_completed="true" # Mark script as successfully completed
log INFO "Installation script completed successfully."
display $BLUE "Finishing up now. Shop smart, shop S-Mart."

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

lol figlet Workshed # Use 'lol' function for figlet

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat
display $RED "Don't mix danger, handle with care!"
display $GREEN "Po."