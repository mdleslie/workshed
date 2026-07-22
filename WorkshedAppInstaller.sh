#!/bin/bash
# Pop!_OS / Ubuntu Fresh Install Setup Script – 2026 Edition
# Author: workshed (@mdleslie) 
# Version: 1.0.9 Nemophila edition with Snaps support added.
# Updated: 2026-07-21
# co-authored by Gemini

set -eEuo pipefail
IFS=$'\n\t'

##############################
# Configuration & Variables
##############################

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]] && { echo "ERROR: Cannot find home for $TARGET_USER"; exit 1; }

log_file="$TARGET_HOME/install_log.txt"
update_summary="$TARGET_HOME/install_summary.txt"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
installed_deb_packages=()
installed_flatpak_apps=()
installed_snap_packages=()

##############################
# EDIT THESE THREE ARRAYS 
##############################

deb_packages=(
    fortune-mod
    cowsay
    ubuntu-restricted-extras
    fuse3
    build-essential
    pkg-config
    mesa-utils
    ffmpeg
    mpv
    mediainfo
    vlc
    fastfetch
    libssl-dev
    libexpat1-dev
    libgl1-mesa-dev
    libgstreamer1.0-dev
    libgstreamer-plugins-base1.0-dev
    gstreamer1.0-plugins-bad
    gstreamer1.0-plugins-ugly
    gstreamer1.0-plugins-good
    gstreamer1.0-libav
    libavcodec-extra
    nfs-common
    cifs-utils
    gamemode
    steam
    cpu-x
    python3
    figlet
    fonts-inter
    ncdu
    pydf
    ffmpegthumbnailer
    bind9-dnsutils
    inetutils-traceroute
    whois
    nmap
    btop
    cmake
    libcairo2-dev
    libx11-dev
    lv2-dev
    nasm
    rar
    unrar
    p7zip-full
    p7zip-rar
    tree
    wget
    libsndfile1-dev
    libxcursor-dev
    libxext-dev
    libxrandr-dev
    net-tools
    ethtool
    boxes
    yubikey-manager
    fido2-tools
    smartmontools
    org.gnome.DejaDup
    tldr
    bacula-console-qt
    exiftool
    nodejs
    mediainfo
    mediainfo-gui
)

flatpak_apps=(
    com.synology.SynologyDrive
    com.brave.Browser
    org.kde.kdenlive
    fr.handbrake.ghb
    com.obsproject.Studio
    org.telegram.desktop
    com.bitwarden.desktop
    io.github.aandrew_me.ytdn
    org.localsend.localsend_app
    io.github.shiftey.Desktop
    com.github.tchx84.Flatseal
    net.davidotek.pupgui2
    com.vscodium.codium
    org.darktable.Darktable
    com.google.Chrome
    io.github.flattool.Warehouse
    com.discordapp.Discord
    org.inkscape.Inkscape
    com.github.unrud.VideoDownloader
    app.zen_browser.zen
    it.mijorus.gearlever
    eu.betterbird.Betterbird
    tv.plex.PlexDesktop
    io.github.cosmic_utils.camera
    com.yubico.yubioath
    dev.edfloreshz.CosmicTweaks
    org.upscayl.Upscayl
    net.lutris.Lutris
    
)

snap_packages=(
    lunatask
    spotify
    ticker
)

##############################
# Core Functions 
##############################

log() { local lvl="$1" msg="$2"; printf "[%s] [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$lvl" "$msg" | tee -a "$log_file"; logger -p user."$lvl" "$msg"; }
display() { echo -e "${1}${2}${NC}" | tee -a "$log_file"; command -v lolcat >/dev/null 2>&1 && [[ -t 1 ]] && echo -e "$2" | lolcat || echo -e "$2"; }
cache_sudo() { sudo -v; (while :; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) & }

cleanup() {
    log INFO "Running cleanup..."
    if [[ "$script_completed" != "true" ]] && [[ -f "$TARGET_HOME/.bashrc.bak" ]]; then
        mv "$TARGET_HOME/.bashrc.bak" "$TARGET_HOME/.bashrc"
        log WARNING ".bashrc reverted"
    fi
}

# lolcat
if ! command -v lolcat &>/dev/null; then
    log INFO "Installing lolcat – aesthetics matter, po!"
    sudo apt update && sudo apt install -y lolcat
fi

display $GREEN "Lets go, it's showtime!"
echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat
sleep 4s

cache_sudo

# Add Fastfetch PPA immediately
log INFO "Adding Fastfetch PPA"
display $GREEN "Adding Fastfetch PPA..."
sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
##############################

# System update + Nala
log INFO "Updating system + installing Nala"
display $GREEN "Updating and upgrading..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y nala

display $BLUE "Breaking new gate."
echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat
sleep 4s

##############################
# Microsoft Fonts + DVD support
##############################
log INFO "Preconfiguring Microsoft fonts and libdvd-pkg"
display $GREEN "Installing Microsoft fonts and libdvd – safe mode, po!"

