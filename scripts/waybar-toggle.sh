#!/bin/bash

# Toggle script for Waybar

# Check if waybar is running
if pgrep -x waybar > /dev/null; then
    # Kill waybar
    killall waybar
else
    # Start waybar
    waybar &
fi
