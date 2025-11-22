#!/bin/bash
# Pop!_OS / Ubuntu Fresh Install Setup Script – 2025 Edition
# Author: workshed (@mdleslie) 

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
installed_deb_packages=()
installed_flatpak_apps=()

##############################
# EDIT THESE TWO ARRAYS 
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
    libgstreamer-plugins-bad1.0-dev
    gstreamer1.0-plugins-bad
    gstreamer1.0-qt5
    gstreamer1.0-plugins-ugly
    gstreamer1.0-plugins-good
    gstreamer1.0-libav
    libavcodec-extra
    chromium-codecs-ffmpeg-extra
    nfs-common
    cifs-utils
    gamemode
    steam
    cpu-x
    python3
    python3-pip
    figlet
    fonts-inter
    mangohud
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
    eu.betterbird.Betterbird
    net.davidotek.pupgui2
    com.vscodium.codium
    org.darktable.Darktable
    com.google.Chrome
    io.github.flattool.Warehouse
    com.discordapp.Discord
    com.github.IsmaelMartinez.teams_for_linux
    com.github.taiko2k.tauonmb
    org.inkscape.Inkscape
    com.rtosta.zapzap
    us.zoom.Zoom
    com.dropbox.Client
    md.obsidian.Obsidian
    com.github.unrud.VideoDownloader
    app.zen_browser.zen
    it.mijorus.gearlever
    io.github.Faugus.faugus-launcher
)

##############################
# Core Functions 
##############################

log() { local lvl=$1 msg=$2; printf "[%s] [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$lvl" "$msg" | tee -a "$log_file"; logger -p user."$lvl" "$msg"; }
display() { echo -e "${1}${2}${NC}" | tee -a "$log_file"; command -v lolcat >/dev/null 2>&1 && [[ -t 1 ]] && echo -e "$2" | lolcat || echo -e "$2"; }
lol() { command -v lolcat >/dev/null 2>&1 && [[ -t 1 ]] && "$@" | lolcat || "$@"; }
cache_sudo() { sudo -v; (while :; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) &; }

cleanup() {
    log INFO "Running cleanup..."
    [[ "$script_completed" != "true" ]] && [[ -f "$TARGET_HOME/.bashrc.bak" ]] && \
        mv "$TARGET_HOME/.bashrc.bak" "$TARGET_HOME/.bashrc" && log WARNING ".bashrc reverted"
}
trap 'log ERROR "Failed at line $LINENO"' ERR
trap cleanup EXIT
script_completed="false"

# Early lolcat
if ! command -v lolcat &>/dev/null; then
    log INFO "Installing lolcat – aesthetics matter, po!"
    sudo apt update && sudo apt install -y lolcat
fi

echo '########################################' | lol
echo '########################################' | lol
echo '########################################' | lol
display $GREEN "Lets go, it's showtime!"
sleep 5
cache_sudo

# System update + Nala
log INFO "Updating system + installing Nala"
display $GREEN "Updating and upgrading..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y nala

echo '########################################' | lol
display $GREEN "Gus, don't be William Zabka from Back to School."

# Microsoft fonts + DVD (your bulletproof method)
log INFO "Installing Microsoft fonts + libdvdcss"
display $GREEN "Microsoft fonts + DVD playback – the version that never fails, po!"
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
sudo apt install -y ttf-mscorefonts-installer libdvd-pkg
unset DEBIAN_FRONTEND
sudo dpkg-reconfigure -f noninteractive libdvd-pkg || true
sudo /usr/lib/libdvd-pkg/b-i_libdvdcss.sh -y <<< "y"

echo '########################################' | lol
display $GREEN "Are you a fan of delicious flavor?"

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
log INFO "Installing ${#flatpak_apps[@]} Flatpak apps"
[[ ! -x "$(command -v flatpak)" ]] && sudo nala install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
for app in "${flatpak_apps[@]}"; do
    if flatpak list --user | grep -q "$app"; then
        log INFO "$app → already installed"
    else
        log INFO "Installing Flatpak → $app"
        sudo -u "$TARGET_USER" flatpak install -y --user flathub "$app" && installed_flatpak_apps+=("$app")
    fi
done

# =============================================================================
# 8. FINAL TOUCHES 
# =============================================================================

# ─── 8.1 Custom update script 
log INFO "Downloading your custom update.sh script"
display $GREEN "Creating and downloading the update.sh script."
sudo curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/update.sh \
    -o /usr/bin/update.sh
sudo chmod +x /usr/bin/update.sh
display $GREEN "update.sh installed → just run 'update.sh' anytime!"

# ─── 8.2 Bash aliases 
log INFO "Adding Workshed bash aliases"
display $GREEN "Modifying .bashrc file to include useful aliases."
cp "$TARGET_HOME/.bashrc" "$TARGET_HOME/.bashrc.bak" 2>/dev/null || true

curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/bash.rc%20aliases \
    >> "$TARGET_HOME/.bashrc"

