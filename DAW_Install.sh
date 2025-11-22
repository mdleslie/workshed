#!/bin/bash

# DAW Installation Script
# Author: workshed (Modified by Miku Kobato, po!)
# Description: Installs and configures all native Digital Audio Workstation (DAW) tools
#              including REAPER, yabridge, and the Ratatouille LV2/Standalone plugin.
#
# NOTE: This script is designed to be run standalone and includes checks for prerequisite tools.

##############################
# Configuration Variables

# Determine the target user (the user who executed the script/sudo)
TARGET_USER="${SUDO_USER:-$USER}"

# Define log file paths based on the target user
log_file="/home/$TARGET_USER/daw_install_log.txt"
update_summary="/home/$TARGET_USER/daw_install_summary.txt"

# REAPER Version (UPDATE THIS IF NEW REAPER RELEASES COME OUT)
REAPER_VERSION="754"
REAPER_URL="https://www.reaper.fm/files/7.x/reaper${REAPER_VERSION}_linux_x86_64.tar.xz"
REAPER_INSTALL_DIR="/opt/REAPER"

# yabridge Version (UPDATE THIS IF NEW VERSIONS ARE RELEASED)
YABRIDGE_VERSION="5.0.4"
YABRIDGE_DIR="/opt/yabridge-$YABRIDGE_VERSION"
YABRIDGE_URL="https://github.com/robbert-vdh/yabridge/releases/download/$YABRIDGE_VERSION/yabridge-$YABRIDGE_VERSION.tar.gz"

# Colors (Copied from main script for consistency)
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flag to track script completion
script_completed="false"

##################################
# Core Functions (Re-created for standalone use)

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

# Cleanup function
cleanup() {
    log INFO "DAW cleanup finished."
}

# Function to check and install Nala if missing
check_and_install_nala() {
    if ! command -v nala &> /dev/null; then
        log INFO "Nala is not installed. Installing Nala using apt."
        display $GREEN "Installing Nala. Because it is better than apt."
        if sudo apt update && sudo apt install nala -y; then
            log INFO "Nala installed successfully."
        else
            log WARNING "Failed to install Nala. Falling back to using 'apt' for package installation."
        fi
    fi
    # If Nala is installed, ensure it is updated
    if command -v nala &> /dev/null; then
        sudo nala update
    else
        sudo apt update
    fi
}

# Function to cache sudo credentials
cache_sudo() {
    sudo -v
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null ) &
}


###############################################
# Error Handling & Traps

# Error handling: exit immediately if a command exits with a non-zero status
set -e
trap 'log ERROR "An error occurred. Exit code: $?"' ERR
trap cleanup EXIT

#################################################
# Package Arrays

# List of all critical dependencies for building audio tools (including Ratatouille)
# These dependencies MUST be installed regardless of whether they were in the OS setup script.
deb_packages=(
  "wine-stable"              # Essential for yabridge VST hosting
  "git"                       # Needed for cloning Ratatouille source/submodules
  "build-essential"           # Compiler toolchain (make, gcc, g++)
  "pkg-config"
  "libssl-dev"
  "libexpat1-dev"
  "libcairo2-dev"
  "libx11-dev"
  "libsndfile1-dev"
  "lv2-dev"
  "jackd2"                    # JACK Audio Connection Kit
  "libjack-jackd2-dev"        # JACK development headers (for Ratatouille)
  "portaudio19-dev"           # PortAudio development headers (for Ratatouille standalone)
  "libxcursor-dev"            # Graphical dependencies for custom UI libraries
  "libxext-dev"
  "libxrandr-dev"
  "curl"                      # Needed for downloading REAPER/yabridge/Ratatouille fallback
)

# Flatpak applications relevant to DAW workflow (e.g., audio utilities)
flatpak_apps=(
  "org.guitarix.Guitarix"     # Guitarix
  "org.rncbc.qpwgraph"        # PipeWire/JACK Graph Manager
  "ar.com.tuxguitar.TuxGuitar"
)

# Array to store the names of installed packages
installed_packages=()

#################################################
# DAW Installation Functions

