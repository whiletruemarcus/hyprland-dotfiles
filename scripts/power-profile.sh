#!/bin/bash

# Declare an associative array mapping menu names to power profile keys.
declare -A PROFILES=(
    ["Performance"]="performance"
    ["Balanced"]="balanced"
    ["Power Saver"]="power-saver"
)

current=$(powerprofilesctl get)

# Build menu options from the associative array keys.
menu=$(printf "%s\n" "${!PROFILES[@]}")

# Prompt using wofi.
selected=$(echo "$menu" | wofi --dmenu \
    --prompt "Power Profile [Current: ${current^}]" \
    --height 250 --width 400 --hide-scroll --insensitive)

# Convert selected value to proper profile key.
profile="${PROFILES[$selected]}"

if [[ -n "$profile" ]]; then
    powerprofilesctl set "$profile"
else
    echo "Invalid selection: $selected" >&2
fi
