#!/bin/bash

HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
WOFI_SCRIPT="$HOME/.config/scripts/update-wofi-colors.sh"
WAYBAR_WALLPAPER_DETECTION="$HOME/.config/scripts/waybar-wallpaper-detection.sh"
GTK_SCRIPT="$HOME/.config/scripts/update-gtk-theme.sh"

sleep 0.3
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

    # Check the waybar region to adjust colors automatically
    if [ -x "$WAYBAR_WALLPAPER_DETECTION" ]; then
        "$WAYBAR_WALLPAPER_DETECTION"
    else
        echo "Error: Waybar wallpaper detection script not found or not executable at $WAYBAR_WALLPAPER_DETECTION"
        return 1
    fi

    # Update GTK theme
    if [ -x "$GTK_SCRIPT" ]; then
        "$GTK_SCRIPT"
    else
        echo "Error: GTK theme update script not found or not executable at $GTK_SCRIPT"
        return 1
    fi

    # Sets the theme using wallust templates
    wallust run $wallpaper --dynamic-threshold

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
    sleep 0.1
    killall -SIGUSR2 waybar
    sleep 0.1
    killall dunst
    sleep 0.1
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
