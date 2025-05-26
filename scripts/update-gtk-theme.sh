#!/bin/bash

# Path to wallpaper config file
WALLPAPER_FILE="$HOME/.config/waytrogen/wallpaper.txt"

# Check if wallpaper file exists
if [ ! -f "$WALLPAPER_FILE" ]; then
    echo "Error: Wallpaper file not found at $WALLPAPER_FILE"
    exit 1
fi

# Read current wallpaper path
CURRENT_WALLPAPER=$(cat "$WALLPAPER_FILE")

# Extract folder name from wallpaper path
FOLDER_NAME=$(echo "$CURRENT_WALLPAPER" | grep -o 'Wallpapers/[^/]*' | cut -d'/' -f2)

# Check if folder name was extracted
if [ -z "$FOLDER_NAME" ]; then
    echo "Error: Could not extract folder name from wallpaper path: $CURRENT_WALLPAPER"
    exit 1
fi

echo "Detected wallpaper folder: $FOLDER_NAME"

# Map folder names to GTK themes
case "$FOLDER_NAME" in
    "Catppuccin")
        THEME_NAME="Colloid-Dark-Catppuccin"
        ;;
    "Everforest")
        THEME_NAME="Colloid-Dark-Everforest"
        ;;
    "Gruvbox")
        THEME_NAME="Colloid-Dark-Gruvbox"
        ;;
    "Nord" | "Onedark")
        THEME_NAME="Colloid-Dark-Nord"
        ;;
    "Black" | "Animated")
        THEME_NAME="Colloid-Dark"
        ;;
    *)
        echo "Warning: No specific theme mapping for folder '$FOLDER_NAME', using default Colloid-Dark"
        THEME_NAME="Colloid-Dark"
        ;;
esac

# Get current GTK theme
CURRENT_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")

# Check if theme needs to be changed
if [ "$CURRENT_THEME" = "$THEME_NAME" ]; then
    echo "Theme is already set to $THEME_NAME"
else
    echo "Changing GTK theme from '$CURRENT_THEME' to '$THEME_NAME'"

    # Set the new GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME_NAME"

    # Also set related theme settings for consistency
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME_NAME"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

    # Set icon theme to match (if you have matching icon themes)
    # gsettings set org.gnome.desktop.interface icon-theme "Your-Icon-Theme"

    # Force GTK3 applications to use dark theme
    export GTK_THEME="$THEME_NAME"

    # Update gtk-3.0 settings file for persistent dark theme preference
    mkdir -p ~/.config/gtk-3.0

    # Update or add gtk-theme-name line
    if [ -f ~/.config/gtk-3.0/settings.ini ]; then
        if grep -q "gtk-theme-name=" ~/.config/gtk-3.0/settings.ini; then
            sed -i "s/gtk-theme-name=.*/gtk-theme-name=$THEME_NAME/" ~/.config/gtk-3.0/settings.ini
        else
            echo "gtk-theme-name=$THEME_NAME" >> ~/.config/gtk-3.0/settings.ini
        fi
    else
        echo "gtk-theme-name=$THEME_NAME" > ~/.config/gtk-3.0/settings.ini
    fi

    # Update or add gtk-application-prefer-dark-theme line
    if grep -q "gtk-application-prefer-dark-theme=" ~/.config/gtk-3.0/settings.ini; then
        sed -i "s/gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=1/" ~/.config/gtk-3.0/settings.ini
    else
        echo "gtk-application-prefer-dark-theme=1" >> ~/.config/gtk-3.0/settings.ini
    fi

    # Update gtk-4.0 settings file
    mkdir -p ~/.config/gtk-4.0
    if ! grep -q "gtk-application-prefer-dark-theme" ~/.config/gtk-4.0/settings.ini 2>/dev/null; then
        echo "gtk-application-prefer-dark-theme=1" >> ~/.config/gtk-4.0/settings.ini
    fi

    # Update xsettingsd configuration
    XSETTINGSD_CONF="$HOME/.config/xsettingsd/xsettingsd.conf"
    if [ -f "$XSETTINGSD_CONF" ]; then
        # Update the Net/ThemeName line
        sed -i "s/Net\/ThemeName \".*\"/Net\/ThemeName \"$THEME_NAME\"/" "$XSETTINGSD_CONF"
        echo "Updated xsettingsd theme configuration"

        # Restart xsettingsd to apply changes
        if pgrep xsettingsd > /dev/null; then
            pkill xsettingsd
            sleep 0.5
            xsettingsd &
            echo "Restarted xsettingsd daemon"
        fi
    else
        echo "Warning: xsettingsd.conf not found at $XSETTINGSD_CONF"
    fi

    # Update GTK2 configuration (.gtkrc-2.0)
    GTKRC_FILE="$HOME/.gtkrc-2.0"
    if [ -f "$GTKRC_FILE" ]; then
        # Update the gtk-theme-name line
        sed -i "s/gtk-theme-name=\".*\"/gtk-theme-name=\"$THEME_NAME\"/" "$GTKRC_FILE"
        echo "Updated GTK2 theme configuration"
    else
        echo "Warning: .gtkrc-2.0 not found at $GTKRC_FILE"
    fi

    # Verify the change
    NEW_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")
    if [ "$NEW_THEME" = "$THEME_NAME" ]; then
        echo "✓ Successfully changed GTK theme to $THEME_NAME"
    else
        echo "✗ Failed to change GTK theme"
        exit 1
    fi
fi
