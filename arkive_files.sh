#!/bin/bash

# --- CONFIGURATION ---
SOURCE="/media/david/LandingDrive/Drop Folder/"
DEST="/mnt/Ark/Vault/"
# I added .log to the filename so it opens easily in text editors
LOGDIR="/home/david/logs"
LOGFILE="$LOGDIR/move_logs.log"

# --- PRE-FLIGHT ---
# Create the log directory if it is missing
mkdir -p "$LOGDIR"

# --- SAFETY CHECK ---
if [ ! -d "$DEST" ]; then
    echo "$(date): ERROR - Destination drive not mounted at $DEST. Aborting." >> "$LOGFILE"
    exit 1
fi

# --- EXECUTION ---
echo "$(date): Starting move job..." >> "$LOGFILE"

# Run rsync
rsync -av --remove-source-files "$SOURCE" "$DEST" >> "$LOGFILE" 2>&1

echo "$(date): Job finished." >> "$LOGFILE"
echo "-------------------------------------" >> "$LOGFILE"