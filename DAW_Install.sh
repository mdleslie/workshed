#!/bin/bash

# DAW Installation Script
# Author: workshed (Modified by Miku Kobato, po!)
# Description: Installs REAPER, yabridge, Ratatouille, and Scarlett GUI.
#              (Fixed Permissions & Directory Logic)

##############################
# Configuration Variables
##############################

TARGET_USER="${SUDO_USER:-$USER}"
log_file="/home/$TARGET_USER/daw_install_log.txt"

# REAPER Version
REAPER_VERSION="754"
REAPER_URL="https://www.reaper.fm/files/7.x/reaper${REAPER_VERSION}_linux_x86_64.tar.xz"
REAPER_INSTALL_DIR="/opt/REAPER"

# yabridge Version
YABRIDGE_VERSION="5.0.4"
YABRIDGE_DIR="/opt/yabridge-$YABRIDGE_VERSION"
YABRIDGE_URL="https://github.com/robbert-vdh/yabridge/releases/download/$YABRIDGE_VERSION/yabridge-$YABRIDGE_VERSION.tar.gz"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

##############################
# Core Functions
##############################

log() {
    echo "[$1] $2" | tee -a "$log_file"
}

display() {
    echo -e "$1$2${NC}"
}

check_and_install_nala() {
    if ! command -v nala &> /dev/null; then
        sudo apt update && sudo apt install nala -y
    fi
}

##############################
# Package Arrays
##############################

deb_packages=(
  "wine-stable" "git" "build-essential" "pkg-config" "libssl-dev"
  "libexpat1-dev" "libcairo2-dev" "libx11-dev" "libsndfile1-dev"
  "lv2-dev" "jackd2" "libjack-jackd2-dev" "portaudio19-dev"
  "libxcursor-dev" "libxext-dev" "libxrandr-dev" "curl" 
  "make" "gcc" "libgtk-4-dev" "libasound2-dev"
)

flatpak_apps=(
  "org.guitarix.Guitarix"
  "org.rncbc.qpwgraph"
  "ar.com.tuxguitar.TuxGuitar"
)

##############################
# Main Logic
##############################

export DEBIAN_FRONTEND=noninteractive

log INFO "Starting DAW Installation..."
display $GREEN "Omajinai time! Setting up the pro-audio software!"

# 1. Install Nala & Pre-configure Jackd2
check_and_install_nala
sudo apt-get install -y debconf-utils
echo "jackd2 jackd/tweak_rt_limits boolean true" | sudo debconf-set-selections

# 2. Install Dependencies
INSTALLER="nala"
if ! command -v nala &> /dev/null; then INSTALLER="apt"; fi

log INFO "Installing dependencies..."
for package in "${deb_packages[@]}"; do
    sudo DEBIAN_FRONTEND=noninteractive "$INSTALLER" install -y "$package"
done

# 3. Install Flatpaks
if command -v flatpak &> /dev/null; then
    for app in "${flatpak_apps[@]}"; do
        flatpak install -y --noninteractive flathub "$app"
    done
fi

# 4. PortAudio Fix
echo "/usr/lib/x86_64-linux-gnu" | sudo tee /etc/ld.so.conf.d/portaudio.conf > /dev/null
sudo ldconfig

# -----------------------------------------------------------
# 5. RATATOUILLE FIX (Build as User, Install as Root)
# -----------------------------------------------------------
log INFO "Installing Ratatouille..."
TEMP_SOURCE="/home/$TARGET_USER/Ratatouille.lv2-temp"

# Step A: Compile as the normal user (avoids permission errors in home dir)
# We delete the fallback curl command entirely because it was broken.
sudo -H -u "$TARGET_USER" bash -c "
    rm -rf '$TEMP_SOURCE'
    mkdir -p '$TEMP_SOURCE'
    cd '$TEMP_SOURCE'
    git clone https://github.com/brummer10/Ratatouille.lv2.git .
    git submodule update --init --recursive
    make standalone
    make lv2
"

