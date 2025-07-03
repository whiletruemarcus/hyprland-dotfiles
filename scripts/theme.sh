#!/bin/bash

#===============================================================================
# Theme Synchronization Script
# ~/.config/scripts/theme.sh
# Description: Updates system theme components based on current wallpaper
# Author: saatvik333
# Version: 2.5
# Dependencies: swww, wallust, hyprctl, waybar, dunst, hyprswitch, imagemagick
#===============================================================================

set -euo pipefail

sleep 0.69  # Short delay to ensure script starts cleanly

# --- Configuration ---
readonly SCRIPT_NAME="${0##*/}"
readonly HYPRLOCK_CONF="${HOME}/.config/hypr/hyprlock.conf"
readonly WOFI_SCRIPT="${HOME}/.config/scripts/update-wofi-colors.sh"
readonly WAYBAR_WALLPAPER_DETECTION="${HOME}/.config/scripts/waybar-wallpaper-detection.sh"
readonly GTK_SCRIPT="${HOME}/.config/scripts/update-gtk-colors.sh"
readonly WALLPAPER_CACHE="${HOME}/.config/waytrogen/wallpaper.txt"
readonly LOG_FILE="${HOME}/.cache/${SCRIPT_NAME%.sh}.log"
readonly LOCK_FILE="/tmp/${SCRIPT_NAME%.sh}.lock"
readonly GIF_FRAME="${HOME}/.config/waytrogen/gif-frame.jpg"  # Temporary frame for GIFs

# Global flags
CLEANUP_GIF_FRAME=0
SKIP_WAYBAR_DETECTION=0  # Default to running waybar detection

# --- Logging Functions ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" >&2
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

