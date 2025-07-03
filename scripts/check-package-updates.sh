#!/bin/bash

#===============================================================================
# Check Package Updates Script
# ~/.config/scripts/check-package-updates.sh
# Description: Checks for available package updates using checkupdates-with-aur.
# Author: saatvik333
# Version: 1.2
# Dependencies: checkupdates-with-aur, notify-send (optional)
#===============================================================================

# Prevent multiple instances
script_name=$(basename "$0")
lockfile="/tmp/${script_name}.lock"

# Clean up lock file on exit
trap 'rm -f "$lockfile"' EXIT

# Use flock for better process control
exec 200>"$lockfile"
if ! flock -n 200; then
    exit 1
fi

# Check if checkupdates-with-aur is available
if ! command -v checkupdates-with-aur >/dev/null 2>&1; then
    # Send desktop notification
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Waybar Update Checker" "checkupdates-with-aur not found. Install pacman-contrib or use an AUR helper." -u normal -i dialog-warning
    fi
    echo '{"tooltip": "checkupdates-with-aur not found - install pacman-contrib", "class": "transparent"}'
    exit 1
fi

# Define color thresholds (fixed typo)
threshold_null=0
threshold_yellow=25
threshold_red=100

# Check for database lock and wait if necessary
check_lock_files() {
    local pacman_lock="/var/lib/pacman/db.lck"
    local checkup_lock="${TMPDIR:-/tmp}/checkup-db-${UID}/db.lck"
    local timeout=30
    local elapsed=0

    while [ -f "$pacman_lock" ] || [ -f "$checkup_lock" ]; do
        if [ $elapsed -ge $timeout ]; then
            echo '{"tooltip": "Database locked - try again later", "class": "transparent"}'
            exit 1
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
}

check_lock_files

# Get update count with error handling
if ! updates=$(checkupdates-with-aur 2>/dev/null | wc -l); then
    echo '{"tooltip": "Error checking updates", "class": "transparent"}'
    exit 1
fi

# Determine CSS class based on update count
css_class="transparent"
if [ "$updates" -gt $threshold_null ]; then
    css_class="green"
fi
if [ "$updates" -gt $threshold_yellow ]; then
    css_class="yellow"
fi
if [ "$updates" -gt $threshold_red ]; then
    css_class="red"
fi

# Output JSON for Waybar
if [ "$updates" -gt 0 ]; then
    printf '{"text": "%s", "tooltip": "%s packages require updates", "class": "%s"}\n' "$updates" "$updates" "$css_class"
else
    printf '{"text": "0", "tooltip": "No updates available", "class": "transparent"}\n'
fi
