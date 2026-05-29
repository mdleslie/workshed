#!/bin/bash
# Fedora Fresh Install Setup Script – 2026 Edition
# Author: workshed (@mdleslie) 
# Version: 2.0.5 FEDORA edition --Gnome DE
# Updated: 2026-05-28 
#co-authored by Gemini

set -eEuo pipefail
IFS=$'\n\t'

##############################
# Configuration & Variables
##############################

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]] && { echo "ERROR: Cannot find home for $TARGET_USER"; exit 1; }

TICKER_SNAP_DIR="$TARGET_HOME/snap/ticker/common"
LOG_DIR="$TARGET_HOME/logs"

log_file="$TARGET_HOME/install_log.txt"
update_summary="$TARGET_HOME/install_summary.txt"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
installed_dnf_packages=()
installed_flatpak_apps=()
installed_snap_packages=()
installed_dnf_packages=(${installed_dnf_packages[@]:-})

##############################
# Log Rotation
##############################

mkdir -p "$LOG_DIR"
chown "$TARGET_USER:$TARGET_USER" "$LOG_DIR"

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

##############################
# PACKAGE ARRAYS 
##############################

dnf_packages=(
    dnf-plugins-core
    fortune-mod
    cowsay
    fuse-libs
    fuse3
    fuse
    pkgconf-pkg-config
    mesa-utils
    ffmpeg
    mpv
    mediainfo
    vlc
    fastfetch
    openssl-devel
    expat-devel
    mesa-libGL-devel
    gstreamer1-devel
    gstreamer1-plugins-base-devel
    gstreamer1-plugins-bad-free-devel
    gstreamer1-plugins-bad-free
    gstreamer1-plugins-ugly-free
    gstreamer1-plugins-good
    gstreamer1-libav
    nfs-utils
    cifs-utils
    gamemode
    steam
    cpu-x
    python3
    python3-pip
    figlet
    google-inter-fonts
    mangohud
    ncdu
    ffmpegthumbnailer
    bind-utils
    traceroute
    whois
    nmap
    btop
    cmake
    cairo-devel
    libX11-devel
    lv2-devel
    nasm
    rar
    unrar
    p7zip
    p7zip-plugins
    tree
    wget
    libsndfile-devel
    libXcursor-devel
    libXext-devel
    libXrandr-devel
    net-tools
    ethtool
    boxes
    yubikey-manager
    libfido2
    curl
    file-roller
    duf
    google-noto-sans-fonts
    google-noto-serif-fonts
    liberation-fonts
    btrfs-assistant
    btrbk 
    snapper
    gnome-tweaks
    gnome-extensions-app
    dconf-editor
    gnome-themes-extra
    nautilus-python
    tldr
    bat
    mscore-fonts-all
)

flatpak_apps=(
    com.synology.SynologyDrive
    com.brave.Browser
    org.kde.kdenlive
    fr.handbrake.ghb
    com.obsproject.Studio
    io.missioncenter.MissionCenter
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
    com.github.taiko2k.tauonmb
    org.inkscape.Inkscape
    com.github.unrud.VideoDownloader
    app.zen_browser.zen
    it.mijorus.gearlever
    io.github.seadve.Kooha
    no.mifi.losslesscut
    eu.betterbird.Betterbird
    tv.plex.PlexDesktop
    com.yubico.yubioath
    com.mattjakeman.ExtensionManager
)

snap_packages=(
    upnote
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
    # Disable the trap to prevent loops if cleanup fails
    trap - ERR EXIT 
    log INFO "Running cleanup..."
}
trap 'log ERROR "Failed at line $LINENO"' ERR
trap cleanup EXIT

#Dracut config fix
echo 'omit_dracutmodules+=" anaconda "' | sudo tee /etc/dracut.conf.d/extramodules.conf

# Install lolcat (Fedora)
if ! command -v lolcat &>/dev/null; then
    log INFO "Installing lolcat..."
    sudo dnf install -y lolcat
fi

display $GREEN "Setting maximum parallel downloads to 10, po."
echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat
echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf

display $GREEN "Refreshing repos, po."
echo '########################################' | lolcat
sudo dnf upgrade --refresh

display $GREEN "Fedora migration starting... po!"
echo '########################################' | lolcat
sleep 2
cache_sudo

display $GREEN "Help flatpaks look native."
echo '########################################' | lolcat
sudo flatpak override --filesystem=~/.icons:ro --filesystem=~/.fonts:ro

display $GREEN "Installing Development Tools."
echo '########################################' | lolcat
sudo dnf install -y @development-tools

display $GREEN "Let's go, it's showtime! "
echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat
sleep 5
display $BLUE "Breaking new gate."
echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat
sleep 4s

##############################
# System Update & Repos
##############################
log INFO "Updating system and enabling RPM Fusion"
display $GREEN "Enabling RPM Fusion (Free/Non-Free) and updating..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf upgrade --refresh -y

log INFO "Swapping to full-featured curl"
sudo dnf install -y curl --allowerasing

##############################
# Multimedia & Codecs
##############################
log INFO "Performing targeted codec swap"
display $GREEN "Swapping to full codecs – po!"

# 1. Clean up any metadata confusion
sudo dnf clean all
sudo dnf makecache

# 2. Swap ffmpeg using explicit releasever to avoid Rawhide/F45 leaks
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing --releasever=$(rpm -E %fedora)

# 3. Install freeworld plugins, explicitly disabling rawhide repos if they exist
sudo dnf install -y \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly \
    libavcodec-freeworld \
    mesa-va-drivers-freeworld \
    mesa-vdpau-drivers-freeworld \
    --allowerasing --skip-unavailable --releasever=$(rpm -E %fedora)
    
