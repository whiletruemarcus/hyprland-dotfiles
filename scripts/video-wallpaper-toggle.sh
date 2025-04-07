#!/bin/bash

# Toggle script for mpvpaper live wallpaper

# Path to your video wallpaper
VIDEO_WALLPAPER="$HOME/Pictures/Wallpapers/you-ghost-my-heart-black.mp4"

# Check if mpvpaper is running
if pgrep -x mpvpaper > /dev/null; then
    # Kill mpvpaper with signal SIGUSR2
    killall SIGUSR2 mpvpaper
    notify-send "mpvpaper" "Live wallpaper stopped" -t 2000
else
    # Start mpvpaper
    mpvpaper -vs -o "no-audio loop" '*' "$VIDEO_WALLPAPER" &
    notify-send "mpvpaper" "Live wallpaper started" -t 2000
fi