# 1. PURGE
sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y libdvd-pkg ttf-mscorefonts-installer 2>/dev/null || true

# 2. PRE-SEED
sudo debconf-set-selections <<EOF
ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true
libdvd-pkg libdvd-pkg/build boolean true
libdvd-pkg libdvd-pkg/post-invoke_hook-install boolean true
libdvd-pkg libdvd-pkg/first-install note
libdvd-pkg libdvd-pkg/upgrade note
EOF

# 3. INSTALL (Inline ENV assignment is bulletproof)
sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq ttf-mscorefonts-installer libdvd-pkg

# 4. BUILD & CONFIGURE (Using the native reconfigure tool)
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive libdvd-pkg

display $GREEN "Microsoft fonts + DVD playback installed perfectly – po!"
echo '########################################' | lolcat
sleep 3s
display $GREEN "Are you a fan of delicious flavor?"
sleep 2s

# Install deb packages
log INFO "Installing ${#deb_packages[@]} deb packages"
for package in "${deb_packages[@]}"; do
    if dpkg -l 2>/dev/null | grep -q "^ii  $package "; then
        log INFO "$package → already installed"
    else
        log INFO "Installing $package"
        sudo nala install -y "$package" && installed_deb_packages+=("$package")
    fi
done

# Flatpak setup
log INFO "Installing ${#flatpak_apps[@]} Flatpak apps (System-Wide)"
display $GREEN "Installing Flatpak applications..."

# 1. Ensure Flatpak is installed
if ! command -v flatpak &>/dev/null; then
    log INFO "Flatpak not installed, installing now..."
    sudo nala install -y flatpak
fi

# 2. Remove conflicting 'user' remote so the system one takes priority
flatpak remote-delete --user flathub 2>/dev/null || true

# 3. Add Remote (System-Wide)
# FIX: Added 'sudo' here to prevent the PolicyKit password popup window!
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# 4. Install Loop
for app in "${flatpak_apps[@]}"; do
    if flatpak list | grep -q "$app"; then
        log INFO "$app → already installed"
    else
        log INFO "Installing Flatpak → $app"
        # We use 'sudo' here to install system-wide without prompts
        if sudo flatpak install --system -y --noninteractive flathub "$app" >> "$log_file" 2>&1; then
             installed_flatpak_apps+=("$app")
             log INFO "$app installed successfully"
        else
             log ERROR "Failed to install $app"
             display $RED "Failed to install $app"
        fi
    fi
done

##############################
# Snap Setup 
##############################
log INFO "Installing Snapd and ${#snap_packages[@]} Snap packages"
display $GREEN "Setting up Snap environment..."

# 1. Install snapd service
if ! command -v snap &>/dev/null; then
    log INFO "snapd not found installed already. Installing snapd..."
    sudo nala install -y snapd
fi

# 2. Start and enable the service immediately
sudo systemctl enable --now snapd.socket

# 3. Install the core snap and snapd (Required for many apps to function)
log INFO "Installing Snapd..."
sudo snap install snapd

log INFO "Installing Snap Core..."
sudo snap install core

# 4. Install Snap Loop
for snap_app in "${snap_packages[@]}"; do
    if snap list | grep -q "$snap_app"; then
        log INFO "$snap_app → already installed"
    else
        log INFO "Installing Snap → $snap_app"
        if sudo snap install "$snap_app"; then
             installed_snap_packages+=("$snap_app") 
             log INFO "$snap_app installed successfully"
        else
             log ERROR "Failed to install $snap_app"
             display $RED "Failed to install $snap_app"
        fi
    fi
done

display $GREEN "I am losing my mind."
echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat
sleep 3s

# ---------------------------------------------------------
# CONFIGURE LOG ROTATION
# ---------------------------------------------------------

display $GREEN "Configuring log rotation for Arkive logs..."

# 1. DEFINE the variable (This was missing!)
LOG_DIR="$TARGET_HOME/logs"

# Ensure the log directory exists with correct permissions
mkdir -p "$LOG_DIR"
chown "$TARGET_USER:$TARGET_USER" "$LOG_DIR"

# Create the logrotate config file
# We use variables inside the config so it adapts to any user
cat << EOF | sudo tee /etc/logrotate.d/arkive_files > /dev/null
${log_file} {
    su $TARGET_USER $TARGET_USER
    daily
    rotate 4
    size 5M
    missingok
    notifempty
    compress
}
EOF

display $GREEN "Log rotation configured."

##############################
#  FINAL TOUCHES 
##############################

# Custom update script 
log INFO "Downloading your custom update.sh script"
display $GREEN "Creating and downloading the update.sh script."
sudo curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/update.sh \
    -o /usr/bin/update.sh
sudo chmod +x /usr/bin/update.sh
display $GREEN "update.sh installed → just run 'update' anytime!"
sleep 2s

