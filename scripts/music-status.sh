#!/bin/bash

# Minimal music status script for hyprlock
# Provides clean, aesthetic output for currently playing music

get_music_info() {
    # Check if playerctl is installed
    if ! command -v playerctl &> /dev/null; then
        echo ""
        return
    fi

    # Get list of active players
    players=$(playerctl -l 2>/dev/null)

    if [ -z "$players" ]; then
        echo ""
        return
    fi

    # Try to find an active player that's playing something
    for player in $players; do
        status=$(playerctl -p "$player" status 2>/dev/null)

        if [ "$status" = "Playing" ]; then
            active_player=$player
            break
        elif [ "$status" = "Paused" ] && [ -z "$active_player" ]; then
            active_player=$player
        fi
    done

    # If no active player was found
    if [ -z "$active_player" ]; then
        echo ""
        return
    fi

    # Get track information
    title=$(playerctl -p "$active_player" metadata title 2>/dev/null || echo "")
    artist=$(playerctl -p "$active_player" metadata artist 2>/dev/null || echo "")
    status=$(playerctl -p "$active_player" status 2>/dev/null || echo "")

    # Return empty if no title
    if [ -z "$title" ]; then
        echo ""
        return
    fi

    # Truncate long titles and artists
    if [ ${#title} -gt 30 ]; then
        title="${title:0:27}..."
    fi

    if [ ${#artist} -gt 20 ]; then
        artist="${artist:0:17}..."
    fi

    # Set status icon (minimal)
    if [ "$status" = "Playing" ]; then
        icon="󰎇"
    else
        icon="◦"
    fi

    # Output formatted info (minimal aesthetic)
    if [ -n "$artist" ]; then
        echo "$icon $artist · $title"
    else
        echo "$icon $title"
    fi
}

# Execute the function
get_music_info
