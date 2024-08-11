#!/bin/bash

# Define the log file path
log_file="/home/$USER/install_log.txt"

# Function to log and display messages
log_and_display() {
  echo -e "$1" | tee -a "$log_file"
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
  "lolcat"
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

# Cleanup function
cleanup() {
    log_and_display "\e[1;34m Cleaning up... \e[0m"
    
    # Remove any temporary files
    rm -f /tmp/install_script_*

    # Revert .bashrc if the script didn't complete successfully
    if [ -f ~/.bashrc.bak ] && [ "$script_completed" != "true" ]; then
        mv ~/.bashrc.bak ~/.bashrc
        log_and_display "\e[1;34m Reverted .bashrc to original state. \e[0m"
    fi

    # Add any other cleanup tasks here
    
    log_and_display "\e[1;34m Cleanup completed. \e[0m"
}

# Trap for cleanup
trap cleanup EXIT

# Variable to track script completion
script_completed="false"

# Introduction and instruction
log_and_display "\e[1;34m This script should run unattended to automate setting up a clean OS install.\e[0m"
sleep 2s
log_and_display "\e[1;34m Don't Mix Danger, Handle with Care! \e[0m"
sleep 3s

# Function to cache sudo credentials and keep them alive
#
# This function runs the 'sudo -v' command to validate the user's sudo credentials.
# It then starts an infinite loop that periodically checks if the sudo process is still running.
# If the process is still running, it sleeps for 60 seconds. If the process is not running,
# the loop exits. The output of the loop is redirected to '/dev/null' to suppress any output.
# The function is run in the background using the '&' operator.
cache_sudo() {
    sudo -v
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null ) &
}

# Update apt and install any needed upgrades first
log_and_display "\e[1;34m Preparing system before installing new applications. This will install any available upgrades.  \e[0m" 
sleep 1s

sudo apt update
sudo apt upgrade -y


# Install Nala so we can use it instead of apt for the rest of the script
log_and_display "\e[1;34m Adding curl and installing Nala. Because it is better than apt. \e[0m"
sleep 2s
sudo apt install curl -y
curl https://gitlab.com/volian/volian-archive/-/raw/main/install-nala.sh | bash
sudo nala update

# Remove old version of LibeOffice until OSes start shipping newer versions.
log_and_display "\e[1;34m Removing the old packaged version of Libre Office. The script will install from flatpak later in the script. The flatpak version is more up to date. \e[0m"
sleep 3s
sudo nala remove --purge -y "libreoffice*"
sudo nala clean -y
sudo nala autoremove -y

# Check if Desktop Environment is Gnome and installing utilities to make Gnome usable.
log_and_display "\e[1;34m Installing Gnome utilities, if needed. \e[0m"
sleep 2s
if [[ $(echo "$DESKTOP_SESSION") =~ [Gg][Nn][Oo][Mm][Ee] ]]; then
  sudo nala install gnome-tweaks gnome-sushi imagemagick nautilus-image-converter nautilus-admin ffmpegthumbnailer -y
fi

# Check to see if the OS is Pop OS so we can use Pop OS app store. And uninstall the Pop Shop.
log_and_display "\e[1;34m Checking OS to see if Pop OS specific steps are needed. \e[0m"
sleep 2s
os_name=$(lsb_release -si)
if [[ "$os_name" == "Pop" || "$os_name" == "Pop!_OS" ]]; then
    log_and_display "\e[1;34m Running on Pop!_OS. Proceeding with installation and uninstallation. \e[0m"
    # Install cosmic-icons and cosmic-store
    sudo nala install cosmic-icons cosmic-store -y
    # Uninstall the Pop Shop
    sudo nala remove pop-shop -y
    sudo nala purge pop-shop -y
fi

# Add repo and install MakeMKV that actually works.
log_and_display "\e[1;34m Installing MakeMKV from the heyarje repo. This one works better than the flathub one. \e[0m" 
sleep 2s
sudo add-apt-repository -y ppa:heyarje/makemkv-beta
sudo nala update
sudo nala install makemkv-bin makemkv-oss -y

# Add repo and install FastFetch
log_and_display "\e[1;34m Installing Fastfetch from the zhangsongcui repo. Make sure to confirm actions. This step is needed until fastfest is available as a system or flatpak install. \e[0m" 
sleep 2s
sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
sudo nala update
sudo nala install fastfetch -y

# Preconfigure the Microsoft fonts EULA acceptance
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections

# Preconfigure libdvd-pkg settings
export DEBIAN_FRONTEND=noninteractive
sudo DEBIAN_FRONTEND=noninteractive apt -yq install libdvd-pkg
sudo bash /usr/lib/libdvd-pkg/b-i_libdvdcss.sh