# Function to generate and install .desktop shortcuts
install_desktop_shortcuts() {
    log INFO "Installing application shortcuts (.desktop files)."
    local target_user_home="/home/$TARGET_USER"
    local desktop_dir="$target_user_home/.local/share/applications"
    
    sudo mkdir -p "$desktop_dir"
    
    # 1. REAPER Desktop Entry
    cat << EOF | sudo tee "$desktop_dir/reaper-native.desktop" > /dev/null
[Desktop Entry]
Name=REAPER (Native)
Comment=REAPER Digital Audio Workstation
Exec=/usr/local/bin/reaper
Icon=${REAPER_INSTALL_DIR}/Data/reaper_logo_color.png
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Recorder;
EOF

    # 2. Ratatouille Standalone Entry
    cat << EOF | sudo tee "$desktop_dir/ratatouille-standalone.desktop" > /dev/null
[Desktop Entry]
Name=Ratatouille Standalone (LV2/NAM)
Comment=Standalone Neural Amp Modeler Host
Exec=/usr/local/bin/Ratatouille
Icon=audio-input-microphone
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Midi;
EOF

    # 3. Guitarix Flatpak Entry (Example - Guitarix is a Flatpak so this is mainly a placeholder)
    cat << EOF | sudo tee "$desktop_dir/guitarix-flatpak.desktop" > /dev/null
[Desktop Entry]
Name=Guitarix (Flatpak)
Comment=Virtual Guitar Amplifier
Exec=flatpak run org.guitarix.Guitarix
Icon=org.guitarix.Guitarix
Terminal=false
Type=Application
Categories=AudioVideo;Audio;
EOF
    
    # Set correct ownership so the user can see them
    sudo chown -R ${TARGET_USER}:${TARGET_USER} "$desktop_dir"
    log INFO "Shortcuts installed successfully to $desktop_dir."
    display $GREEN "Shortcuts ready, po!"
}

# --- YABRIDGE INSTALL BLOCK ---
install_yabridge() {
    log INFO "Starting yabridge installation (VST Bridge)."
    display $GREEN "Setting up yabridge VST Bridge."

    # 1. Download and unpack yabridge
    sudo mkdir -p "$YABRIDGE_DIR"
    curl -sL "$YABRIDGE_URL" -o /tmp/yabridge.tar.gz
    sudo tar -xf /tmp/yabridge.tar.gz -C /opt/
    sudo rm /tmp/yabridge.tar.gz
    log INFO "Yabridge binaries unpacked to /opt/."

    # 2. Add yabridge to the system's PATH
    sudo ln -sf "$YABRIDGE_DIR/yabridge" /usr/local/bin/yabridge
    sudo ln -sf "$YABRIDGE_DIR/yabridgectl" /usr/local/bin/yabridgectl
    log INFO "Yabridge symlinks created."

    # 3. Create standard VST Directories (User paths)
    local VST2_PATH="/home/$TARGET_USER/.vst"
    local VST3_PATH="/home/$TARGET_USER/.vst3"
    mkdir -p "$VST2_PATH"
    mkdir -p "$VST3_PATH"
    
    # 4. Set Windows VST plugin paths (Assuming local paths for now)
    local WIN_VST_PATH="/home/$TARGET_USER/VSTPlugins" 
    local WIN_VST3_PATH="/home/$TARGET_USER/VST3"       

    mkdir -p "$WIN_VST_PATH"
    mkdir -p "$WIN_VST3_PATH"
    sudo chown -R $TARGET_USER:$TARGET_USER "$WIN_VST_PATH" "$WIN_VST3_PATH" 
    log INFO "Windows VST paths configured (and created) for yabridge."

    # 5. Execute yabridgectl to link and sync directories (runs as the target user)
    log INFO "Executing yabridgectl sync as user $TARGET_USER."

    # We use sudo -H -u for reliability instead of runuser
    sudo -H -u "$TARGET_USER" bash -c "
        /usr/local/bin/yabridgectl clear
        /usr/local/bin/yabridgectl add '$WIN_VST_PATH'
        /usr/local/bin/yabridgectl add '$WIN_VST3_PATH'
        /usr/local/bin/yabridgectl sync
    " 2>&1 | log INFO

    log INFO "yabridge installation and sync completed."
    display $GREEN "yabridge VST bridge ready, po!"
}

####################
### Script Start ###
####################

log INFO "Starting DAW installation script"
display $GREEN "Omajinai time! Setting up the pro-audio software, po!"
sleep 3s

# Ensure user is logged in for the script to continue
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" == "root" ]; then
    log ERROR "FATAL: Could not determine non-root user. Miku requests you run script using 'sudo ./daw_install.sh'."
    exit 1
fi
display $GREEN "Target user identified as: $TARGET_USER"

# Cache sudo credentials
log INFO "Caching sudo credentials"
sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null ) &

# --- CHECK AND UPDATE PACKAGE MANAGER ---
check_and_install_nala

# Install necessary .deb packages
log INFO "Installing required DAW .deb packages."
# Determine which installer to use (nala is preferred)
INSTALLER="nala"
if ! command -v nala &> /dev/null; then
    INSTALLER="apt"
fi

for package in "${deb_packages[@]}"; do
    if dpkg -l | grep -qw "$package"; then
        log INFO "$package is already installed, skipping."
    else
        log INFO "Installing $package"
        if sudo "$INSTALLER" install -y "$package"; then
            installed_packages+=("$package")
        else
            log ERROR "Failed to install $package"
            exit 1 # Stop if core dependencies fail
        fi
    fi