echo -e "\n# ── Workshed aliases loaded – po! ──" >> "$TARGET_HOME/.bashrc"
display $GREEN "Aliases added! Open a new terminal or run 'source ~/.bashrc'"

# ─── 8.3 NFS mounts for Arkive
log INFO "Adding NFS mounts to /etc/fstab"
display $BLUE "Modifying fstab file to include NFS mount to Arkive."
sudo mkdir -p /mnt/Arkive 
sudo cp /etc/fstab /etc/fstab.bak

curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/fstab \
    | sudo tee -a /etc/fstab > /dev/null

display $GREEN "NFS mounts added – they’ll appear after reboot"

# ─── 8.4 Band Maid fastfetch logo 
log INFO "Downloading an impossibly hard rocking maid logo, po."
display $GREEN "Adding new logo for fastfetch. An impossibly hard rocking maid logo, po."
sleep 5s
mkdir -p "$TARGET_HOME/.local/share/fastfetch/logos"
curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/maid \
    -o "$TARGET_HOME/.local/share/fastfetch/logos/maid"

display $GREEN "Band Maid logo installed – po!"

# ─── 8.5 yt-dlp (latest & greatest, via pipx)
log INFO "Installing/upgrading yt-dlp via pipx"
display $GREEN "Installing yt-dlp"

if ! command -v pipx &>/dev/null; then
    sudo nala install -y pipx
fi

# Make sure pipx is in PATH for this session
export PATH="$HOME/.local/bin:$PATH"

pipx install yt-dlp >/dev/null 2>&1 || pipx upgrade yt-dlp >/dev/null 2>&1
display $GREEN "yt-dlp is now fully up to date → $(yt-dlp --version)"

# Safe UID change service 
log INFO "Scheduling safe UID change to $NEW_UID"
display $RED "Rebooting once to apply UID change – totally normal!"

# NOTE: We use unquoted EOF here so we can inject $TARGET_USER and $NEW_UID
# but we escape \$ runtime variables that must run later.
sudo tee /opt/fix-my-uid.sh > /dev/null <<EOF
#!/bin/bash
set -euo pipefail

# Hardcoded values from installer
TARGET_USER="$TARGET_USER"
NEW_UID="$NEW_UID"

OLD_UID=\$(id -u "\$TARGET_USER")
[[ "\$OLD_UID" == "\$NEW_UID" ]] && exit 0

pkill -u "\$TARGET_USER" || true; sleep 2
usermod -u \$NEW_UID "\$TARGET_USER"

# Fix ownership
find /home "\$TARGET_USER" -uid "\$OLD_UID" -exec chown "\$TARGET_USER:\$TARGET_USER" {} + 2>/dev/null || true
find /tmp /var/tmp -uid "\$OLD_UID" -exec chown "\$TARGET_USER:\$TARGET_USER" {} + 2>/dev/null || true

# Repair flatpak permissions and systemd
runuser -u "\$TARGET_USER" -- flatpak repair --user || true
runuser -u "\$TARGET_USER" -- systemctl --user daemon-reload || true

touch /var/lib/uid-fix-done
EOF

sudo chmod +x /opt/fix-my-uid.sh
sudo tee /etc/systemd/system/fix-my-uid.service > /dev/null <<EOF
[Unit]
Description=Safe UID fix (once before login)
ConditionPathExists=!/var/lib/uid-fix-done
After=local-fs.target
Before=display-manager.service
[Service]
Type=oneshot
ExecStart=/opt/fix-my-uid.sh
ExecStartPost=/bin/touch /var/lib/uid-fix-done
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable fix-my-uid.service

# Final report
printf "Installed deb packages: %s\n" "${#installed_deb_packages[@]}" >> "$update_summary"
printf '%s\n' "${installed_deb_packages[@]}" >> "$update_summary"
printf "Installed Flatpak apps: %s\n" "${#installed_flatpak_apps[@]}" >> "$update_summary"
printf '%s\n' "${installed_flatpak_apps[@]}" >> "$update_summary"

display $GREEN "Computer will reboot for the PUID changes to take full effect, po."
display $BLUE "Warning, Computer will reboot for the PUID changes to take full effect, po."
sleep 10s

log INFO "Installation summary saved to $update_summary"

display $GREEN "Script complete. Installation summary saved to $update_summary"
sleep 5s

script_completed="true"
log INFO "All done – po!"
sleep 5s
display $BLUE "Shop smart. Shop S-Mart."
sleep 5s
figlet Workshed | lolcat -a -d 3
display $GREEN "Rebooting now to finish setup..."
display $RED "10"
sleep 1
display $RED "9"
sleep 1
display $RED "8"
sleep 1
display $RED "7"
sleep 1
display $RED "6"
sleep 1
display $RED "5"
sleep 1
display $RED "4"
sleep 1
display $RED "3"
sleep 1
display $RED "2"
sleep 1
display $RED "1"
sleep 1
sudo reboot now