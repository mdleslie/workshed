#!/bin/bash

# Pop OS/Ubuntu Setup Script - added fastfetch repo back in.
# well, trying to, anyway
# Author: workshed
# Description: Automated setup script for fresh Pop OS/Ubuntu installations

##############################
# Configuration Variables

# Determine the target user (the user who executed the script/sudo)
TARGET_USER="${SUDO_USER:-$USER}"

# Define log file paths based on the target user
log_file="/home/$TARGET_USER/install_log.txt"
update_summary="/home/$TARGET_USER/install_summary.txt"

# PUID/PGID Variables for NFS/Docker compatibility
TARGET_PUID="1026"  # Change this to match user id on NFS mounted NAS. Use id command to check.
TARGET_PGID="1000"  # Keeping this for reference, only changing PUID for now.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

##################################
# Core Functions 

# Function to log messages (uses tee and logger for system logs)
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$log_file"
    logger -p user.$level "$message"
}

# Function to display colorful messages in the terminal and log
display() {
    local color=$1
    local message=$2
    echo -e "${color}$message${NC}" | tee -a "$log_file"
    echo -e "${color}$message${NC}" | lolcat
}

# Function to check if the output is a terminal for lolcat
lol() {
  if [ -t 1 ]; then
    "$@" | lolcat
  else
    "$@"
  fi
}

# Function to cache sudo credentials
cache_sudo() {
    sudo -v
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null ) &
}

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

###############################################
# Error Handling & Traps

# Error handling: exit immediately if a command exits with a non-zero status
set -e
trap 'log ERROR "An error occurred. Exit code: $?"' ERR

# Trap for cleanup: runs cleanup on exit (successful or not)
trap cleanup EXIT

# Variable to track script completion
script_completed="false"

# Bind the function to the RETURN key (Optional)
bind 'RETURN: "\e[1~lol \e[4~\n"'

#################################################
# Package Arrays

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
  "rar"
  "unrar"
  "p7zip-full"
  "p7zip-rar"
  "tree"
  "wget"
  "libsndfile1-dev"
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
  "com.google.Chrome"
  "io.github.flattool.Warehouse"
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
  "io.github.Faugus.faugus-launcher"
)

# Array to store the names of installed .deb packages and Flatpak applications
installed_deb_packages=()
installed_flatpak_apps=()

####################
### Script Start ###
####################

# Check and install lolcat
if ! command -v lolcat &> /dev/null; then
    log INFO "lolcat is not installed. Installing lolcat."
    sleep 5s
    sudo apt update && sudo apt install -y lolcat
fi

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

log INFO "Starting installation script"
display $GREEN "Lets go, it's showtime!"
sleep 7s
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
echo '########################################' | lolcat
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
echo '########################################' | lolcat

# Preconfigure Microsoft fonts and libdvd-pkg
log INFO "Preconfiguring Microsoft fonts and libdvd-pkg"
display $GREEN "Installing Microsoft fonts and libdvd."
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
sudo DEBIAN_FRONTEND=noninteractive apt -yq install libdvd-pkg
sudo bash /usr/lib/libdvd-pkg/b-i_libdvdcss.sh
unset DEBIAN_FRONTEND

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Install FastFetch
log INFO "Installing FastFetch"
display $GREEN "Installing Fastfetch from the zhangsongcui repo."
sleep 5s
sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
sudo nala update
sudo nala install fastfetch -y

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
        # Use command substitution to capture output for logging
        FLATPAK_OUTPUT=$(flatpak install -y --noninteractive flathub "$app" 2>&1)
        if [ $? -eq 0 ]; then
            log INFO "$app successfully installed. Details: $FLATPAK_OUTPUT"
            installed_flatpak_apps+=("$app")
        else
            log ERROR "Failed to install $app. Output: $FLATPAK_OUTPUT"
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

# Install Ratatouille LV2 Plugin
log INFO "Installing Ratatouille LV2 Plugin"
display $GREEN "Installing Ratatouille LV2 Plugin."
sleep 2s
git clone https://github.com/brummer10//Ratatouille.lv2.git
cd Ratatouille.lv2
git submodule update --init --recursive
make lv2
make install # Installs to ~/.lv2
# Optional: Uncomment the next line to install system-wide
# sudo make install # Installs to /usr/lib/lv2
cd ..
echo "--- Ratatouille Installation Complete ---"

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# --- START REAPER NATIVE INSTALL BLOCK ---

# Step 1: Install Native Linux Reaper
REAPER_VERSION="684" # Last known version for direct link as of current knowledge
REAPER_URL="https://www.reaper.fm/files/6.x/reaper${REAPER_VERSION}_linux_x86_64.tar.xz" 
INSTALL_DIR="/opt/REAPER"

log INFO "Downloading and installing native Reaper from official site."
display $GREEN "Installing native Reaper to $INSTALL_DIR"
sleep 2s

