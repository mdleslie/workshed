#!/bin/bash

# Define the log file path
log_file="/home/$USER/install_log.txt"

# Function to log and display messages
log_and_display() {
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  message="$timestamp: $1"
  echo "$message" | lolcat
  echo "$message" >> "$log_file"
}

# List of .deb packages to install
deb_packages=(
  "fortune-mod"
  "cowsay"
  "folder-color"
  "ubuntu-restricted-extras"
  "ffmpeg"
  "mpv"
  "mediainfo"
  "vlc"
  "youtube-dl"
  "libdvdcss2"
  "libavcodec-extra"
  "libssl-dev"
  "libexpat1-dev"
  "libgl1-mesa-dev"
  "libgstreamer1.0-dev"
  "libgstreamer-plugins-base1.0-dev" 
  "libgstreamer-plugins-bad1.0-dev" 
  "gstreamer1.0-plugins-base" 
  "gstreamer1.0-plugins-good" 
  "gstreamer1.0-plugins-bad" 
  "gstreamer1.0-plugins-ugly" 
  "gstreamer1.0-libav" 
  "gstreamer1.0-tools" 
  "gstreamer1.0-x" 
  "gstreamer1.0-alsa" 
  "gstreamer1.0-gl" 
  "gstreamer1.0-gtk3" 
  "gstreamer1.0-qt5" 
  "gstreamer1.0-pulseaudio"
  "nfs-common"
  "cifs-utils"
  "gamemode"
  "lutris"
  "steam"
  "cpu-x"
  "python3"
  "pip"
  "figlet"
  "fonts-inter"
  "mangohud"
  "ncdu"
  "pydf"
)

# List of Flatpak applications to install
flatpak_apps=(
  "org.libreoffice.LibreOffice"
  "net.cozic.joplin_desktop"
  "com.synology.SynologyDrive"
  "com.brave.Browser"
  "org.kde.kdenlive"
  "fr.handbrake.ghb"
  "com.obsproject.Studio"
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
  "com.jeffser.Alpaca"
  "com.dropbox.Client"
)

# Array to store the names of installed .deb packages and Flatpak applications
installed_deb_packages=()
installed_flatpak_apps=()


# Check if lolcat is installed
if ! command -v lolcat &> /dev/null; then
    log_and_display " lolcat is not installed. Installing lolcat."
    sudo apt update && sudo apt install -y lolcat
fi

# Define log files
log_file="/home/$USER/install_log.txt"
update_summary="/home/$USER/install_summary.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    local color=$1
    local message=$2
    echo -e "${color}$message${NC}" | tee -a "$log_file"
    echo -e "${color}$message${NC}" | lolcat
}

# Error handling
set -e
trap 'log ERROR "An error occurred. Exit code: $?"' ERR

# Cleanup function
cleanup() {
    log INFO "Cleaning up..."
    
    # Remove any temporary files
    rm -f /tmp/install_script_*

    # Revert .bashrc if the script didn't complete successfully
    if [ -f ~/.bashrc.bak ] && [ "$script_completed" != "true" ]; then
        mv ~/.bashrc.bak ~/.bashrc
        log WARNING "Reverted .bashrc to original state."
    fi

    log INFO "Cleanup completed."
}

# Trap for cleanup
trap cleanup EXIT

# Variable to track script completion
script_completed="false"

# Function to cache sudo credentials
cache_sudo() {
    sudo -v
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null ) &
}

# Start of script
log INFO "Starting installation script"
display $BLUE "This script will automate setting up a clean OS install."
sleep 2s
display $YELLOW "Don't Mix Danger, Handle with Care!"
sleep 3s

# Cache sudo credentials
log INFO "Caching sudo credentials"
cache_sudo

# Update and upgrade system
log INFO "Updating and upgrading system"
display $GREEN "Preparing system before installing new applications."
sudo apt update
sudo apt upgrade -y

# Install Nala
log INFO "Installing Nala"
display $GREEN "Adding curl and installing Nala. Because it is better than apt."
sudo apt install curl -y
curl https://gitlab.com/volian/volian-archive/-/raw/main/install-nala.sh | bash
sudo nala update

# Remove LibreOffice
log INFO "Removing LibreOffice"
display $YELLOW "Removing the old packaged version of LibreOffice."
sudo nala remove --purge -y "libreoffice*"
sudo nala clean -y
sudo nala autoremove -y

# Debug: Print DESKTOP_SESSION
echo "DESKTOP_SESSION: $DESKTOP_SESSION"

