# Pop OS/Ubuntu Setup Script - Cleaning up my mess version
# well, trying to, anyway
# Author: workshed
# Description: Automated setup script for fresh Pop OS/Ubuntu installations
# Define the log file path

log_file="/home/$USER/install_log.txt"

# Function to log and display messages

log_and_display() {
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  message="$timestamp: $1"
  echo "$message"
  echo "$message" >> "$log_file"
}

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
  "fastfetch"
)

# List of Flatpak applications to install

flatpak_apps=(
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
  "org.darktable.Darktable"
  "com.mattermost.Desktop"
  "com.google.Chrome"
  "io.github.flattool.Warehouse"
  "fm.reaper.Reaper"
  "org.guitarix.Guitarix"
  "com.discordapp.Discord"
  "com.github.IsmaelMartinez.teams_for_linux"
  "com.github.taiko2k.tauonmb"
  "org.inkscape.Inkscape"
  "ar.com.tuxguitar.TuxGuitar"
  "com.rtosta.zapzap"
  "us.zoom.Zoom"
  "com.dropbox.Client"
  "md.obsidian.Obsidian"
  "com.github.unrud.VideoDownloader"
  "app.zen_browser.zen"
  "org.rncbc.qpwgraph"
  "it.mijorus.gearlever"
)

# Array to store the names of installed .deb packages and Flatpak applications

installed_deb_packages=()

installed_flatpak_apps=()

# Check if lolcat is installed

if ! command -v lolcat &> /dev/null; then
    log_and_display " lolcat is not installed. Installing lolcat."
    sleep 5s
    sudo apt update && sudo apt install -y lolcat
fi

echo '########################################' | lolcat

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

# Function to check if the output is a terminal

lol() {
  if [ -t 1 ]; then
    "$@" | lolcat
  else
    "$@"
  fi
}

# Bind the function to the RETURN key

bind 'RETURN: "\e[1~lol \e[4~\n"'

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

# Start of script installation message

log INFO "Starting installation script"
display $GREEN "Lets go, it's showtime!"
sleep 5s
display $GREEN "This script will automate setting up a clean OS install."
sleep 5s

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Cache sudo credentials

log INFO "Caching sudo credentials"
cache_sudo

# Update and upgrade system

log INFO "Updating and upgrading system"
display $GREEN "Preparing system before installing new applications."
sleep 5s
sudo apt update
sudo apt upgrade -y

echo '########################################' | lolcat

# Install Nala

log INFO "Installing Nala"
display $GREEN "Adding curl and installing Nala. Because it is better than apt."
sleep 5s
sudo apt install curl -y
curl https://gitlab.com/volian/volian-archive/-/raw/main/install-nala.sh | bash
sudo nala update

echo '########################################' | lolcat
echo '########################################' | lolcat

# Install FastFetch
# This section should not be needed anymore, as fastfetch should be in the ubuntu repos as of 24.10. Will test.
#log INFO "Installing FastFetch"
#display $GREEN "Installing Fastfetch from the zhangsongcui repo."
#sleep 5s
#sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
#sudo nala update
#sudo nala install fastfetch -y

echo '########################################' | lolcat

# Preconfigure Microsoft fonts and libdvd-pkg
log INFO "Preconfiguring Microsoft fonts and libdvd-pkg"
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
sudo DEBIAN_FRONTEND=noninteractive apt -yq install libdvd-pkg
sudo bash /usr/lib/libdvd-pkg/b-i_libdvdcss.sh
unset DEBIAN_FRONTEND

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

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

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

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
        if flatpak install -y --noninteractive flathub "$app" &>> "$log_file"; then
            installed_flatpak_apps+=("$app")
            # The success message is now logged via the redirection above.
        else
            log ERROR "Failed to install $app"
        fi
    fi
done

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

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

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

#For future use
#For future use

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Create update script

log INFO "Creating update script"
display $GREEN "Creating and downloading the update.sh script."
sleep 5s
update_script="/usr/bin/update.sh"
sudo curl -sL https://raw.githubusercontent.com/mdleslie/workshed/workshed/update.sh -o "$update_script"
if [[ $? -eq 0 && -s "$update_script" ]]; then
    sudo chmod +x "$update_script"
    log INFO "Successfully downloaded and set up update.sh script"
else
    log ERROR "Failed to download update.sh script or the downloaded file is empty"
    sudo rm -f "$update_script"  # Clean up in case of a partial download
    exit 1
fi

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Modify .bashrc file

log INFO "Modifying .bashrc file"
display $GREEN "Modifying .bashrc file to include useful aliases."
sleep 5s
# Backup existing .bashrc
cp ~/.bashrc ~/.bashrc.bak

# Download and append aliases
aliases=$(curl -sL "https://raw.githubusercontent.com/mdleslie/workshed/workshed/bash.rc%20aliases")
if [[ $? -eq 0 && -n "$aliases" ]]; then
    echo -e "\n# Added aliases\n$aliases" >> ~/.bashrc
    if [[ $? -eq 0 ]]; then
        log INFO "Successfully added aliases to .bashrc"
    else
        log ERROR "Failed to modify .bashrc file"
        exit 1
    fi
