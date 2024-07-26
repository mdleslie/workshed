#!/bin/bash

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
  "chromium-codecs-ffmpeg-extra"
  "libdvd-pkg"
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
  "curl"
  "git"
  "wget"
  "python3"
)

# List of Flatpak applications to install
flatpak_apps=(
  "com.spotify.Client"
  "org.libreoffice.LibreOffice"
  "net.cozic.joplin_desktop"
  "com.synology.SynologyDrive"
  "com.brave.Browser"
  "one.ablaze.floorp"
  "org.kde.kdenlive"
  "fr.handbrake.ghb"
  "com.obsproject.Studio"
  "io.missioncenter.MissionCenter"
  "flathub org.telegram.desktop"
  "com.bitwarden.desktop"
  "com.skype.Client"
  "io.github.aandrew_me.ytdn"
  "org.localsend.localsend_app"
  "io.github.shiftey.Desktop"
  "com.github.tchx84.Flatseal"
  "org.gnome.Evolution"
  "io.github.flattool.Warehouse"
  "io.github.celluloid_player.Celluloid"
)

# Array to store the names of installed .deb packages and Flatpak applications
installed_deb_packages=()
installed_flatpak_apps=()


echo -e "\e[1;34m Updated July 25 2024. Make sure to click ok or yes at various points in install process. Don't Mix Danger, Handle with Care! \e[0m"
sleep 5s

echo -e "\e[1;34m Preparing system before installing the apps from the array lists script. \e[0m" 

sudo apt update
sudo apt upgrade -y

echo -e "\e[1;34m Removing the old packaged version of Libre Office. We will install a newer version later in this script. \e[0m"
sleep 2s

sudo apt-get remove --purge "libreoffice*"
sudo apt-get clean
sudo apt-get autoremove

echo -e "\e[1;34m Installing Nala \e[0m"

sudo apt install nala

echo -e "\e[1;34m Installing MakeMKV from the heyarje repo. This one works better than the flathub one. \e[0m" 
sleep 2s

sudo add-apt-repository ppa:heyarje/makemkv-beta
sudo apt update
sudo nala install makemkv-bin makemkv-oss -y

echo -e "\e[1;34m Installing Fastfetch from the zhangsongcui repo. Make sure to confirm actions. This step is needed until fastfest is available as a system or flatpak install. \e[0m" 
sleep 2s

sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt update
sudo apt install fastfetch

# May need to move this to end of script. Will test.

echo -e "\e[1;34m Configuring libdvd-pkg. \e[0m" 
sleep 2s

sudo dpkg-reconfigure libdvd-pkg

# Begin installing from array now.

# Function to check if a .deb package is installed
is_deb_installed() {
  dpkg -l | grep -qw "$1"
}

# Function to check if a Flatpak application is installed
is_flatpak_installed() {
  flatpak list | grep -qw "$1"
}

# Update package list for .deb packages
echo-e "\e[1;34m Updating package list...\e[0m"
sudo nala update

# Install each .deb package if not already installed
for package in "${deb_packages[@]}"; do
  if is_deb_installed "$package"; then
    echo-e "\e[1;34m $package is already installed, skipping. \e[0m"
  else
    echo-e "\e[1;34m Installing $package...\e[0m"
    sudo nala install -y "$package"
    if [ $? -eq 0 ]; then
      installed_deb_packages+=("$package")
    else
      echo-e "\e[1;34m Failed to install $package. "
    fi
  fi
done

# Install Flatpak if not already installed
if ! command -v flatpak &> /dev/null; then
  echo-e "\e[1;34m Flatpak is not installed, installing Flatpak... \e[0m"
  sudo nala install -y flatpak
fi

# Install each Flatpak application if not already installed
for app in "${flatpak_apps[@]}"; do
  if is_flatpak_installed "$app"; then
    echo-e "\e[1;34m $app is already installed, skipping. \e[0m"
  else
    echo-e "\e[1;34m Installing $app... \e[0m"
    flatpak install -y flathub "$app"
    if [ $? -eq 0 ]; then
      installed_flatpak_apps+=("$app")
    else
      echo-e "\e[1;34m Failed to install $app. \e[0m"
    fi
  fi
done

# Generate report
if [ ${#installed_deb_packages[@]} -eq 0 ] && [ ${#installed_flatpak_apps[@]} -eq 0 ]; then
  echo-e "\e[1;34m No new programs were installed. \e[0m"
else
  echo-e "\e[1;34m The following .deb packages were installed: \e[0m"
  for package in "${installed_deb_packages[@]}"; do
    echo "- $package"
  done
  echo-e "\e[1;34m The following Flatpak applications were installed: \e[0m"
  for app in "${installed_flatpak_apps[@]}"; do
    echo "- $app"
  done
fi

echo -e "\e[1;34m +++++++++++++++++++++++++++++++++++++++++++++++ \e[0m"

echo -e "\e[1;34m +++++++++++++++++++++++++++++++++++++++++++++++ \e[0m"

echo -e "\e[1;34m Finished scripted installations. Shop Smart, shop S-Mart. \e[0m"

echo -e "\e[1;34m +++++++++++++++++++++++++++++++++++++++++++++++ \e[0m"

echo -e "\e[1;34m +++++++++++++++++++++++++++++++++++++++++++++++ \e[0m"