# Custom file archiving 
log INFO "Downloading your custom arkive_files.sh script"
display $GREEN "Creating and downloading the arkive_files.sh script."
sudo curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/arkive_files.sh \
    -o /usr/bin/arkive_files.sh
sudo chmod +x /usr/bin/arkive_files.sh
display $GREEN "arkive_files.sh installed → just run 'store' anytime!"
sleep 2s

# Bash aliases 
log INFO "Adding Workshed bash aliases"
display $GREEN "Modifying .bashrc file to include useful aliases."
cp "$TARGET_HOME/.bashrc" "$TARGET_HOME/.bashrc.bak" 2>/dev/null || true

curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/bash.rc%20aliases \
    >> "$TARGET_HOME/.bashrc"

echo -e "\n# ── Workshed aliases loaded – po! ──" >> "$TARGET_HOME/.bashrc"
display $GREEN "Aliases added! Open a new terminal or run 'source ~/.bashrc'"
sleep 2s

# Mount folders for Unraid Server
log INFO "Adding folders to /mnt"
display $BLUE "Adding folders to /mnt."
sudo mkdir -p /mnt/data
sudo mkdir -p /mnt/repo

# NFS mounts for Arkive
log INFO "Adding NFS mounts to /etc/fstab"
display $BLUE "Modifying fstab file to include NFS mount to Arkive."
sudo mkdir -p /mnt/Arkive 
sudo cp /etc/fstab /etc/fstab.bak

curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/fstab \
    | sudo tee -a /etc/fstab > /dev/null

display $GREEN "NFS mounts added – they’ll appear after reboot"
sleep 2s

# Band Maid fastfetch logo 
log INFO "Downloading an impossibly hard rocking maid logo, po."
display $GREEN "Adding new logo for fastfetch. An impossibly hard rocking maid logo, po."
sleep 5s
mkdir -p "$TARGET_HOME/.local/share/fastfetch/logos"
curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/maid \
    -o "$TARGET_HOME/.local/share/fastfetch/logos/maid"

display $GREEN "Band Maid logo installed – po!"
sleep 3s

##############################
# Ticker Configuration (Snap Mode)
##############################
log INFO "Configuring Ticker watchlist for $TARGET_USER"
display $GREEN "Setting up Ticker watchlist... tracking the gains, po!"

# Ensure the full path exists and is owned by the user BEFORE download
TICKER_SNAP_DIR="$TARGET_HOME/snap/ticker/common"
mkdir -p "$TICKER_SNAP_DIR"
chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/snap"

# Download your config from GitHub
TICKER_CONFIG_URL="https://raw.githubusercontent.com/mdleslie/workshed/workshed/ticker.yaml"

if curl -fsSL "$TICKER_CONFIG_URL" -o "$TICKER_SNAP_DIR/ticker.yaml"; then
    log INFO "Ticker config downloaded to Snap directory"
    
    # Create a symlink so standard binaries can see it too
    ln -sf "$TICKER_SNAP_DIR/ticker.yaml" "$TARGET_HOME/.ticker.yaml"
    
    # Set ownership on the symlink specifically
    chown -h "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.ticker.yaml"

    # Connect the Snap home interface (Critical for config access)
    sudo snap connect ticker:home || true
    log INFO "Ticker Snap connected to home interface"
else
    log ERROR "Failed to download ticker.yaml from GitHub"
    display $RED "Could not grab the ticker config, po!"
fi

# yt-dlp (latest & greatest, via pipx)
log INFO "Installing/upgrading yt-dlp via pipx"
display $GREEN "Installing yt-dlp"

if ! command -v pipx &>/dev/null; then
    sudo nala install -y pipx
fi

# Make sure pipx is in PATH for this session
export PATH="$TARGET_HOME/.local/bin:$PATH"

pipx install yt-dlp >/dev/null 2>&1 || pipx upgrade yt-dlp >/dev/null 2>&1
display $GREEN "yt-dlp is now fully up to date → $(yt-dlp --version)"
sleep 2s

# Final report
printf "Installed deb packages: %s\n" "${#installed_deb_packages[@]}" >> "$update_summary"
printf '%s\n' "${installed_deb_packages[@]}" >> "$update_summary"
printf "Installed Flatpak apps: %s\n" "${#installed_flatpak_apps[@]}" >> "$update_summary"
printf '%s\n' "${installed_flatpak_apps[@]}" >> "$update_summary"
printf "Installed Snap packages: %s\n" "${#installed_snap_packages[@]}" >> "$update_summary"
printf '%s\n' "${installed_snap_packages[@]}" >> "$update_summary"

log INFO "Installation summary saved to $update_summary"

display $GREEN "Script complete. Installation summary saved to $update_summary"
sleep 5s

display $BLUE "Shop smart. Shop S-Mart."

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat
sleep 3s

script_completed="true"

exit
