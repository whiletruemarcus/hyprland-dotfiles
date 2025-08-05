#!/bin/bash

#===============================================================================
# Updates wofi colors
# ~/.config/scripts/update-wofi-colors.sh
# Description: Updates wofi style.css based on the colors defined in colors.css by
# converting hex colors to rgba and applying lightening effects.
# It also manages GTK configuration files, symlinks for assets, and updates xsettingsd.
# Author: saatvik333
# Version: 2.0
# Dependencies: sed grep
#===============================================================================

# Make sure the config directory exists
mkdir -p ~/.config/wofi

COLORS_FILE="$HOME/.config/wofi/colors.css"

# Function to extract color value from CSS variable
extract_color() {
  local var_name="$1"
  grep -o "^[[:space:]]*--${var_name}:[[:space:]]*#[0-9a-fA-F]\{6\}" "$COLORS_FILE" |
    sed -E 's/^[[:space:]]*--[^:]+:[[:space:]]*#([0-9a-fA-F]{6}).*/\1/'
}

# Function to convert hex to RGB values
hex_to_rgb() {
  local hex="$1"
  local r=$((0x${hex:0:2}))
  local g=$((0x${hex:2:2}))
  local b=$((0x${hex:4:2}))
  echo "$r,$g,$b"
}

# Function to lighten a color
lighten_hex() {
  local hex="$1"
  local percent="$2"
  local r=$((0x${hex:0:2}))
  local g=$((0x${hex:2:2}))
  local b=$((0x${hex:4:2}))

  r=$((r + (255 - r) * percent / 100))
  g=$((g + (255 - g) * percent / 100))
  b=$((b + (255 - b) * percent / 100))

  r=$((r > 255 ? 255 : r))
  g=$((g > 255 ? 255 : g))
  b=$((b > 255 ? 255 : b))

  printf "%02x%02x%02x" "$r" "$g" "$b"
}

# Extract colors from CSS file
if [[ ! -f "$COLORS_FILE" ]]; then
  echo "Error: Colors file not found at $COLORS_FILE"
  exit 1
fi

# Extract all required colors
BG=$(extract_color "background")
FG=$(extract_color "foreground")
C0=$(extract_color "color0")
C1=$(extract_color "color1")
C3=$(extract_color "color3")
C4=$(extract_color "color4")
C5=$(extract_color "color5")

# Fallback colors if extraction fails
BG=${BG:-"2A2D2E"}
FG=${FG:-"FFD3FF"}
C0=${C0:-"4F5253"}
C1=${C1:-"573B71"}
C3=${C3:-"8B4AAB"}
C4=${C4:-"AE57CE"}
C5=${C5:-"DC6FF3"}

# Generate accent colors
ACCENT=$(lighten_hex "$C4" 10)
SELECTION=$(lighten_hex "$C3" 15)

# Convert to RGB for rgba usage
BG_RGB=$(hex_to_rgb "$BG")
C0_RGB=$(hex_to_rgb "$C0")
C1_RGB=$(hex_to_rgb "$C1")
SELECTION_RGB=$(hex_to_rgb "$SELECTION")

echo "Generated colors:"
echo "Background: #$BG -> rgba($BG_RGB)"
echo "Accent: #$ACCENT"
echo "Selection: #$SELECTION -> rgba($SELECTION_RGB)"

# Create wofi style.css
cat >~/.config/wofi/style.css <<EOL
/* ~/.config/wofi/style.css - Auto-generated from colors.css */

window {
    margin: 5px;
    border-radius: 8px;
    background-color: rgba($BG_RGB, 0.9);
    font-family: "Liga SFMono Nerd Font", monospace;
}

#input {
    margin: 8px;
    padding: 10px 12px;
    border: 2px solid #${ACCENT};
    border-radius: 8px;
    color: #${FG};
    background-color: rgba($C0_RGB, 0.8);
    outline: none;
    caret-color: #${C5};
    font-size: 14px;
}

#input:focus {
    border-color: #${C5};
    box-shadow: 0 0 8px rgba($SELECTION_RGB, 0.3);
}

#inner-box {
    margin: 8px;
    padding-top: 5px;
    background-color: transparent;
}

#outer-box {
    margin: 0;
    padding: 5px;
    background-color: transparent;
}

#scroll {
    margin: 0;
    padding: 5px;
}

#text {
    margin: 3px;
    padding: 3px;
    color: #${FG};
    font-size: 13px;
}

#text:selected {
    color: #${C5};
    font-weight: bold;
}

#entry {
    padding: 8px;
    margin: 2px 5px;
    border-radius: 8px;
    transition: all 0.2s ease;
}

#entry:hover {
    background-color: rgba($SELECTION_RGB, 0.2);
}

#entry:selected {
    background-color: rgba($SELECTION_RGB, 0.4);
    box-shadow: 0 2px 6px rgba($SELECTION_RGB, 0.2);
}

#img {
    margin-right: 10px;
    margin-left: 5px;
}

#unselected {
    opacity: 0.85;
}

#urgent {
    background-color: rgba($C1_RGB, 0.3);
    color: #${C1};
    border-left: 3px solid #${C1};
}
EOL

echo "✓ Wofi theme updated successfully with extracted colors"