# Install Gnome utilities if needed
if [[ "$DESKTOP_SESSION" =~ [Gg][Nn][Oo][Mm][Ee] ]]; then
    log "INFO" "Installing Gnome utilities"
    display "$GREEN" "Installing Gnome utilities."
    sudo apt install gnome-tweaks gnome-sushi imagemagick nautilus-image-converter nautilus-admin ffmpegthumbnailer -y
fi

# Check for Pop!_OS
os_name=$(lsb_release -si)
if [[ "$os_name" == "Pop" || "$os_name" == "Pop!_OS" ]]; then
    log INFO "Running Pop!_OS specific steps"
    display $GREEN "Running on Pop!_OS. Proceeding with installation and uninstallation."
    sudo nala install cosmic-icons cosmic-store -y
    sudo nala remove pop-shop -y
    sudo nala purge pop-shop -y
fi

# Install MakeMKV
log INFO "Installing MakeMKV"
display $GREEN "Installing MakeMKV from the heyarje repo."
sudo add-apt-repository -y ppa:heyarje/makemkv-beta
sudo nala update
sudo nala install makemkv-bin makemkv-oss -y

# Install FastFetch
log INFO "Installing FastFetch"
display $GREEN "Installing Fastfetch from the zhangsongcui repo."
sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
sudo nala update
sudo nala install fastfetch -y

# Preconfigure Microsoft fonts and libdvd-pkg
log INFO "Preconfiguring Microsoft fonts and libdvd-pkg"
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
sudo DEBIAN_FRONTEND=noninteractive apt -yq install libdvd-pkg
sudo bash /usr/lib/libdvd-pkg/b-i_libdvdcss.sh

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
        else
            log ERROR "Failed to install $package"
        fi
    fi
done

# Install Flatpak applications
log INFO "Installing Flatpak applications"
display $GREEN "Installing Flatpak applications."
if ! command -v flatpak &> /dev/null; then
    log INFO "Flatpak not installed, installing Flatpak"
    sudo nala install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

for app in "${flatpak_apps[@]}"; do
    if flatpak list | grep -qw "$app"; then
        log INFO "$app is already installed, skipping."
    else
        log INFO "Installing $app"
        if flatpak install -y --noninteractive flathub "$app" >> "$log_file" 2>&1; then
            installed_flatpak_apps+=("$app")
            log INFO "$app installed successfully"
        else
            log ERROR "Failed to install $app"
        fi
    fi
done

# Generate installation report
log INFO "Generating installation report"
if [ ${#installed_deb_packages[@]} -eq 0 ] && [ ${#installed_flatpak_apps[@]} -eq 0 ]; then
    log INFO "No new programs were installed"
else
    echo "Installed .deb packages:" >> "$update_summary"
    printf '%s\n' "${installed_deb_packages[@]}" >> "$update_summary"
    echo "Installed Flatpak applications:" >> "$update_summary"
    printf '%s\n' "${installed_flatpak_apps[@]}" >> "$update_summary"
fi

# Create update script
log INFO "Creating update script"
display $GREEN "Creating and downloading the update.sh script."
sudo curl -sL https://raw.githubusercontent.com/mdleslie/workshed/workshed/update.sh -o /usr/bin/update.sh
if [[ $? -ne 0 ]]; then
    log ERROR "Failed to download update.sh script"
    exit 1
fi
sudo chmod +x /usr/bin/update.sh

# Modify .bashrc file
log INFO "Modifying .bashrc file"
display $GREEN "Modifying .bashrc file to include useful aliases."
sudo cp ~/.bashrc ~/.bashrc.bak
curl -sL "https://github.com/mdleslie/workshed/raw/workshed/bash.rc%20aliases" | tee -a ~/.bashrc
if [[ $? -ne 0 ]]; then
    log ERROR "Failed to download bash.rc aliases"
    exit 1
fi

# Add Band Maid logo for fastfetch
log INFO "Adding Band Maid logo for fastfetch"
display $GREEN "Adding new logo for fastfetch. An impossibly hard rocking maid logo."
mkdir -p ~/.local/share/fastfetch/logos
curl -sL "https://github.com/mdleslie/workshed/raw/workshed/maid" -o ~/.local/share/fastfetch/logos/maid
if [[ $? -ne 0 ]]; then
    log ERROR "Failed to download maid logo"
    exit 1
fi

# Cleanup
log INFO "Performing final cleanup"
sudo nala autoremove -y
sudo nala clean -y

# Script completion
script_completed="true"
log INFO "Installation script completed successfully"
display $BLUE "Finishing up now. Shop smart, shop S-Mart."
sleep 3s

figlet Workshed | lolcat -a -d 3

log INFO "Installation summary saved to $update_summary"
display $GREEN "Installation summary saved to $update_summary"