else
    log ERROR "Failed to download bash.rc aliases"
    exit 1
fi

log INFO "Successfully modified .bashrc"
display $GREEN "To apply changes, run 'source ~/.bashrc' or start a new terminal session."

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Modify fstab file
log INFO "Modifying fstab file"
display $BLUE "Modifying fstab file to include NFS mount to Arkive."
sleep 5s

# Create mount points
sudo mkdir -p /mnt/Arkive
sudo mkdir -p /mnt/Merlin
sudo mkdir -p /mnt/Unraid

# Backup existing fstab
sudo cp /etc/fstab /etc/fstab.bak

# Download and append NFS mount entry

fstab_entry=$(curl -sL "https://raw.githubusercontent.com/mdleslie/workshed/workshed/fstab")
if [[ $? -eq 0 && -n "$fstab_entry" ]]; then  # Check curl exit code AND file content
    echo "$fstab_entry" | sudo tee -a /etc/fstab > /dev/null
    if [[ $? -eq 0 ]]; then
        log INFO "Successfully added NFS mount entry to fstab"
    else
        log ERROR "Failed to modify fstab file (writing to /etc/fstab)."
        exit 1
    fi
else
    log ERROR "Failed to download NFS mount fstab entry. Curl exited with code $?"
    exit 1
fi

# Test section, might be able to add this section again with new Pop OS release #
# Validate fstab

#if ! sudo mount -a; then
#    log ERROR "Failed to mount all entries in fstab. Please check /etc/fstab for errors."
#    exit 1
#fi

#log INFO "Successfully modified fstab and verified mounts"

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Add Band Maid logo for fastfetch

log INFO "Adding Band Maid logo for fastfetch"
display $GREEN "Adding new logo for fastfetch. An impossibly hard rocking maid logo, po."
sleep 5s
mkdir -p ~/.local/share/fastfetch/logos
curl -sL "https://raw.githubusercontent.com/mdleslie/workshed/workshed/maid" -o ~/.local/share/fastfetch/logos/maid
if [[ $? -eq 0 && -s ~/.local/share/fastfetch/logos/maid ]]; then  # Check exit code AND file size
    log INFO "Successfully downloaded Band Maid logo"
else
    log ERROR "Failed to download Band Maid logo. Curl exited with code $?"
    exit 1
fi

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# --- Changing PUID and PGID for NFS mounting of Arkive nas. ---
# Note: Variables should be defined once at the top of the script
USER_NAME="david" # The user whose IDs are being changed
NEW_PUID="1026"
NEW_PGID="100"
# ------------------------------

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

log INFO "Starting PUID/PGID change for user ${USER_NAME}."
display $GREEN "Changing PUID/PGID for user ${USER_NAME}."
sleep 2s

# 1. Change the Primary Group ID (PGID)
log INFO "Attempting to change PGID for group ${USER_NAME} to ${NEW_PGID}."
if sudo groupmod -g ${NEW_PGID} ${USER_NAME}; then
    log INFO "Group ID (PGID) successfully changed to ${NEW_PGID}."
else
    log ERROR "Failed to change PGID for group ${USER_NAME} to ${NEW_PGID}."
    # Optionally exit or continue with a warning
fi

# 2. Change the User ID (PUID)
log INFO "Attempting to change PUID for user ${USER_NAME} to ${NEW_PUID}."
# The -g flag ensures the primary group is updated with the new PGID
# The -m and -d flags ensure the home directory and path are correctly handled
if sudo usermod -u ${NEW_PUID} -g ${USER_NAME} -m -d /home/${USER_NAME} ${USER_NAME}; then
    log INFO "User ID (PUID) successfully changed to ${NEW_PUID}."
else
    log ERROR "Failed to change PUID for user ${USER_NAME} to ${NEW_PUID}."
    # Optionally exit or continue with a warning
fi

# 3. Fix File Ownership
# This is a crucial step to ensure the user owns all their files again.
# We're using the user's new PUID to find their files.
log INFO "Starting file ownership update. This may take a moment."
display $YELLOW "Updating file ownership. Please wait..."

# Check the old PUID before it was changed for maximum compatibility/safety
# For simplicity, we can rely on the fact that 'usermod' updates the user in the system
# We check based on the new user name, which has the new PUID.
if sudo find / -uid $(id -u ${USER_NAME}) -print0 | sudo xargs -0 chown ${USER_NAME}:${USER_NAME}; then
    log INFO "File ownership update complete."
else
    log ERROR "File ownership update FAILED. Manual review of file permissions is required."
fi

display $GREEN "PUID/PGID and file ownership update section finished."
sleep 2s

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Cleanup
log INFO "Performing final cleanup"
sudo nala autoremove -y
sudo nala clean

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Script completion
script_completed="true"
log INFO "Installation script completed successfully"
display $BLUE "Finishing up now. Shop smart, shop S-Mart."

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

display $RED "Don't mix danger, handle with care!"
sleep 5s

figlet Workshed | lolcat -a -d 3

log INFO "Installation summary saved to $update_summary"

display $GREEN "Installation summary saved to $update_summary"

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat
