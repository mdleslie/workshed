#!/bin/bash
#######################################
#######################################
######################################
#### Template to work on. Not ready yet.
######################################
#####################################
###         Sample entry for crontab   ###
###     0 3 * * * /home/$USER/scripts/system_backup.sh
#####################################

# Set backup directory
BACKUP_DIR="/home/$USER/system_backups"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to create timestamped backups
create_backup() {
    local source_file=$1
    local backup_name=$(basename "$source_file")
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    sudo cp "$source_file" "$BACKUP_DIR/${backup_name}.backup_$timestamp"
}

# Backup important system files
create_backup "/etc/fstab"
create_backup "/etc/apt/sources.list"

# Add more files to backup as needed
# create_backup "/path/to/another/important/file"

# Clean up old backups (keep last 10)
cleanup_backups() {
    local file_prefix=$1
    local keep_count=10
    ls -t "$BACKUP_DIR/${file_prefix}"* | tail -n +$((keep_count + 1)) | xargs -r rm
}

cleanup_backups "fstab.backup_"
cleanup_backups "sources.list.backup_"

# Log the backup
echo "Backup completed on $(date)" >> "$BACKUP_DIR/backup.log"