wget -q --show-progress "$REAPER_URL" -O /tmp/reaper.tar.xz 2>&1 | log INFO

if [ $? -ne 0 ]; then
    log ERROR "Failed to download Reaper from $REAPER_URL"
    exit 1
fi

mkdir -p /tmp/reaper_temp
tar -xf /tmp/reaper.tar.xz -C /tmp/reaper_temp --strip-components=1 2>&1 | log INFO

# Run the installer script:
# --install-dir: specifies where the main files go
# --install-symlink: creates a symlink in /usr/local/bin so you can run 'reaper' from the terminal
sudo /tmp/reaper_temp/install-reaper.sh --install-dir="$INSTALL_DIR" --install-symlink /usr/local/bin 2>&1 | log INFO

if [ -f "$INSTALL_DIR/reaper" ]; then
    log INFO "Reaper native installation successful."
else
    log ERROR "Reaper native installation failed. Check installer script output."
    exit 1
fi

rm -rf /tmp/reaper_temp /tmp/reaper.tar.xz
log INFO "Cleaned up temporary Reaper files."
echo "--- Native Reaper Installation Complete ---"

# --- END REAPER NATIVE INSTALL BLOCK ---

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# --- START YABRIDGE INSTALL BLOCK ---

# Dependencies needed for yabridge host to run Windows plugins
log INFO "Installing Wine dependencies (essential for yabridge)."
display $GREEN "Installing Wine Stable."
sudo nala install -y wine-stable

# Define yabridge installation variables
YABRIDGE_VERSION="5.0.4" # UPDATE this version number if newer versions are released
YABRIDGE_DIR="/opt/yabridge-$YABRIDGE_VERSION"
YABRIDGE_URL="https://github.com/robbert-vdh/yabridge/releases/download/$YABRIDGE_VERSION/yabridge-$YABRIDGE_VERSION.tar.gz"

log INFO "Downloading and unpacking yabridge version $YABRIDGE_VERSION"
display $GREEN "Setting up yabridge VST Bridge."

# 1. Download and unpack yabridge
sudo mkdir -p "$YABRIDGE_DIR"
wget -q --show-progress -O /tmp/yabridge.tar.gz "$YABRIDGE_URL" 2>&1 | log INFO
sudo tar -xf /tmp/yabridge.tar.gz -C /opt/ 2>&1 | log INFO
sudo rm /tmp/yabridge.tar.gz
log INFO "Yabridge binaries unpacked to /opt/."

# 2. Add yabridge to the system's PATH
log INFO "Creating symlinks for yabridge and yabridgectl in /usr/local/bin."
sudo ln -sf "$YABRIDGE_DIR/yabridge" /usr/local/bin/yabridge
sudo ln -sf "$YABRIDGE_DIR/yabridgectl" /usr/local/bin/yabridgectl

# 3. Create standard VST Directories (if they don't exist yet)
VST2_PATH="/home/$TARGET_USER/.vst"
VST3_PATH="/home/$TARGET_USER/.vst3"
mkdir -p "$VST2_PATH"
mkdir -p "$VST3_PATH"
log INFO "VST plugin directories created: $VST2_PATH and $VST3_PATH"

# 4. Set Windows VST plugin paths
# NOTE: Update these paths to where your actual Windows VST files are stored (e.g., on your NFS/NAS mounts).
# Example paths for a Wine prefix or shared drive:
WIN_VST_PATH="/mnt/Unraid/WindowsVST/VSTPlugins" 
WIN_VST3_PATH="/mnt/Unraid/WindowsVST/VST3"       
log INFO "Windows VST paths configured for yabridge: $WIN_VST_PATH and $WIN_VST3_PATH"

# 5. Execute yabridgectl to link and sync directories (runs as the target user)
log INFO "Executing yabridgectl sync as user $TARGET_USER."
display $BLUE "Linking and scanning VST directories with yabridge."

# We use runuser to ensure the command runs as the non-root user and accesses their home directory.
# First, remove any existing paths to avoid duplicates/errors
runuser -l $TARGET_USER -c 'yabridgectl clear' 2>&1 | log INFO

# Add new VST directories
runuser -l $TARGET_USER -c "yabridgectl add '$WIN_VST_PATH'" 2>&1 | log INFO
runuser -l $TARGET_USER -c "yabridgectl add '$WIN_VST3_PATH'" 2>&1 | log INFO

# Final synchronization step
runuser -l $TARGET_USER -c 'yabridgectl sync' 2>&1 | log INFO

log INFO "yabridge installation and sync completed."
echo "--- yabridge Installation Complete ---"

# --- END YABRIDGE INSTALL BLOCK ---

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

