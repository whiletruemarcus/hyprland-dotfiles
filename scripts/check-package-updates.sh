#!/bin/bash

# Prevent multiple instances
script_name=$(basename "$0")
instance_count=$(ps aux | grep -F "$script_name" | grep -v grep | grep -v $$ | wc -l)
if [ $instance_count -gt 1 ]; then
    sleep $instance_count
fi

# Define color thresholds
threshoold_null=0
threshhold_yellow=25
threshhold_red=100

# Check for database lock and wait if necessary
check_lock_files() {
    local pacman_lock="/var/lib/pacman/db.lck"
    local checkup_lock="${TMPDIR:-/tmp}/checkup-db-${UID}/db.lck"
    while [ -f "$pacman_lock" ] || [ -f "$checkup_lock" ]; do
        sleep 1
    done
}

check_lock_files
updates=$(checkupdates-with-aur | wc -l)

# Determine CSS class based on update count
css_class="transparent"
if [ "$updates" -gt $threshoold_null ]; then
    css_class="green"
fi
if [ "$updates" -gt $threshhold_yellow ]; then
    css_class="yellow"
fi
if [ "$updates" -gt $threshhold_red ]; then
    css_class="red"
fi

# Output JSON for Waybar
if [ "$updates" -gt 0 ]; then
    printf '{"tooltip": "%s package require updates", "class": "%s"}' "$updates" "$css_class"
else
    printf '{"tooltip": "No updates available", "class": "transparent"}'
fi
