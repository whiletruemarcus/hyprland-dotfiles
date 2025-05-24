#!/bin/bash

HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
WOFI_SCRIPT="$HOME/.config/scripts/update-wofi-colors.sh"

sleep 0.2
# --- Functions ---
current_wallpaper() {
    wallpaper=$(swww query | grep -oP '(?<=image: ).*')

    echo "$wallpaper" > "$HOME/.config/waytrogen/wallpaper.txt"
    echo "$wallpaper"
}

update_hyprlock() {
    local wallpaper="$1"

    # Check if hyprlock.conf exists
    if [ ! -f "$HYPRLOCK_CONF" ]; then
        echo "Error: Hyprlock config not found at $HYPRLOCK_CONF"
        return 1
    fi

    # Update the path in the background section
    sed -i '/^background {/,/^}/ s|^[ \t]*path[ \t]*=[ \t]*.*|    path = '"$wallpaper"'|' "$HYPRLOCK_CONF"

    echo "Updated Hyprlock background to: $wallpaper"
}

apply_theme() {
    local wallpaper="$1"

    # Sets the theme using wallust templates
    wallust run $wallpaper

    # Execute the Wofi script to update colors
    if [ -x "$WOFI_SCRIPT" ]; then
        "$WOFI_SCRIPT"
    else
        echo "Error: Wofi script not found or not executable at $WOFI_SCRIPT"
        return 1
    fi
}

reload_components() {
    hyprctl reload
    sleep 0.05
    killall -SIGUSR2 waybar
    sleep 0.05
    killall dunst
    sleep 0.05
    dunst & disown

    echo "Successfully updated dunst colors!"
}

WALLPAPER=$(current_wallpaper)
if [ -z "$WALLPAPER" ]; then
    echo "No wallpaper found. Please set a wallpaper first."
    return 1
fi
update_hyprlock "$WALLPAPER"
apply_theme "$WALLPAPER"
reload_components
if [ $? -eq 0 ]; then
    echo "Theme applied successfully!"
else
    echo "Failed to apply theme."
    exit 1
fi