done

echo '########################################' | lolcat

# Install necessary Flatpak applications
log INFO "Installing required DAW Flatpak applications."
if ! command -v flatpak &> /dev/null; then
    log WARNING "Flatpak not found. Skipping Flatpak app installation."
else
    for app in "${flatpak_apps[@]}"; do
        if flatpak list | grep -qw "$app"; then
            log INFO "$app is already installed, skipping."
        else
            log INFO "Installing $app"
            FLATPAK_OUTPUT=$(flatpak install -y --noninteractive flathub "$app" 2>&1)
            if [ $? -eq 0 ]; then
                log INFO "$app successfully installed. Details: $FLATPAK_OUTPUT"
                installed_packages+=("$app")
            else
                log ERROR "Failed to install $app. Output: $FLATPAK_OUTPUT"
            fi
        fi
    done
fi
echo '########################################' | lolcat

# Apply PortAudio linker fix (Crucial for brummer10 builds on Pop/Ubuntu)
log INFO "Applying PortAudio linker fix for brummer10 standalone builds"
echo "/usr/lib/x86_64-linux-gnu" | sudo tee /etc/ld.so.conf.d/portaudio.conf > /dev/null
sudo ldconfig
display $GREEN "PortAudio linker ready."
sleep 2s

# ----------------------------------------------------
# START RATATOUILLE LV2/STANDALONE INSTALL BLOCK (THE FIX)
# ----------------------------------------------------
log INFO "Installing Ratatouille LV2 Plugin & Standalone (FINAL, CLEAN INSTALL)"
display $GREEN "Installing Ratatouille LV2 Plugin and Standalone application."
sleep 2s

TEMP_SOURCE_DIR="/home/$TARGET_USER/Ratatouille.lv2-temp"
USER_HOME_DIR="/home/$TARGET_USER"
EXECUTABLE_NAME="Ratatouille" 
USER_BIN_PATH="/home/$TARGET_USER/bin"
SYSTEM_BIN_PATH="/usr/local/bin/$EXECUTABLE_NAME"

# Ensure user's personal bin path exists and is owned correctly
sudo mkdir -p "$USER_BIN_PATH"
sudo chown -R ${TARGET_USER}:${TARGET_USER} "$USER_BIN_PATH" 2>/dev/null || true

log INFO "Building and installing Ratatouille as user $TARGET_USER..."

