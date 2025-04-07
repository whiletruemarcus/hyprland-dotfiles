#!/bin/bash
WALLPAPER_DIR="/home/saatvik333/Pictures/Wallpapers"
HACKER_THEME="/home/saatvik333/.config/wal/colorschemes/dark/hacker.json"
MATRIX_BLACK_PATH="/home/saatvik333/Pictures/Wallpapers/127.0.0.1.png"

# Create temporary mapping file with relative paths
tmpfile=$(mktemp)
find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) -exec sh -c '
    file="{}"
    rel_path="${file#'"$WALLPAPER_DIR/"'}"
    echo "$rel_path|$file"
' \; > "$tmpfile"

# Launch wofi with formatted paths
SELECTED_REL_PATH=$(awk -F'|' '{print $1}' "$tmpfile" | wofi -d -p "Select a wallpaper: ")

# Clean exit if no selection
if [ -z "$SELECTED_REL_PATH" ]; then
    rm "$tmpfile"
    exit 1
fi

# Get full path from selection
WALLPAPER=$(awk -F'|' -v selected="$SELECTED_REL_PATH" '$1 == selected {print $2; exit}' "$tmpfile")
rm "$tmpfile"

# Validate path resolution
if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    echo "Error: Invalid wallpaper selection"
    exit 1
fi

# Update hyprpaper
echo "preload = $WALLPAPER" > ~/.config/hypr/hyprpaper.conf
echo "wallpaper = ,$WALLPAPER" >> ~/.config/hypr/hyprpaper.conf
hyprctl hyprpaper preload "$WALLPAPER"
hyprctl hyprpaper wallpaper ",$WALLPAPER"

# Define the waybar directory paths
WAYBAR_DIR="$HOME/.config/waybar"
WAYBAR_TEMP_DIR="$WAYBAR_DIR/temp"
WAYBAR_STYLE="$WAYBAR_DIR/style.css"
WAYBAR_STYLE_PYWAL="$WAYBAR_TEMP_DIR/style-pywal.css"
WAYBAR_STYLE_DEFAULT="$WAYBAR_TEMP_DIR/style-default.css"

# Define Hyprland config path
HYPRLAND_CONF="$HOME/.config/hypr/hyprland.conf"

# Apply theme
if [ "$WALLPAPER" == "$MATRIX_BLACK_PATH" ]; then
    wal --theme "$HACKER_THEME"

    # For hacker theme: Move style-pywal.css to style.css and backup default
    if [ -f "$WAYBAR_STYLE_PYWAL" ] && [ -f "$WAYBAR_STYLE" ]; then
        # Backup current style.css if it's not already backed up
        if [ ! -f "$WAYBAR_STYLE_DEFAULT" ]; then
            mv "$WAYBAR_STYLE" "$WAYBAR_STYLE_DEFAULT"
        else
            rm "$WAYBAR_STYLE"
        fi
        # Move pywal style to main location
        cp "$WAYBAR_STYLE_PYWAL" "$WAYBAR_STYLE"
    fi

    # Change Hyprland border_size to 2 for hacker theme
    sed -i 's/^general {/general {\n    border_size = 2/g' "$HYPRLAND_CONF"
    sed -i 's/^[ \t]*border_size[ \t]*=[ \t]*[0-9]\+/    border_size = 2/g' "$HYPRLAND_CONF"

    # Reload Hyprland config
    hyprctl reload
    killall -SIGUSR2 waybar
else
    wal -i "$WALLPAPER"

    # For other themes: Restore the default style if it exists
    if [ -f "$WAYBAR_STYLE_DEFAULT" ]; then
        rm -f "$WAYBAR_STYLE"
        cp "$WAYBAR_STYLE_DEFAULT" "$WAYBAR_STYLE"
    fi

    # Change Hyprland border_size back to 0 for other themes
    sed -i 's/^[ \t]*border_size[ \t]*=[ \t]*[0-9]\+/    border_size = 0/g' "$HYPRLAND_CONF"

    # Reload Hyprland config
    hyprctl reload
    killall -SIGUSR2 waybar
fi
# Update system components
source ~/.cache/wal/colors.sh
source ~/.config/scripts/update-wofi-colors.sh
source ~/.config/scripts/update-dunst-colors.sh
ping www.google.com
# Reload waybar