# Step B: Install the compiled binaries as ROOT
if [ -f "$TEMP_SOURCE/Ratatouille" ]; then
    log INFO "Binary compiled successfully. Installing..."
    cp "$TEMP_SOURCE/Ratatouille" /usr/local/bin/Ratatouille
    chmod +x /usr/local/bin/Ratatouille
    
    # Install LV2 Plugin
    mkdir -p /usr/lib/lv2/Ratatouille.lv2
    cp -r "$TEMP_SOURCE/Ratatouille.lv2/"* /usr/lib/lv2/Ratatouille.lv2/
else
    log ERROR "Ratatouille failed to compile. Check 'build-essential' and 'libgtk-4-dev'."
fi
rm -rf "$TEMP_SOURCE"

# -----------------------------------------------------------
# 6. SCARLETT FIX (Create Firmware Dir)
# -----------------------------------------------------------
log INFO "Installing Scarlett Focus GUI..."
if [ -d "alsa-scarlett-gui" ]; then rm -rf alsa-scarlett-gui; fi

# CRITICAL FIX: Create the firmware directory to prevent Segfault
sudo mkdir -p /usr/lib/firmware/scarlett2

git clone https://github.com/geoffreybennett/alsa-scarlett-gui
cd alsa-scarlett-gui/src
make -j$(nproc)
sudo make install

# Cleanup
cd ../.. 
rm -rf alsa-scarlett-gui

# 7. REAPER Install
log INFO "Installing REAPER..."
mkdir -p /tmp/reaper_install
curl -L "$REAPER_URL" -o /tmp/reaper_install/reaper.tar.xz
tar -xf /tmp/reaper_install/reaper.tar.xz -C /tmp/reaper_install
REAPER_SRC=$(find /tmp/reaper_install -maxdepth 1 -type d -name "reaper_linux*" | head -1)
sudo cp -R "$REAPER_SRC"/* "$REAPER_INSTALL_DIR/" 2>/dev/null || sudo mkdir -p "$REAPER_INSTALL_DIR" && sudo cp -R "$REAPER_SRC"/* "$REAPER_INSTALL_DIR/"
sudo ln -sf "$REAPER_INSTALL_DIR/reaper" /usr/local/bin/reaper
rm -rf /tmp/reaper_install

# 8. Yabridge Install
log INFO "Installing Yabridge..."
sudo mkdir -p "$YABRIDGE_DIR"
curl -sL "$YABRIDGE_URL" -o /tmp/yabridge.tar.gz
sudo tar -xf /tmp/yabridge.tar.gz -C /opt/
sudo ln -sf "$YABRIDGE_DIR/yabridge" /usr/local/bin/yabridge
sudo ln -sf "$YABRIDGE_DIR/yabridgectl" /usr/local/bin/yabridgectl
rm /tmp/yabridge.tar.gz

# 9. Create Desktop Shortcuts
log INFO "Creating Shortcuts..."
mkdir -p "/home/$TARGET_USER/.local/share/applications"

# REAPER Shortcut
cat << EOF | sudo tee "/home/$TARGET_USER/.local/share/applications/reaper-native.desktop" > /dev/null
[Desktop Entry]
Name=REAPER
Exec=/usr/local/bin/reaper
Icon=${REAPER_INSTALL_DIR}/Data/reaper_logo_color.png
Type=Application
Categories=Audio;
EOF

# Ratatouille Shortcut
cat << EOF | sudo tee "/home/$TARGET_USER/.local/share/applications/ratatouille.desktop" > /dev/null
[Desktop Entry]
Name=Ratatouille
Exec=/usr/local/bin/Ratatouille
Icon=audio-input-microphone
Type=Application
Categories=Audio;
EOF

# Scarlett Shortcut (Ensuring full path)
sudo sed -i 's|Exec=alsa-scarlett-gui|Exec=/usr/local/bin/alsa-scarlett-gui|g' /usr/share/applications/alsa-scarlett-gui.desktop 2>/dev/null

# Correct ownership of shortcuts
sudo chown -R $TARGET_USER:$TARGET_USER "/home/$TARGET_USER/.local/share/applications"

log INFO "Installation Complete!"
display $GREEN "All done, po!"