# Install yt-dlp
# TEST this section needs to be tested as part of the script.
log INFO "Installing yt dlp"
display $GREEN "Installing yt dlp."
python3 -m pip install -U "yt-dlp[default]"

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Changing PUID and PGID for NFS mounting of Arkive nas. Thanks Gemini.
# We are changing the UID only ($TARGET_PUID: 1026) to match the Synology NAS.

#########################################################
echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

log INFO "Starting PUID change via Systemd scheduling for user ${TARGET_USER}."
display $RED "WARNING: PUID changes must happen after a REBOOT."
display $GREEN "Scheduling PUID change for user ${TARGET_USER} to ${TARGET_PUID}."
sleep 2s

# Filenames
SYSTEMD_SERVICE="workshed-puid-fix.service"
SYSTEMD_TARGET="/etc/systemd/system/${SYSTEMD_SERVICE}"
CHOWN_SCRIPT_PATH="/opt/workshed-chown-fix.sh"

# 1. Write the one-time Chown script
# This script is executed by the Systemd service (run as root).
sudo tee ${CHOWN_SCRIPT_PATH} > /dev/null << EOF_CHOWN_SCRIPT
#!/bin/bash
# ----------------------------------------------------
# PUID/PGID Fix Script - Executed Once by Systemd
# ----------------------------------------------------

# 1. Perform the final PUID change (if not yet applied)
/usr/sbin/usermod -u ${TARGET_PUID} ${TARGET_USER} || true
/usr/bin/echo "[\$(date +'%Y-%m-%d %H:%M:%S')] PUID applied/confirmed for ${TARGET_USER}." | /usr/bin/logger

# 2. Fix file ownership (CRITICAL STEP)
# This finds files owned by the old UID and assigns them to the new user.
/usr/bin/find / -uid \$(/usr/bin/id -u ${TARGET_USER}) -print0 2>/dev/null | /usr/bin/xargs -0 /usr/bin/chown ${TARGET_USER}:${TARGET_USER} 2>/dev/null

/usr/bin/echo "[\$(date +'%Y-%m-%d %H:%M:%S')] File ownership fix completed." | /usr/bin/logger

# 3. Flatpak Repair (CRITICAL FOR YOUR ISSUE)
# Fixes permissions and internal database entries for all user Flatpak installs.
# We use runuser to execute the command as the target user.
/usr/bin/runuser -l ${TARGET_USER} -c '/usr/bin/flatpak repair --user'
/usr/bin/echo "[\$(date +'%Y-%m-%d %H:%M:%S')] Flatpak repair completed for ${TARGET_USER}." | /usr/bin/logger

# 4. Disable and delete the service for one-time execution cleanup
/usr/bin/systemctl disable ${SYSTEMD_SERVICE}
/usr/bin/rm -f ${SYSTEMD_TARGET}
/usr/bin/rm -f ${CHOWN_SCRIPT_PATH}
/usr/bin/echo "[\$(date +'%Y-%m-%d %H:%M:%S')] Systemd PUID fix service self-deleted." | /usr/bin/logger

exit 0
EOF_CHOWN_SCRIPT

sudo chmod +x ${CHOWN_SCRIPT_PATH}
log INFO "One-time chown script created at ${CHOWN_SCRIPT_PATH}."


# 2. Create the Systemd One-Shot Service
sudo tee ${SYSTEMD_TARGET} > /dev/null << EOF_SYSTEMD
[Unit]
Description=Workshed PUID Change and File Ownership Fix
After=network-online.target multi-user.target
RequiresMountsFor=/home

[Service]
Type=oneshot
ExecStart=${CHOWN_SCRIPT_PATH}
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF_SYSTEMD

# 3. Enable and start the service (it will run on the next boot)
sudo systemctl daemon-reload
sudo systemctl enable ${SYSTEMD_SERVICE}
log INFO "Systemd service ${SYSTEMD_SERVICE} enabled and ready to run on reboot."

display $GREEN "PUID change scheduled via Systemd."
display $RED "CRITICAL: A REBOOT IS REQUIRED to apply PUID changes."
sleep 5s

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

##########################################################
# END OF CRITICAL PUID SCHEDULING BLOCK

# Cleanup
display $GREEN "Starting Cleanup."
sleep 2s

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat

# Final Cleanup and Shutdown Sequence
log INFO "Starting Final Cleanup and Shutdown Sequence."
display $GREEN "Starting Final Cleanup and Shutdown Sequence."
sleep 2s

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

# Temporarily disable 'set -e' to ensure the final shutdown commands run
set +e

display $GREEN "Computer will reboot for the PUID changes to take full effect, po."
sleep 10s

log INFO "Installation summary saved to $update_summary"

display $GREEN "Script complete. Installation summary saved to $update_summary"
sleep 5s

figlet Workshed | lolcat -a -d 3

# Force an exit before the reboot command to ensure the shell doesn't hang
# and then execute the reboot as a separate, guaranteed command.
sudo reboot & exit 0