# Function to check if a .deb package is installed
is_deb_installed() {
  dpkg -l | grep -qw "$1"
}

# Function to check if a Flatpak application is installed
is_flatpak_installed() {
  flatpak list | grep -qw "$1"
}

log_and_display "\e[1;34m Installing deb packages now. \e[0m" 
sleep 2s

# Update package list for .deb packages
log_and_display "\e[1;34m Updating package list...\e[0m"
sudo nala update

# Install each .deb package if not already installed
for package in "${deb_packages[@]}"; do
  if dpkg -l | grep -qw "$package"; then
    log_and_display "\e[1;34m $package is already installed, skipping. \e[0m"
  else
    log_and_display "\e[1;34m Installing $package...\e[0m"
    if sudo nala install -y "$package"; then
      installed_deb_packages+=("$package")
    else
      log_and_display "\e[1;34m Failed to install $package. \e[0m"
    fi
  fi
done

log_and_display "\e[1;34m Installing flatpak applications now. \e[0m" 
sleep 2s

# Install Flatpak if not already installed
if ! command -v flatpak &> /dev/null; then
  log_and_display "\e[1;34m Flatpak is not installed, installing Flatpak... \e[0m"
  sudo nala install -y flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Iterate through the list of Flatpak applications
for app in "${flatpak_apps[@]}"; do
  if flatpak list | grep -qw "$app"; then
    log_and_display "\e[1;34m $app is already installed, skipping. \e[0m"
  else
    log_and_display "\e[1;34m Installing $app... \e[0m"
    if flatpak install -y --noninteractive flathub "$app" >> "$log_file" 2>&1; then
      installed_flatpak_apps+=("$app")
      log_and_display "\e[1;34m $app installed successfully. \e[0m"
    else
      log_and_display "\e[1;34m Failed to install $app. Check for errors. \e[0m"
    fi
  fi
done

# Generate installed applications report
if [ ${#installed_deb_packages[@]} -eq 0 ] && [ ${#installed_flatpak_apps[@]} -eq 0 ]; then
  log_and_display "\e[1;34m No new programs were installed. \e[0m"
else
  log_and_display "\e[1;34m The following .deb packages were installed: \e[0m"
  for package in "${installed_deb_packages[@]}"; do
    echo "- $package" | tee -a "$log_file"
  done
  log_and_display "\e[1;34m The following Flatpak applications were installed: \e[0m"
  for app in "${installed_flatpak_apps[@]}"; do
    echo "- $app" | tee -a "$log_file"
  done
fi

# Create update script
log_and_display "\e[1;34m Creating and downloading the update.sh script. This will make updates easier. \e[0m"
sleep 2s
sudo curl -sL https://raw.githubusercontent.com/mdleslie/workshed/workshed/update.sh -o /usr/bin/update.sh
if [[ $? -ne 0 ]]; then
  log_and_display "\e[1;34m Failed to download update.sh script. \e[0m"
  exit 1
fi
sudo chmod +x /usr/bin/update.sh

# Modify .bashrc file
log_and_display "\e[1;34m Modifying .bashrc file to include useful aliases. \e[0m" 
sleep 3s

# Make a backup of the original .bashrc file
sudo cp ~/.bashrc ~/.bashrc.bak

# Download and append the new aliases to the .bashrc file
log_and_display "\e[1;34m Downloading and appending aliases to .bashrc file... \e[0m"
sleep 2s
curl -sL "https://github.com/mdleslie/workshed/raw/workshed/bash.rc%20aliases" | tee -a ~/.bashrc
if [[ $? -ne 0 ]]; then
  log_and_display "\e[1;34m Failed to download bash.rc aliases. \e[0m"
  exit 1
fi

# Adding a Band Maid logo for fastfetch
log_and_display "\e[1;34m Adding new logo for fastfetch. An impossibly hard rocking maid logo. \e[0m"
sleep 3s

# Create the logos directory if it doesn't already exist
mkdir -p ~/.local/share/fastfetch/logos

# Download the maid file directly into the logos directory
curl -sL "https://github.com/mdleslie/workshed/raw/workshed/maid" -o ~/.local/share/fastfetch/logos/maid

# Check if the download was successful
if [[ $? -ne 0 ]]; then
  log_and_display "\e[1;34m Failed to download maid logo. \e[0m"
  exit 1
fi

# Needed for cleanup functions:
script_completed="true"


log_and_display "\e[1;34m Finishing up now. Shop smart, shop S-Mart. \e[0m"
sleep 3s

sudo nala autoremove -y
sudo nala clean -y


figlet Workshed | lolcat -a -d 3