log_debug() {
    if [[ ${DEBUG:-0} -eq 1 ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $*" | tee -a "$LOG_FILE" >&2
    fi
}

# --- Utility Functions ---
cleanup() {
    local exit_code=$?
    # Clean up temporary GIF frame if needed
    if [[ $CLEANUP_GIF_FRAME -eq 1 && -f "$GIF_FRAME" ]]; then
        rm -f "$GIF_FRAME"
        log "Removed temporary GIF frame: $GIF_FRAME"
    fi

    [[ -f "$LOCK_FILE" ]] && rm -f "$LOCK_FILE"
    log "Script completed with exit code: $exit_code"
    exit $exit_code
}

acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid
        pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            log_error "Another instance is already running (PID: $pid)"
            exit 1
        else
            log "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

validate_dependencies() {
    local missing_deps=()
    local deps=("swww" "wallust" "hyprctl" "sed")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi

    log_debug "All dependencies validated"
    return 0
}

validate_file_executable() {
    local file="$1"
    local description="$2"

    if [[ ! -f "$file" ]]; then
        log_error "$description not found: $file"
        return 1
    fi

    if [[ ! -x "$file" ]]; then
        log_error "$description not executable: $file"
        return 1
    fi

    return 0
}

create_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || {
            log_error "Failed to create directory: $dir"
            return 1
        }
        log_debug "Created directory: $dir"
    fi
}

# --- GIF Handling Functions ---
handle_gif_wallpaper() {
    local gif_path="$1"
    log "Handling GIF wallpaper: $gif_path"

    # Create directory if needed
    create_directory "$(dirname "$GIF_FRAME")" || return 1

    # Extract first frame
    if ! convert "$gif_path[0]" "$GIF_FRAME" &>/dev/null; then
        log_error "Failed to extract first frame from GIF: $gif_path"
        return 1
    fi

    if [[ ! -f "$GIF_FRAME" ]]; then
        log_error "Extracted frame not found: $GIF_FRAME"
        return 1
    fi

    log "Extracted first frame to: $GIF_FRAME"
    CLEANUP_GIF_FRAME=1  # Set flag for cleanup
    echo "$GIF_FRAME"
}

# --- Core Functions ---
get_current_wallpaper() {
    log_debug "Retrieving current wallpaper"

    local wallpaper
    wallpaper=$(swww query 2>/dev/null | grep -oP '(?<=image: ).*' | head -n1 | tr -d '\n\r')

    if [[ -z "$wallpaper" ]]; then
        log_error "No wallpaper detected from swww"
        return 1
    fi

    if [[ ! -f "$wallpaper" ]]; then
        log_error "Wallpaper file does not exist: $wallpaper"
        return 1
    fi

    # Cache original wallpaper path
    create_directory "$(dirname "$WALLPAPER_CACHE")"
    echo "$wallpaper" > "$WALLPAPER_CACHE" || {
        log_error "Failed to cache wallpaper path"
        return 1
    }

    # Handle GIF wallpapers
    if [[ "$wallpaper" =~ \.(gif|GIF)$ ]]; then
        if ! command -v convert &>/dev/null; then
            log_error "ImageMagick required for GIF wallpapers but not installed"
            return 1
        fi
        wallpaper=$(handle_gif_wallpaper "$wallpaper") || return 1
        # Set flag to skip waybar wallpaper detection
        SKIP_WAYBAR_DETECTION=1
    else
        SKIP_WAYBAR_DETECTION=0
    fi

    log "Using wallpaper for colors: $wallpaper"
    echo "$wallpaper"  # Output to stdout only
}


update_hyprlock_config() {
    local wallpaper="$1"

    log_debug "Updating hyprlock configuration"

    if [[ ! -f "$HYPRLOCK_CONF" ]]; then
        log_error "Hyprlock config not found: $HYPRLOCK_CONF"
        return 1
    fi

    # Create backup
    local backup="${HYPRLOCK_CONF}.backup.$(date +%s)"
    cp "$HYPRLOCK_CONF" "$backup" || {
        log_error "Failed to create backup of hyprlock config"
        return 1
    }

    # Update wallpaper path in background section using awk for robust replacement
    local temp_file="${HYPRLOCK_CONF}.tmp"

    if ! awk -v new_path="$wallpaper" '
        /^background {/ { in_bg = 1 }
        in_bg && /^[ \t]*path[ \t]*=/ {
            print "    path = " new_path
            next
        }
        /^}/ && in_bg { in_bg = 0 }
        { print }
    ' "$HYPRLOCK_CONF" > "$temp_file"; then
        log_error "Failed to process hyprlock config with awk"
        rm -f "$temp_file"
        mv "$backup" "$HYPRLOCK_CONF"
        return 1
    fi

    if ! mv "$temp_file" "$HYPRLOCK_CONF"; then
        log_error "Failed to replace hyprlock config"
        rm -f "$temp_file"
        mv "$backup" "$HYPRLOCK_CONF"
        return 1
    fi

    # Remove backup on success
    rm -f "$backup"
    log "Updated hyprlock background configuration"
}

execute_theme_scripts() {
    local wallpaper="$1"

    log_debug "Executing theme update scripts"

    # Skip waybar wallpaper detection for GIFs
    if [[ ${SKIP_WAYBAR_DETECTION:-0} -eq 0 ]]; then
        if validate_file_executable "$WAYBAR_WALLPAPER_DETECTION" "Waybar wallpaper detection script"; then
            log_debug "Executing waybar wallpaper detection"
            # Pass the current wallpaper to the script
            if ! "$WAYBAR_WALLPAPER_DETECTION" "$wallpaper"; then
                log_error "Waybar wallpaper detection script failed"
                return 1
            fi
            log "Waybar wallpaper detection completed"
        else
            return 1
        fi
    else
        log "Skipping waybar wallpaper detection for GIF"
    fi

    # Execute GTK theme update
    if validate_file_executable "$GTK_SCRIPT" "GTK theme script"; then
        log_debug "Executing GTK theme update"
        # Pass the current wallpaper to GTK script
        if ! "$GTK_SCRIPT" "$wallpaper"; then
            log_error "GTK theme script failed"
            return 1
        fi
        log "GTK theme update completed"
    else
        return 1
    fi

    # Execute wallust with dynamic threshold
    log_debug "Executing wallust theme generation with: $wallpaper"

    # Verify wallpaper file exists and is readable
    if [[ ! -r "$wallpaper" ]]; then
        log_error "Wallpaper file not readable: $wallpaper"
        return 1
    fi

    # Get absolute path to ensure wallust can find the file
    local abs_wallpaper
    abs_wallpaper=$(realpath "$wallpaper" 2>/dev/null) || {
        log_error "Failed to resolve absolute path for: $wallpaper"
        return 1
    }

    log_debug "Resolved wallpaper path: $abs_wallpaper"

    if ! wallust run "$abs_wallpaper" --dynamic-threshold 2>&1; then
        log_error "Wallust theme generation failed for: $abs_wallpaper"
        return 1
    fi
    log "Wallust theme generation completed"

    # Execute wofi color update
    if validate_file_executable "$WOFI_SCRIPT" "Wofi color script"; then
        log_debug "Executing wofi color update"
        if ! "$WOFI_SCRIPT"; then
            log_error "Wofi color script failed"
            return 1
        fi
        log "Wofi color update completed"
    else
        return 1
    fi
}

reload_system_components() {
    log_debug "Reloading system components"

    # Reload hyprland configuration
    if ! hyprctl reload 2>/dev/null; then
        log_error "Failed to reload hyprland configuration"
        return 1
    fi
    log "Hyprland configuration reloaded"

    # Reload waybar
    if pgrep -x waybar >/dev/null; then
        if ! killall -SIGUSR2 waybar 2>/dev/null; then
            log_error "Failed to reload waybar"
            return 1
        fi
        log "Waybar reloaded"
    else
        log_debug "Waybar not running, skipping reload"
    fi

    # Restart dunst
    if pgrep -x dunst >/dev/null; then
        log_debug "Stopping existing dunst process"
        killall dunst 2>/dev/null || true
        sleep 0.1
    fi

    log_debug "Starting dunst daemon"
    if command -v dunst >/dev/null 2>&1; then
        # Start dunst in background and capture any immediate errors
        if dunst &>/dev/null & then
            local dunst_pid=$!
            sleep 0.1

            # Check if dunst is still running
            if kill -0 "$dunst_pid" 2>/dev/null; then
                log "Dunst restarted successfully (PID: $dunst_pid)"
            else
                log_error "Dunst process died immediately after start"
                # Try to get error info
                dunst --version >/dev/null 2>&1 || log_error "Dunst binary may be corrupted"
                return 1
            fi
        else
            log_error "Failed to execute dunst command"
            return 1
        fi
    else
        log_error "Dunst command not found in PATH"
        return 1
    fi

    # Restart hyprswitch
    if pgrep -x hyprswitch >/dev/null; then
        log_debug "Stopping existing hyprswitch process"
        killall hyprswitch 2>/dev/null || true
        sleep 0.1
    fi

    log_debug "Starting hyprswitch daemon"
    if command -v hyprswitch >/dev/null 2>&1; then
        local hyprswitch_css="${HOME}/.config/hypr/hyprswitch.css"
        local hyprswitch_cmd

        if [[ -f "$hyprswitch_css" ]]; then
            log_debug "Using custom CSS: $hyprswitch_css"
            hyprswitch_cmd="hyprswitch init --show-title --size-factor 5 --workspaces-per-row 4 --custom-css $hyprswitch_css"
        else
            log_debug "Using default hyprswitch configuration"
            hyprswitch_cmd="hyprswitch init --show-title --size-factor 5 --workspaces-per-row 4"
        fi

        # Start hyprswitch and capture any immediate errors
        if $hyprswitch_cmd &>/dev/null & then
            local hyprswitch_pid=$!
            sleep 0.1

            # Check if hyprswitch is still running
            if kill -0 "$hyprswitch_pid" 2>/dev/null; then
                log "Hyprswitch restarted successfully (PID: $hyprswitch_pid)"
            else
                log_error "Hyprswitch process died immediately after start"
                # Try to get more info about the failure
                if hyprswitch --help &>/dev/null; then
                    log_debug "Hyprswitch binary appears functional"
                else
                    log_error "Hyprswitch binary may have issues"
                fi
                return 1
            fi
        else
            log_error "Failed to execute hyprswitch command: $hyprswitch_cmd"
            return 1
        fi
    else
        log_error "Hyprswitch command not found in PATH"
        return 1
    fi
}

# --- Main Execution ---
main() {
    log "Starting theme synchronization"

    # Setup
    trap cleanup EXIT INT TERM
    acquire_lock

    # Create necessary directories
    create_directory "$(dirname "$LOG_FILE")"
    create_directory "$(dirname "$WALLPAPER_CACHE")"

    # Validate environment
    validate_dependencies || exit 1

    # Get current wallpaper (might be GIF frame)
    local wallpaper
    wallpaper=$(get_current_wallpaper) || exit 1

    # Get original wallpaper path from cache
    local original_wallpaper
    original_wallpaper=$(cat "$WALLPAPER_CACHE")

    # Execute theme update pipeline
    update_hyprlock_config "$original_wallpaper" || exit 1  # Use original path for hyprlock
    execute_theme_scripts "$wallpaper" || exit 1
    reload_system_components || exit 1

    log "Theme synchronization completed successfully"
    notify-send \
    --app-name="Theme Manager" \
    --urgency="normal" \
    --expire-time=4000 \
    --hint="string:desktop-entry:theme-manager" \
    "Theme synchronization completed successfully" \
    "🎨 All components updated\n"
}

# --- Script Entry Point ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
