#!/bin/bash

# Path to your Waybar toggle script
# Command to toggle Waybar
TOGGLE_COMMAND='pgrep -x waybar >/dev/null && killall waybar || waybar &'

# Hover detection threshold for X coordinate
HOVER_THRESHOLD=1

# Variable to track if the mouse was previously in the hover area
LAST_HOVER_STATE=0

# Listen for cursorMoved events and filter them directly
socat - UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE.sock | \
grep --line-buffered '^cursorMoved' | while read -r line; do
    # Extract X coordinate directly from the event
    X=$(echo "$line" | awk -F'[ ,]' '{print $2}')

    # Check if mouse is within the hover threshold
    if (( X <= HOVER_THRESHOLD )); then
        if (( LAST_HOVER_STATE == 0 )); then
            # Toggle Waybar state
            "$TOGGLE_COMMAND"
            LAST_HOVER_STATE=1
        fi
    else
        LAST_HOVER_STATE=0
    fi
done
