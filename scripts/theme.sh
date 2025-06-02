#!/bin/bash

#===============================================================================
# Theme Synchronization Script
# ~/.config/scripts/theme.sh
# Description: Updates system theme components based on current wallpaper
# Author: saatvik333
# Version: 2.0
# Dependencies: swww, wallust, hyprctl, waybar, dunst, hyprswitch
#===============================================================================

set -euo pipefail

sleep 0.2  # Short delay to ensure script starts cleanly

# --- Configuration ---
readonly SCRIPT_NAME="${0##*/}"
readonly HYPRLOCK_CONF="${HOME}/.config/hypr/hyprlock.conf"
readonly WOFI_SCRIPT="${HOME}/.config/scripts/update-wofi-colors.sh"
readonly WAYBAR_WALLPAPER_DETECTION="${HOME}/.config/scripts/waybar-wallpaper-detection.sh"
readonly GTK_SCRIPT="${HOME}/.config/scripts/update-gtk-colors.sh"
readonly WALLPAPER_CACHE="${HOME}/.config/waytrogen/wallpaper.txt"
readonly LOG_FILE="${HOME}/.cache/${SCRIPT_NAME%.sh}.log"
readonly LOCK_FILE="/tmp/${SCRIPT_NAME%.sh}.lock"

# --- Logging Functions ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

log_debug() {
    if [[ ${DEBUG:-0} -eq 1 ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $*" | tee -a "$LOG_FILE"
    fi
}

# --- Utility Functions ---
cleanup() {
    local exit_code=$?
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

# --- Core Functions ---
get_current_wallpaper() {
    log_debug "Retrieving current wallpaper" >&2

    local wallpaper
    wallpaper=$(swww query 2>/dev/null | grep -oP '(?<=image: ).*' | head -n1 | tr -d '\n\r')

    if [[ -z "$wallpaper" ]]; then
        log_error "No wallpaper detected from swww" >&2
        return 1
    fi

    if [[ ! -f "$wallpaper" ]]; then
        log_error "Wallpaper file does not exist: $wallpaper" >&2
        return 1
    fi

    # Cache wallpaper path
    create_directory "$(dirname "$WALLPAPER_CACHE")" >&2
    echo "$wallpaper" > "$WALLPAPER_CACHE" || {
        log_error "Failed to cache wallpaper path" >&2
        return 1
    }

    log "Current wallpaper: $wallpaper" >&2
    printf '%s' "$wallpaper"
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

    # Execute waybar wallpaper detection
    if validate_file_executable "$WAYBAR_WALLPAPER_DETECTION" "Waybar wallpaper detection script"; then
        log_debug "Executing waybar wallpaper detection"
        if ! "$WAYBAR_WALLPAPER_DETECTION"; then
            log_error "Waybar wallpaper detection script failed"
            return 1
        fi
        log "Waybar wallpaper detection completed"
    else
        return 1
    fi

    # Execute GTK theme update
    if validate_file_executable "$GTK_SCRIPT" "GTK theme script"; then
        log_debug "Executing GTK theme update"
        if ! "$GTK_SCRIPT"; then
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

    # Get current wallpaper
    local wallpaper
    if ! wallpaper=$(get_current_wallpaper); then
        exit 1
    fi

    # Execute theme update pipeline
    update_hyprlock_config "$wallpaper" || exit 1
    execute_theme_scripts "$wallpaper" || exit 1
    reload_system_components || exit 1

    log "Theme synchronization completed successfully"
}

# --- Script Entry Point ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
