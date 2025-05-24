#!/bin/bash

# Configuration
volume_step=5
brightness_step=5
max_volume=100
notification_timeout=1000 # In milliseconds
download_album_art=false
show_album_art=false
show_music_in_volume_indicator=true

# --- Volume Control ---
function get_volume {
    pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]{1,3}(?=%)' | head -1
}

function get_mute {
    pactl get-sink-mute @DEFAULT_SINK@ | grep -Po '(?<=Mute: )(yes|no)'
}

function get_volume_icon {
    local vol=$(get_volume)
    local mute_status=$(get_mute)
    if [ "$mute_status" == "yes" ] || [ "$vol" -eq 0 ]; then
        volume_icon="󰕿" # U+F6A9 notification-sound-slash / nf-mdi-volume_mute
    elif [ "$vol" -lt 50 ]; then
        volume_icon="󰖀" # U+F027 notification-sound-low / nf-mdi-volume_low
    else
        volume_icon="󰕾" # U+F028 notification-sound-high / nf-mdi-volume_high
    fi
}

function show_volume_notif {
    local volume_val=$(get_volume)
    local mute_status=$(get_mute)
    get_volume_icon  # This sets $volume_icon based on mute status and volume

    # Determine notification content based on mute status
    local body_text
    local progress_value
    if [ "$mute_status" == "yes" ] || [ "$volume_val" -eq 0 ]; then
        body_text="$volume_icon Muted"
        progress_value=0
    else
        body_text="$volume_icon $volume_val%"
        progress_value=$volume_val
    fi

    # Rest of the notification logic
    local summary_text=""
    local app_name="Volume"

    if [[ $show_music_in_volume_indicator == "true" ]]; then
        current_song=$(playerctl -f "{{title}} - {{artist}}" metadata 2>/dev/null || echo "")
        if [[ -n "$current_song" ]]; then
             body_text="$body_text  $current_song"
        fi
        if [[ $show_album_art == "true" ]] && [[ -n "$current_song" ]]; then
            get_album_art
        else
            album_art=""
        fi
        notify-send -a "$app_name" -t $notification_timeout \
            -h string:x-dunst-stack-tag:volume_notif \
            -h int:value:$progress_value \
            -h string:hlcolor:#ffffff \
            -i "$album_art" "$summary_text" "$body_text"
    else
        notify-send -a "$app_name" -t $notification_timeout \
            -h string:x-dunst-stack-tag:volume_notif \
            -h int:value:$progress_value \
            -h string:hlcolor:#ffffff \
            "$summary_text" "$body_text"
    fi
}

# --- Microphone Mute Control ---
function get_mic_mute {
    pactl get-source-mute @DEFAULT_SOURCE@ | grep -Po '(?<=Mute: )(yes|no)'
}

function get_mic_icon {
    local mic_mute_status=$(get_mic_mute)
    if [ "$mic_mute_status" == "yes" ]; then
        mic_icon="󰍭"
    else
        mic_icon="󰍬"
    fi
}

function show_mic_mute_notif {
    get_mic_icon
    local mic_mute_status=$(get_mic_mute)
    local status_text
    if [ "$mic_mute_status" == "yes" ]; then
        status_text="Muted"
    else
        status_text="Unmuted"
    fi
    notify-send -a "Microphone" -t $notification_timeout -h string:x-dunst-stack-tag:mic_mute_notif "" "$mic_icon Microphone $status_text"
}

# --- Brightness Control ---
function get_brightness {
    # brightnessctl version 0.6 changed output of -m.
    # This tries to be compatible with both by checking for '%' which is in new, not old.
     brightnessctl g | xargs -I{} expr {} \* 100 / $(brightnessctl m)

}

function get_brightness_icon {
    local brightness=$(get_brightness)
    if [ "$brightness" -lt 33 ]; then
        brightness_icon="󰃞" # Low brightness icon
    elif [ "$brightness" -lt 66 ]; then
        brightness_icon="󰃟" # Medium brightness icon
    else
        brightness_icon="󰃠" # High brightness icon
    fi
}

function show_brightness_notif {
    local brightness_val=$(get_brightness)
    get_brightness_icon
    notify-send -a "Brightness" -t $notification_timeout -h string:x-dunst-stack-tag:brightness_notif -h string:hlcolor:#ffffff -h int:value:$brightness_val "" "$brightness_icon $brightness_val%"
}