##############################
# Install DNF packages
##############################
log INFO "Installing ${#dnf_packages[@]} DNF packages"
for package in "${dnf_packages[@]}"; do
    if rpm -q "$package" &>/dev/null; then
        log INFO "$package → already installed"
    else
        log INFO "Installing $package"
        sudo dnf install -y "$package" && installed_dnf_packages+=("$package")
    fi
done

##############################
# Flatpak setup
##############################
log INFO "Setting up Flatpak"
display $GREEN "Installing Flatpak applications..."
sudo dnf install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

for app in "${flatpak_apps[@]}"; do
    if flatpak list | grep -q "$app"; then
        log INFO "$app → already installed"
    else
        log INFO "Installing Flatpak → $app"
        if sudo flatpak install -y --noninteractive flathub "$app" >> "$log_file" 2>&1; then
             installed_flatpak_apps+=("$app")
        else
             log ERROR "Failed to install $app"
        fi
    fi
done

##############################
# Snap Setup 
##############################
log INFO "Installing Snapd and setting up symlinks"
display $GREEN "Enabling Snap environment..."
sudo dnf install -y snapd
sudo ln -s /var/lib/snapd/snap /snap || true
sudo systemctl enable --now snapd.socket

log INFO "The waiting is the hardest part..."
until sudo snap wait system seed.loaded; do
    sleep 2
    log INFO "Still waiting for snapd..."
done

sleep 15 

for snap_app in "${snap_packages[@]}"; do
    log INFO "Installing Snap → $snap_app"
    # Adding || true ensures the script doesn't stop if the store is down
    sudo snap install "$snap_app" || log ERROR "Store is down, skipping $snap_app" || true
done

##############################
#  FINAL TOUCHES 
##############################

# 1. Custom update script 
log INFO "Downloading Fedora update script"
sudo curl -fsSL "https://raw.githubusercontent.com/mdleslie/workshed/workshed/Fedora_update.sh" -o /usr/bin/update.sh
sudo chmod +x /usr/bin/update.sh
sudo ln -sf /usr/bin/update.sh /usr/bin/update

# 2. Custom file archiving
log INFO "Downloading custom arkive_files.sh script"
sudo curl -fsSL "https://raw.githubusercontent.com/mdleslie/workshed/workshed/arkive_files.sh" -o /usr/bin/arkive_files.sh
sudo chmod +x /usr/bin/arkive_files.sh
sudo ln -sf /usr/bin/arkive_files.sh /usr/bin/store

# 3. Custom verification script
log INFO "Downloading custom verify.sh script"
sudo curl -fsSL "https://raw.githubusercontent.com/mdleslie/workshed/workshed/verify.sh" -o /usr/bin/verify.sh
sudo chmod +x /usr/bin/verify.sh
sudo ln -sf /usr/bin/verify.sh /usr/bin/verify

# 4. Bash aliases (Fedora/Ultramarine optimized)
log INFO "Adding Workshed bash aliases"

# Create the directory if it doesn't exist
mkdir -p "${TARGET_HOME}/.bashrc.d"

# Download the config into its own separate file
curl -fsSL "https://raw.githubusercontent.com/mdleslie/workshed/workshed/Fedora_bashrc" -o "${TARGET_HOME}/.bashrc.d/workshed.rc"

# Add your signature footer to that specific file
echo -e "\n# ── Workshed aliases loaded – po! ──" >> "${TARGET_HOME}/.bashrc.d/workshed.rc"

# Set correct ownership
chown "$TARGET_USER:$TARGET_USER" "${TARGET_HOME}/.bashrc.d/workshed.rc"

# 5. NFS mounts for Arkive
log INFO "Adding NFS mounts to /etc/fstab"
sudo mkdir -p /mnt/Arkive 
sudo cp /etc/fstab /etc/fstab.bak
curl -fsSL "https://raw.githubusercontent.com/mdleslie/workshed/workshed/fstab" | sudo tee -a /etc/fstab > /dev/null

# 6. Band Maid logo 
log INFO "Downloading logo, po."
mkdir -p "${TARGET_HOME}/.local/share/fastfetch/logos"
curl -fsSL "https://raw.githubusercontent.com/mdleslie/workshed/workshed/maid" -o "${TARGET_HOME}/.local/share/fastfetch/logos/maid"

# 7. Ticker Configuration
log INFO "Configuring Ticker"
mkdir -p "$TICKER_SNAP_DIR"
curl -fsSL "https://raw.githubusercontent.com/mdleslie/workshed/workshed/ticker.yaml" -o "$TICKER_SNAP_DIR/ticker.yaml"
ln -sf "$TICKER_SNAP_DIR/ticker.yaml" "$TARGET_HOME/.ticker.yaml"
sudo snap connect ticker:home || true

sync
sleep 5s

# Check for firmware updates
log INFO "Checking for Firmware Updates."
fwupdmgr refresh && fwupdmgr get-updates

fwupdmgr update

# Pipx + yt-dlp
log INFO "Installing Pipx and yt-dlp"
sudo dnf install -y pipx
sudo -u "$TARGET_USER" pipx ensurepath
sudo -u "$TARGET_USER" pipx install yt-dlp || true
export PATH="$TARGET_HOME/.local/bin:$PATH"

# Bun JS
log INFO "Installing Bun"
sudo -u "$TARGET_USER" bash -c "curl -fsSL https://bun.com/install | bash"

###
###
display $BLUE "Shop smart. Shop S-Mart."
echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat
sleep 3s

read -p "Press [Enter] to exit..."
exit
###
###

