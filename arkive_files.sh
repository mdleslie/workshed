#!/bin/bash

# --- CONFIGURATION ---
SOURCE_DIR="/media/david/LandingDrive/Drop Folder"
DEST_DIR="/mnt/Merlin/dest_vault/Temp"  # Verified: Manual mount point
LOGDIR="/home/david/logs/arkive"   # Consolidated with system logs
LOGFILE="$LOGDIR/move_logs.log"

# --- PRE-FLIGHT ---
mkdir -p "$LOGDIR"

if [ ! -d "$SOURCE_DIR" ] || [ ! -d "$DEST_DIR" ]; then
    echo "$(date): ERROR - Drives not mounted or paths incorrect." >> "$LOGFILE"
    exit 1
fi

echo "$(date): Starting Smart Move Job (Files > 30 days old)..." >> "$LOGFILE"

# --- THE LOGIC LOOP ---
find "$SOURCE_DIR" -type f -mtime +30 -printf "%P\0" | while IFS= read -r -d '' rel_path; do
    
    SOURCE_FILE="$SOURCE_DIR/$rel_path"
    DEST_FILE="$DEST_DIR/$rel_path"
    DEST_PARENT=$(dirname "$DEST_FILE")

    # Create destination folder structure if missing
    mkdir -p "$DEST_PARENT"

    # Define the final destination path (default)
    FINAL_DEST="$DEST_FILE"

    # --- COLLISION CHECKING ---
    if [ -f "$DEST_FILE" ]; then
        
        s_size=$(stat -c%s "$SOURCE_FILE")
        d_size=$(stat -c%s "$DEST_FILE")

        # LOGIC A: Same Name + Same Size = IGNORE (Keep in Source)
        if [ "$s_size" -eq "$d_size" ]; then
            echo "Skipping (Duplicate): $rel_path" >> "$LOGFILE"
            continue 
        
        # LOGIC B: Same Name + Different Size = RENAME
        else
            filename=$(basename "$rel_path")
            extension="${filename##*.}"
            filename_no_ext="${filename%.*}"
            
            if [ "$filename" == "$extension" ]; then extension=""; dot=""; else dot="."; fi

            count=1
            new_name="${filename_no_ext}_$(printf "%04d" $count)${dot}${extension}"
            new_dest="$DEST_PARENT/$new_name"

            while [ -f "$new_dest" ]; do
                ((count++))
                new_name="${filename_no_ext}_$(printf "%04d" $count)${dot}${extension}"
                new_dest="$DEST_PARENT/$new_name"
            done

            echo "Conflict (Size Mismatch). Renaming to $new_name" >> "$LOGFILE"
            FINAL_DEST="$new_dest"
        fi
    fi

    # --- EXECUTION: MANUAL COPY AND DELETE ---
    # We use rsync to copy because it's robust, but we handle deletion ourselves.
    # -t: Preserve time (try to)
    # --no-perms --no-owner --no-group: Don't fight the NAS over ownership
    
    rsync -t --no-perms --no-owner --no-group "$SOURCE_FILE" "$FINAL_DEST" 2>/dev/null
    
    # SAFETY CHECK: Only delete source if destination file now exists
    if [ -f "$FINAL_DEST" ]; then
        rm "$SOURCE_FILE"
    else
        echo "ERROR: Failed to move $rel_path" >> "$LOGFILE"
    fi

done

echo "$(date): Job finished." >> "$LOGFILE"
echo "-------------------------------------" >> "$LOGFILE"