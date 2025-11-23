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
    net-tools
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

log() { local lvl="$1" msg="$2"; printf "[%s] [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$lvl" "$msg" | tee -a "$log_file"; logger -p user."$lvl" "$msg"; }
display() { echo -e "${1}${2}${NC}" | tee -a "$log_file"; command -v lolcat >/dev/null 2>&1 && [[ -t 1 ]] && echo -e "$2" | lolcat || echo -e "$2"; }
lol() { command -v lolcat >/dev/null 2>&1 && [[ -t 1 ]] && "$@" | lolcat || "$@"; }
cache_sudo() { sudo -v; (while :; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) & }

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

echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat
display $GREEN "Lets go, it's showtime!"
echo '########################################' | lolcat
echo '########################################' | lolcat
echo '########################################' | lolcat
display $GREEN "Don't mix danger, handle with care!"
sleep 5
cache_sudo

# ─── Add Fastfetch PPA immediately ───
log INFO "Adding Fastfetch PPA"
display $GREEN "Adding Fastfetch PPA..."
sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
# ─────────────────────────────────────────────────

# System update + Nala
log INFO "Updating system + installing Nala"
display $GREEN "Updating and upgrading..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y nala

echo '########################################' | lolcat
display $GREEN "Gus, don't be William Zabka from Back to School."
sleep 3s

##############################
# Microsoft Fonts + DVD support
##############################
log INFO "Preconfiguring Microsoft fonts and libdvd-pkg"
display $GREEN "Installing Microsoft fonts and libdvd – safe mode, po!"

# 1. PURGE
sudo apt-get purge -y libdvd-pkg ttf-mscorefonts-installer 2>/dev/null || true

# 2. PRE-SEED 
sudo debconf-set-selections <<EOF
ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true
libdvd-pkg libdvd-pkg/first-install boolean true
libdvd-pkg libdvd-pkg/post-invoke_hook-install boolean true
EOF

# 3. INSTALL
export DEBIAN_FRONTEND=noninteractive
sudo apt-get install -yq ttf-mscorefonts-installer libdvd-pkg

# 4. BUILD & CONFIGURE
sudo bash /usr/lib/libdvd-pkg/b-i_libdvdcss.sh <<EOF
y
y
EOF

unset DEBIAN_FRONTEND

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
sleep 2s

# ─── 8.2 Bash aliases 
log INFO "Adding Workshed bash aliases"
display $GREEN "Modifying .bashrc file to include useful aliases."
cp "$TARGET_HOME/.bashrc" "$TARGET_HOME/.bashrc.bak" 2>/dev/null || true

curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/bash.rc%20aliases \
    >> "$TARGET_HOME/.bashrc"

echo -e "\n# ── Workshed aliases loaded – po! ──" >> "$TARGET_HOME/.bashrc"
display $GREEN "Aliases added! Open a new terminal or run 'source ~/.bashrc'"
sleep 2s

# ─── 8.3 NFS mounts for Arkive
log INFO "Adding NFS mounts to /etc/fstab"
display $BLUE "Modifying fstab file to include NFS mount to Arkive."
sudo mkdir -p /mnt/Arkive 
sudo cp /etc/fstab /etc/fstab.bak

curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/fstab \
    | sudo tee -a /etc/fstab > /dev/null

display $GREEN "NFS mounts added – they’ll appear after reboot"
sleep 2s

# ─── 8.4 Band Maid fastfetch logo 
log INFO "Downloading an impossibly hard rocking maid logo, po."
display $GREEN "Adding new logo for fastfetch. An impossibly hard rocking maid logo, po."
sleep 5s
mkdir -p "$TARGET_HOME/.local/share/fastfetch/logos"
curl -fsSL https://raw.githubusercontent.com/mdleslie/workshed/workshed/maid \
    -o "$TARGET_HOME/.local/share/fastfetch/logos/maid"

display $GREEN "Band Maid logo installed – po!"
sleep 3s

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
sleep 2s

# Safe UID change service (FAST VERSION)
log INFO "Scheduling safe UID change to $NEW_UID"
display $RED "Rebooting once to apply UID change – totally normal!"

sudo tee /opt/fix-my-uid.sh > /dev/null <<EOF
#!/bin/bash
set -euo pipefail

# Hardcoded values from installer
TARGET_USER="$TARGET_USER"
NEW_UID="$NEW_UID"
TARGET_HOME="/home/\$TARGET_USER"

OLD_UID=\$(id -u "\$TARGET_USER")
[[ "\$OLD_UID" == "\$NEW_UID" ]] && exit 0

# Kill user processes
pkill -u "\$TARGET_USER" || true; sleep 1

# Change the UID
usermod -u \$NEW_UID "\$TARGET_USER"

# FAST FIX: Use recursive chown (Instant on new systems)
if [ -d "\$TARGET_HOME" ]; then
    chown -R "\$TARGET_USER:\$TARGET_USER" "\$TARGET_HOME"
fi

# Check tmp files (safer with find)
find /tmp /var/tmp -uid "\$OLD_UID" -exec chown "\$TARGET_USER:\$TARGET_USER" {} + 2>/dev/null || true

# Repair Flatpaks and Reload Systemd
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