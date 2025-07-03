#!/bin/bash

#===============================================================================
# Updates waybar.css
# ~/.config/scripts/waybar-wallpaper-detection.sh
# Description: Updates waybar.css template in wallust folder based on the wallpaper
# region based on the luminosity of the top 5% area from top aka waybar region for clarity
# Author: saatvik333
# Version: 2.1
# Dependencies: cat magick sed bc
#===============================================================================

# Check if wallpaper path was provided
if [[ -z "$1" ]]; then
    echo "ERROR: Wallpaper path not provided" >&2
    exit 1
fi

WALLPAPER="$1"

# Get image dimensions and calculate crop region
IMG_INFO=$(magick identify -format "%w %h" "$WALLPAPER" 2>/dev/null)
if [[ $? -ne 0 ]]; then
    echo "ERROR: Failed to get image info for: $WALLPAPER" >&2
    exit 1
fi

read -r IMG_W IMG_H <<< "$IMG_INFO"
CROP_H=$((IMG_H * 5 / 100))

# Extract top region RGB values
RGB_VALUES=$(magick "$WALLPAPER" -crop "${IMG_W}x${CROP_H}+0+0" -resize 1x1! -format "%[fx:int(255*r)] %[fx:int(255*g)] %[fx:int(255*b)]" info:- 2>/dev/null)
if [[ $? -ne 0 ]]; then
    echo "ERROR: Failed to process image: $WALLPAPER" >&2
    exit 1
fi

read -r R G B <<< "$RGB_VALUES"

# Calculate relative luminance
LUMINANCE=$(echo "scale=0; ($R * 299 + $G * 587 + $B * 114) / 1000" | bc)

# Check if light (threshold 128)
if (( $(echo "$LUMINANCE > 80" | bc -l) )); then
    # Light background - swap colors
    sed -i.bak \
        -e 's/@define-color background {{background}};/@define-color background {{foreground}};/' \
        -e 's/@define-color foreground {{foreground}};/@define-color foreground {{background}};/' \
        ~/.config/wallust/templates/waybar.css

    echo "RGB: $R $G $B, Luminance: $LUMINANCE"
else
    # Dark background - restore original
    sed -i.bak \
        -e 's/@define-color background {{foreground}};/@define-color background {{background}};/' \
        -e 's/@define-color foreground {{background}};/@define-color foreground {{foreground}};/' \
        ~/.config/wallust/templates/waybar.css

    echo "RGB: $R $G $B, Luminance: $LUMINANCE"
fi
