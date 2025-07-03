#!/bin/bash

#===============================================================================
# GTK Files updation script
# ~/.config/scripts/update-gtk-theme.sh
# Description: Updates GTK themes based on the current wallpaper from specific folders.
# This script reads the current wallpaper path, determines the appropriate GTK theme
# based on the folder structure, and updates the GTK settings accordingly.
# It also manages GTK configuration files, symlinks for assets, and updates xsettingsd.
# Author: saatvik333
# Version: 2.0
# Dependencies: sed gtk3
#===============================================================================

set -euo pipefail
shopt -s nullglob extglob

# --- Configuration Section ---
declare -rg CONFIG_DIR="$HOME/.config"
declare -rg WALLPAPER_FILE="$CONFIG_DIR/waytrogen/wallpaper.txt"
declare -rgA THEME_MAP=(
    ["Catppuccin"]="Colloid-Dark-Catppuccin"
    ["Everforest"]="Colloid-Dark-Everforest"
    ["Gruvbox"]="Colloid-Dark-Gruvbox"
    ["Nord"]="Colloid-Dark-Nord"
    ["Onedark"]="Colloid-Dark-Dracula"
    ["Black"]="Colloid-Dark"
    ["Animated"]="Colloid-Dark"
)
declare -rg DEFAULT_THEME="Colloid-Dark"
declare -rg COLOR_SCHEME="prefer-dark"
declare -rg GTK_VERSIONS=("3.0" "4.0")

# --- Utility Functions ---
die() { echo -e "\033[1;31mERROR: $*\033[0m" >&2; exit 1; }
log_info() { echo -e "\033[1;34mINFO: $*\033[0m"; }
log_warn() { echo -e "\033[1;33mWARN: $*\033[0m"; }

file_exists() { [[ -f "$1" ]] || die "File not found: $1"; }
dir_exists() { [[ -d "$1" ]] || die "Directory not found: $1"; }

# --- Core Functions ---
get_wallpaper_folder() {
    file_exists "$WALLPAPER_FILE"
    local wallpaper_path
    wallpaper_path=$(<"$WALLPAPER_FILE") || die "Failed to read wallpaper file"
    [[ "$wallpaper_path" =~ Wallpapers/([^/]+)/ ]] || die "Invalid wallpaper path pattern"
    echo "${BASH_REMATCH[1]}"
}

resolve_theme_name() {
    local folder="${1:-}"
    [[ -z "$folder" ]] && { echo "$DEFAULT_THEME"; return; }
    echo "${THEME_MAP["$folder"]:-$DEFAULT_THEME}"
}

verify_theme_installation() {
    local theme="${1:?Theme name required}"
    local paths=(
        "$HOME/.themes/$theme"
        "$HOME/.local/share/themes/$theme"
        "/usr/share/themes/$theme"
    )

    for path in "${paths[@]}"; do
        [[ -d "$path" ]] && return 0
    done
    die "Theme not installed: '$theme'"
}

update_gtk_settings() {
    local theme=$1
    gsettings set org.gnome.desktop.interface gtk-theme "$theme"
    gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME"
}

manage_gtk_config() {
    local version=$1 theme=$2 config_file="$CONFIG_DIR/gtk-$version/settings.ini"
    mkdir -p "$(dirname "$config_file")"

    set_ini_value "$config_file" "Settings" "gtk-theme-name" "$theme"
    set_ini_value "$config_file" "Settings" "gtk-application-prefer-dark-theme" "1"
}

set_ini_value() {
    local file=$1 section=$2 key=$3 value=$4
    file_exists "$file" || touch "$file"

    if grep -q "^\[$section\]" "$file"; then
        if grep -q "^$key=" "$file"; then
            sed -i "/^\[$section\]/,/^\[/ s/^$key=.*/$key=$value/" "$file"
        else
            sed -i "/^\[$section\]/a $key=$value" "$file"
        fi
    else
        printf '\n[%s]\n%s=%s\n' "$section" "$key" "$value" >> "$file"
    fi
}

manage_symlinks() {
    local theme=$1 target_dir gtk4_dir="$CONFIG_DIR/gtk-4.0"
    declare -A links=(
        ["$gtk4_dir/gtk.css"]="gtk-4.0/gtk.css"
        ["$gtk4_dir/gtk-dark.css"]="gtk-4.0/gtk-dark.css"
        ["$gtk4_dir/assets"]="gtk-4.0/assets"
        ["$CONFIG_DIR/assets"]="assets"
    )

    for path in "$HOME/.themes/$theme" "$HOME/.local/share/themes/$theme" "/usr/share/themes/$theme"; do
        [[ -d "$path" ]] && { target_dir="$path"; break; }
    done || die "Theme assets not found: $theme"

    for link in "${!links[@]}"; do
        local target="$target_dir/${links[$link]}"
        [[ -e "$target" ]] || continue

        ln -sf "$target" "$link" && log_info "Created symlink: ${link##*/}"
    done
}

update_xsettingsd() {
    local theme=$1 config_file="$CONFIG_DIR/xsettingsd/xsettingsd.conf"
    file_exists "$config_file" || return

    sed -i "s/Net\/ThemeName \".*\"/Net\/ThemeName \"$theme\"/" "$config_file"
}

# --- Main Execution ---
current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")
wallpaper_folder=$(get_wallpaper_folder)
target_theme=$(resolve_theme_name "$wallpaper_folder")

[[ -n "$target_theme" ]] || die "Failed to resolve theme name"

[[ "$current_theme" == "$target_theme" ]] && exit 0

verify_theme_installation "$target_theme"
update_gtk_settings "$target_theme"


for version in "${GTK_VERSIONS[@]}"; do
    manage_gtk_config "$version" "$target_theme"
done

manage_symlinks "$target_theme"
update_xsettingsd "$target_theme"

# Final verification
new_theme=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")
[[ "$new_theme" == "$target_theme" ]] || die "Theme verification failed"

log_info "Theme updated to $target_theme"
exit 0