# --- Music Control ---
# Global variable for album art path, set by get_album_art
album_art=""

function get_album_art {
    album_art="" # Reset before attempting to fetch
    local art_url=$(playerctl -f "{{mpris:artUrl}}" metadata 2>/dev/null)

    if [[ -z "$art_url" ]]; then
        return
    fi

    if [[ $art_url == "file://"* ]]; then
        album_art="${art_url/file:\/\//}"
    elif [[ ($art_url == "http://"* || $art_url == "https://"* ) && $download_album_art == "true" ]]; then
        # Sanitize filename: allow alphanumeric, dot, underscore, hyphen. Replace others.
        local filename_unsafe=$(basename "$art_url")
        local filename_safe=$(echo "$filename_unsafe" | sed 's/[^a-zA-Z0-9._-]//g')

        # Add a generic extension if none is apparent, helps some viewers
        if [[ ! "$filename_safe" == *.* ]]; then
            filename_safe="${filename_safe}.jpg"
        fi

        if [[ -n "$filename_safe" ]]; then
            local temp_art_path="/tmp/$filename_safe"
            # Check if file exists and is not too old (e.g. 1 day) to avoid redownloading constantly for dynamic URLs
            if [ ! -f "$temp_art_path" ] || [[ $(find "$temp_art_path" -mtime +1 -print) ]]; then
                wget --quiet -O "$temp_art_path" "$art_url"
            fi
            if [ -f "$temp_art_path" ] && [ -s "$temp_art_path" ]; then # Check if file exists and is not empty
                 album_art="$temp_art_path"
            else # Wget failed or file empty
                 album_art=""
            fi
        fi
    fi
}


function show_music_notif {
    local song_title=$(playerctl -f "{{title}}" metadata 2>/dev/null || echo "")
    local song_artist=$(playerctl -f "{{artist}}" metadata 2>/dev/null || echo "")
    local song_album=$(playerctl -f "{{album}}" metadata 2>/dev/null || echo "")

    if [[ -z "$song_title" && -z "$song_artist" ]]; then
      return
    fi

    local summary_text="$song_title"
    local body_text="$song_artist"
    if [[ -n "$song_album" ]]; then
        body_text="$body_text - $song_album"
    fi

    # Explicitly reset album_art before calling get_album_art
    album_art=""
    if [[ $show_album_art == "true" ]]; then
        get_album_art # Sets global album_art variable
    fi

    # Use the global album_art variable which is set by get_album_art
    notify-send -a "Music Player" -t $notification_timeout -h string:x-dunst-stack-tag:music_notif -i "$album_art" "$summary_text" "$body_text"
}


# --- Main Script Logic ---
case $1 in
    volume_up)
    pactl set-sink-mute @DEFAULT_SINK@ 0
    current_volume=$(get_volume)
    if [ $(( "$current_volume" + "$volume_step" )) -gt $max_volume ]; then
        pactl set-sink-volume @DEFAULT_SINK@ $max_volume%
    else
        pactl set-sink-volume @DEFAULT_SINK@ +$volume_step%
    fi
    show_volume_notif
    ;;

    volume_down)
    pactl set-sink-volume @DEFAULT_SINK@ -$volume_step%
    show_volume_notif
    ;;

    volume_mute)
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    show_volume_notif
    ;;

    mic_mute)
    pactl set-source-mute @DEFAULT_SOURCE@ toggle
    show_mic_mute_notif
    ;;

    brightness_up)
    brightnessctl set $brightness_step%+
    show_brightness_notif
    ;;

    brightness_down)
    brightnessctl set $brightness_step%-
    show_brightness_notif
    ;;

    next_track)
    playerctl next
    sleep 0.2 # Allow player to update before fetching metadata
    show_music_notif
    ;;

    prev_track)
    playerctl previous
    sleep 0.2
    show_music_notif
    ;;

    play_pause)
    playerctl play-pause
    sleep 0.1 # Short delay for metadata update
    show_music_notif
    ;;
    *)
    echo "Usage: $0 {volume_up|volume_down|volume_mute|mic_mute|brightness_up|brightness_down|next_track|prev_track|play_pause}"
    exit 1
    ;;
esac
