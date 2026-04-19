#!/bin/bash
# Fedora Fresh Install Setup Script – 2026 Edition
# Author: workshed (@mdleslie) 
# Version: 2.0.0 FEDORA edition
# Updated: 2026-02-21

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

NEW_UID="1026"
NEW_GID="1000"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
installed_dnf_packages=()
installed_flatpak_apps=()
installed_snap_packages=()

##############################
# PACKAGE ARRAYS 
##############################

dnf_packages=(
    fortune-mod
    cowsay
    fuse3
    @development-tools
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
    inter-fonts
    mangohud
    ncdu
    pydf
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
    gnome-sushi
    nautilus-python
    file-roller
    gnome-tweaks
    gnome-extensions-app
    dconf-editor
    gnome-themes-extra
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
    io.github.Faugus.faugus-launcher
    io.github.seadve.Kooha
    no.mifi.losslesscut
    eu.betterbird.Betterbird
    tv.plex.PlexDesktop
    io.github.cosmic_utils.camera
    com.yubico.yubioath
)

snap_packages=(
    upnote
    lunatask
    spotify
)

##############################
# Core Functions 
##############################

log() { local lvl="$1" msg="$2"; printf "[%s] [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$lvl" "$msg" | tee -a "$log_file"; logger -p user."$lvl" "$msg"; }
display() { echo -e "${1}${2}${NC}" | tee -a "$log_file"; command -v lolcat >/dev/null 2>&1 && [[ -t 1 ]] && echo -e "$2" | lolcat || echo -e "$2"; }
cache_sudo() { sudo -v; (while :; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) & }

cleanup() {
    log INFO "Running cleanup..."
}
trap 'log ERROR "Failed at line $LINENO"' ERR
trap cleanup EXIT
script_completed="false"

# Install lolcat (Fedora)
if ! command -v lolcat &>/dev/null; then
    log INFO "Installing lolcat..."
    sudo dnf install -y lolcat
fi

display $GREEN "Fedora migration starting... po!"
echo '########################################' | lolcat
sleep 2
cache_sudo

##############################
# System Update & Repos
##############################
log INFO "Updating system and enabling RPM Fusion"
display $GREEN "Enabling RPM Fusion (Free/Non-Free) and updating..."
# RPM Fusion is essential for ffmpeg, vlc, steam etc on Fedora
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf upgrade --refresh -y

##############################
# Multimedia & Codecs
##############################
log INFO "Installing Multimedia Group and Codecs"
display $GREEN "Installing codecs – po!"

# Use --allowerasing to swap out the "crippled" system drivers for full versions
sudo dnf groupinstall -y "Multimedia" "Sound and Video" --allowerasing

# Explicitly pull the specific plugins and allow swapping/erasing
sudo dnf install -y gstreamer1-plugins-{bad-*,good-*,base} gstreamer1-libav \
    --exclude=gstreamer1-plugins-bad-free-devel --allowerasing

sudo dnf install -y lame* --exclude=lame-devel --allowerasing

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
# CRITICAL FEDORA STEP: The Symlink
sudo ln -s /var/lib/snapd/snap /snap || true
sudo systemctl enable --now snapd.socket

# Wait for snapd to seed
log INFO "Waiting for snapd to initialize..."
sleep 10

for snap_app in "${snap_packages[@]}"; do
    log INFO "Installing Snap → $snap_app"
    if sudo snap install "$snap_app"; then
         installed_snap_packages+=("$snap_app") 
    else
         log ERROR "Failed to install $snap_app"
    fi
done

##############################
# Log Rotation
##############################
LOG_DIR="$TARGET_HOME/logs"
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
# Monitor fix
##############################
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"

##############################
# Scripts & Configs 
##############################

# Custom update script
log INFO "Downloading Fedora update script"
sudo curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/Fedora_update.sh \
    -o /usr/bin/update.sh
sudo chmod +x /usr/bin/update.sh

# Custom file archiving 
sudo curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/arkive_files.sh \
    -o /usr/bin/arkive_files.sh
sudo chmod +x /usr/bin/arkive_files.sh

# Bash aliases (NEW URL)
log INFO "Adding Fedora bash aliases"
cp "$TARGET_HOME/.bashrc" "$TARGET_HOME/.bashrc.bak" 2>/dev/null || true
curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/Fedora_bashrc \
    >> "$TARGET_HOME/.bashrc"

# NFS mounts
sudo mkdir -p /mnt/Arkive 
curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/fstab \
    | sudo tee -a /etc/fstab > /dev/null

# Band Maid logo
mkdir -p "$TARGET_HOME/.local/share/fastfetch/logos"
curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/maid \
    -o "$TARGET_HOME/.local/share/fastfetch/logos/maid"

# Pipx + yt-dlp
sudo dnf install -y pipx
export PATH="$TARGET_HOME/.local/bin:$PATH"
sudo -u "$TARGET_USER" pipx install yt-dlp || true

# Bun JS
log INFO "Installing Bun"
sudo -u "$TARGET_USER" bash -c "curl -fsSL https://bun.com/install | bash"

##############################
# UID Change & Finalize
##############################
CURRENT_UID=$(id -u "$TARGET_USER")
if [ "$CURRENT_UID" != "$NEW_UID" ]; then
    display $RED "Updating UID to $NEW_UID and rebooting..."
    trap - ERR EXIT
    sudo bash -c "
        sed -i 's/^$TARGET_USER:x:$CURRENT_UID:/$TARGET_USER:x:$NEW_UID:/' /etc/passwd
        chown -R $NEW_UID:$NEW_GID $TARGET_HOME || true
        /sbin/reboot -f
    "
else
    display $GREEN "Script complete! po!"
    sudo reboot
fi