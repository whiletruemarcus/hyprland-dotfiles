#!/usr/bin/env bash
# ~/.config/dunst/update-dunst-colors.sh
# Dynamic Dunst config updater with pywal integration

# Enable strict error checking
set -eo pipefail

# Load pywal color environment
WAL_CACHE="$HOME/.cache/wal"
if [[ ! -f "$WAL_CACHE/colors.sh" ]]; then
    echo "Error: Pywal colors not found!" >&2
    exit 1
fi
source "$WAL_CACHE/colors.sh"

# Dunst configuration paths
DUNST_CONF="$HOME/.config/dunst/dunstrc"
DUNST_BACKUP="${DUNST_CONF}.bak"

# Create backup with timestamp
backup_config() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    cp -f "$DUNST_CONF" "${DUNST_BACKUP}.${timestamp}"
}

# Color transformation functions
apply_alpha() {
    echo "${1}${2:-aa}" # Default to alpha=aa (170/255)
}

generate_gradient() {
    echo "vertical gradient ${1} ${2}"
}

# Main update function
update_dunst_colors() {
    # Create temporary working file
    local temp_file=$(mktemp)

    # Process config with updated colors
    sed -E "
        # Global section updates
        /^\[global\]/,/^\[/ {
            s/(frame_color = \").*(\")/\1${color4}\2/;
            s/(progress_bar_color = \").*(\")/\1${color5}\2/;
            s/(separator_color = \").*(\")/\1${foreground}80\2/;
            s/(icon_path = \").*(\")/\1\/usr\/share\/icons\/Papirus-Dark\/24x24\/apps\/:\/home\/$USER\/.icons\/\2/;
        }

        # Urgency levels
        /^\[urgency_low\]/,/^\[/ {
            s/(background = \").*(\")/\1$(apply_alpha "$background" "80")\2/;
            s/(foreground = \").*(\")/\1${foreground}\2/;
            s/(frame_color = \").*(\")/\1${color4}\2/;
        }

        /^\[urgency_normal\]/,/^\[/ {
            s/(background = \").*(\")/\1$(apply_alpha "$background" "cc")\2/;
            s/(foreground = \").*(\")/\1${foreground}\2/;
            s/(frame_color = \").*(\")/\1${color2}\2/;
            s/(progress_bar_color = \").*(\")/\1${color6}\2/;
        }

        /^\[urgency_critical\]/,/^\[/ {
            s/(background = \").*(\")/\1${color1}\2/;
            s/(foreground = \").*(\")/\1${background}\2/;
            s/(frame_color = \").*(\")/\1${color9}\2/;
        }
    " "$DUNST_CONF" > "$temp_file"

    # Replace original config
    mv -f "$temp_file" "$DUNST_CONF"
}

# Main execution flow
main() {
    # backup_config
    update_dunst_colors

    # Graceful Dunst restart
    if pgrep dunst >/dev/null; then
        killall dunst && dunst & disown
    else
        dunst & disown
    fi

    echo "Dunst configuration successfully updated with pywal colors!"
    notify-send -u low "Dunst Updated" "Notification theme reloaded" -i preferences-desktop-theme
}

# Run main function with error trapping
trap 'echo "Error on line $LINENO"; exit 1' ERR
main