# Capture full build output for debugging 
BUILD_OUTPUT=$(sudo -H -u "$TARGET_USER" bash -c "
    export HOME='$USER_HOME_DIR'
    cd '$USER_HOME_DIR'
    rm -rf '$TEMP_SOURCE_DIR'
    mkdir -p '$TEMP_SOURCE_DIR'
    cd '$TEMP_SOURCE_DIR'

    # Clone and submodule commands
    git clone https://github.com/brummer10/Ratatouille.lv2.git .
    git submodule update --init --recursive

    # 1. BUILD STANDALONE (FORCED FIRST EXECUTION to prevent Makefile logic skip)
    make standalone

    # 2. Build and Install LV2 (This step also installs standalone to ~/bin/)
    make lv2
    make install

    echo 'BUILD_AND_INSTALL_COMPLETED'
" 2>&1)

# Log the raw output (for diagnostic if the next step fails)
echo "--------------------------------------------------------" | tee -a "$log_file"
echo "RAW COMPILER OUTPUT START (Look for build errors below):" | tee -a "$log_file"
echo "$BUILD_OUTPUT" | tee -a "$log_file"
echo "RAW COMPILER OUTPUT END" | tee -a "$log_file"
echo "--------------------------------------------------------" | tee -a "$log_file"


# --- CHECK FOR SUCCESS AND COPY TO SYSTEM BIN ---
if [ -f "$USER_BIN_PATH/$EXECUTABLE_NAME" ] && [ -x "$USER_BIN_PATH/$EXECUTABLE_NAME" ]; then
    log INFO "Executable found in ~/bin/. Moving to system path."

    # Move it to system-wide location and set permissions
    if sudo cp "$USER_BIN_PATH/$EXECUTABLE_NAME" "$SYSTEM_BIN_PATH"; then
        sudo chmod 755 "$SYSTEM_BIN_PATH"
        rm -f "$USER_BIN_PATH/$EXECUTABLE_NAME" # Remove redundant copy

        log INFO "Standalone installed successfully."
        display $GREEN "Ratatouille LV2 & Standalone Installation Complete, po!"
    else
        log ERROR "Failed to copy built Ratatouille executable to $SYSTEM_BIN_PATH. Check final permissions."
        exit 1
    fi
    
else
    # ───── FALLBACK: Use brummer10's official prebuilt binary (if local build failed) ─────
    log WARNING "Local build failed (Executable not found in ~/bin/). Attempting official prebuilt download."

    if sudo curl -L --fail -o "$SYSTEM_BIN_PATH" \
        https://github.com/brummer10/Ratatouille.lv2/releases/latest/download/Ratatouille; then
        
        sudo chmod 755 "$SYSTEM_BIN_PATH"
        log INFO "Official prebuilt Ratatouille standalone installed successfully!"
        display $GREEN "Ratatouille LV2 + Official Prebuilt Standalone Installed, po! 🐀🍲 (fallback used)"
    else
        log ERROR "FATAL: Both local build and prebuilt download failed. Review the raw output above for the compiler error."
        # No recovery possible
        exit_code=1
    fi
fi

# Final cleanup (always runs now — success or fallback)
sudo rm -rf "$TEMP_SOURCE_DIR" 2>/dev/null || true
hash -r

log INFO "Ratatouille installation fully completed for ${TARGET_USER}"
echo "--- Ratatouille Installation Complete ---"

# ----------------------------------------------------
# END RATATOUILLE LV2/STANDALONE INSTALL BLOCK
# ----------------------------------------------------


# --- REAPER NATIVE INSTALL BLOCK ---
log INFO "Starting REAPER installation (Native DAW)."
REAPER_INSTALLED=false

# Check if REAPER is already installed
if [ -f "$REAPER_INSTALL_DIR/reaper" ]; then
    log INFO "REAPER is already installed at $REAPER_INSTALL_DIR, skipping."
    REAPER_INSTALLED=true
fi

# If not installed, download and install
if [ "$REAPER_INSTALLED" = false ]; then
    display $BLUE "Downloading REAPER version ${REAPER_VERSION}..."
    
    TEMP_DIR="/tmp/reaper_install_$$"
    mkdir -p "$TEMP_DIR"
    
    if curl --fail -L "$REAPER_URL" -o "$TEMP_DIR/reaper.tar.xz"; then
        log INFO "Download successful, extracting."
        
        if tar -xf "$TEMP_DIR/reaper.tar.xz" -C "$TEMP_DIR"; then
            REAPER_SOURCE_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "reaper_linux*" | head -1)
            
            if [ -d "$REAPER_SOURCE_DIR" ]; then
                log INFO "Installing native REAPER from $REAPER_SOURCE_DIR to $REAPER_INSTALL_DIR."
                sudo mkdir -p "$REAPER_INSTALL_DIR"
                
                # Copy files and ensure permissions
                sudo cp -R "$REAPER_SOURCE_DIR"/* "$REAPER_INSTALL_DIR/"
                sudo chmod +x "$REAPER_INSTALL_DIR/reaper"
                
                # Create symlink for global access
                sudo ln -sf "$REAPER_INSTALL_DIR/reaper" /usr/local/bin/reaper
                
                REAPER_INSTALLED=true
                display $GREEN "REAPER installed successfully, po!"
            else
                log ERROR "Could not find REAPER directory in extracted archive."
            fi
        else
            log ERROR "Failed to extract REAPER archive."
        fi
    else
        log ERROR "Failed to download REAPER from $REAPER_URL. Check version or connectivity."
    fi
    
    rm -rf "$TEMP_DIR"
fi
echo '########################################' | lolcat

display $GREEN "Don't fear the Reaper."
sleep 1s
display $GREEN "Baby, I'm your man."
sleep 2s
display $GREEN "La, la, la, la, la."
sleep 2s
display $GREEN "La, la, la, la, la."
sleep 5s

# --- End of Reaper Install Block ---

# --- YABRIDGE INSTALL BLOCK ---
install_yabridge # Runs the function defined earlier

echo '########################################' | lolcat

# ----------------------------------------------------

# Miku will install the shortcuts now to complete the file structure
install_desktop_shortcuts # Creates .desktop files for all apps

# ----------------------------------------------------

# Final summary
log INFO "DAW installation script finished successfully."
display $GREEN "Omajinai complete! Your DAW environment is ready, po! ✨"
echo "" >> "$update_summary"
echo "--- DAW INSTALLATION SUMMARY ---" >> "$update_summary"
echo "Installed/Updated packages: ${#installed_packages[@]}" >> "$update_summary"
echo "Installed programs:" >> "$update_summary"
printf '%s\n' "${installed_packages[@]}" >> "$update_summary"
echo "REAPER version: ${REAPER_VERSION}" >> "$update_summary"
echo "yabridge version: ${YABRIDGE_VERSION}" >> "$update_summary"
echo "Installation complete!" >> "$update_summary"

script_completed="true"