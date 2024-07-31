#!/bin/bash

# Define the log file path
log_file="/home/$USER/install_log.txt"

# Function to log and display messages
log_and_display() {
  echo -e "$1" | tee -a "$log_file"
}

# List of .deb packages to install
deb_packages=(
  "gnome-sushi"
  "imagemagick"
  "nautilus-image-converter"
  "nautilus-admin"
  "ffmpegthumbnailer"
  "fortune-mod"
  "cowsay"
  "folder-color"
  "nautilus-dropbox"
  "cosmic-icons"
  "cosmic-store"
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
  "gnome-tweaks"
  "lutris"
  "steam"
  "cpu-x"
  "python3"
  "pip"
  "lolcat"
  "figlet"
  "fonts-inter"
  "mangohud"
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
  "org.gnome.Evolution"
  "net.davidotek.pupgui2"
  "com.visualstudio.code"
)

# Array to store the names of installed .deb packages and Flatpak applications
installed_deb_packages=()
installed_flatpak_apps=()

# Introduction
log_and_display "\e[1;34m This is meant to run unattended, but if I missed somethingyou may need intervene along the way. \e[0m"
sleep 2s

log_and_display "\e[1;34m Don't Mix Danger, Handle with Care! \e[0m"
sleep 2s

# Update
log_and_display "\e[1;34m Preparing system before installing applications. \e[0m" 
sleep 2s

sudo apt update
sudo apt upgrade -y

# Remove old version of LibeOffice
log_and_display "\e[1;34m Removing the old packaged version of Libre Office. The script will install from flatpak later in the script. The flatpak version is more up to date. \e[0m"
sleep 5s

sudo apt-get remove --purge -y "libreoffice*"
sudo apt-get clean -y
sudo apt-get autoremove -y

# Install Nala
log_and_display "\e[1;34m Installing Nala. Because it is better than apt. \e[0m"
sleep 2s
sudo apt install nala -y

# Add repo and install MakeMKV
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

# Generate report
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
log_and_display "\e[1;34m Modifying update.sh file... \e[0m"
sleep 2s
sudo curl -sL https://raw.githubusercontent.com/mdleslie/workshed/workshed/update.sh -o /usr/bin/update.sh
if [[ $? -ne 0 ]]; then
  log_and_display "\e[1;34m Failed to download update.sh script. \e[0m"
  exit 1
fi
sudo chmod +x /usr/bin/update.sh

# Modify .bashrc file
log_and_display "\e[1;34m Modifying .bashrc file... \e[0m" 
sleep 2s

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

# Adding new logo for fastfetch
log_and_display "\e[1;34m Adding new logo for fastfetch... \e[0m" 
sleep 2s
mkdir -p ~/.local/share/fastfetch/logos/maid
curl -sL "https://github.com/mdleslie/workshed/raw/workshed/maid" -o ~/.local/share/fastfetch/logos/maid
if [[ $? -ne 0 ]]; then
  log_and_display "\e[1;34m Failed to download maid logo. \e[0m"
  exit 1
fi

log_and_display "\e[1;34m Finishing up now. Shop smart, shop S-Mart. \e[0m"

figlet Workshed | lolcat -a -d 3
