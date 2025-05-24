#!/bin/bash
# ~/.config/scripts/update-wofi-colors.sh

# Make sure the config directory exists
mkdir -p ~/.config/wofi

# Extract all colors from pywal
BACKGROUND=$(grep -o -- "--background: #[0-9a-fA-F]\+" ~/.config/wofi/colors.css | cut -d '#' -f2)
FOREGROUND=$(grep -o -- "--foreground: #[0-9a-fA-F]\+" ~/.config/wofi/colors.css | cut -d '#' -f2)
COLOR0=$(grep -o -- "--color0: #[0-9a-fA-F]\+" ~/.config/wofi/colors.css | cut -d '#' -f2)
COLOR1=$(grep -o -- "--color1: #[0-9a-fA-F]\+" ~/.config/wofi/colors.css | cut -d '#' -f2)
COLOR2=$(grep -o -- "--color2: #[0-9a-fA-F]\+" ~/.config/wofi/colors.css | cut -d '#' -f2)
COLOR3=$(grep -o -- "--color3: #[0-9a-fA-F]\+" ~/.config/wofi/colors.css | cut -d '#' -f2)
COLOR4=$(grep -o -- "--color4: #[0-9a-fA-F]\+" ~/.config/wofi/colors.css | cut -d '#' -f2)
COLOR5=$(grep -o -- "--color5: #[0-9a-fA-F]\+" ~/.config/wofi/colors.css | cut -d '#' -f2)
COLOR6=$(grep -o -- "--color6: #[0-9a-fA-F]\+" ~/.config/wofi/colors.css | cut -d '#' -f2)
COLOR7=$(grep -o -- "--color7: #[0-9a-fA-F]\+" ~/.config/wofi/colors.css | cut -d '#' -f2)
COLOR8=$(grep -o -- "--color8: #[0-9a-fA-F]\+" ~/.config/wofi/colors.css | cut -d '#' -f2)
COLOR9=$(grep -o -- "--color9: #[0-9a-fA-F]\+" ~/.config/wofi/colors.css | cut -d '#' -f2)

# If any color is empty, use default values from your previous output
if [ -z "$BACKGROUND" ]; then BACKGROUND="1e1d1c"; fi
if [ -z "$FOREGROUND" ]; then FOREGROUND="e5e0cf"; fi
if [ -z "$COLOR0" ]; then COLOR0="1e1d1c"; fi
if [ -z "$COLOR1" ]; then COLOR1="928B78"; fi
if [ -z "$COLOR2" ]; then COLOR2="A0967F"; fi
if [ -z "$COLOR3" ]; then COLOR3="9F9B86"; fi
if [ -z "$COLOR4" ]; then COLOR4="B3AC91"; fi
if [ -z "$COLOR5" ]; then COLOR5="C4BB9D"; fi
if [ -z "$COLOR6" ]; then COLOR6="BAC0A6"; fi
if [ -z "$COLOR7" ]; then COLOR7="e5e0cf"; fi
if [ -z "$COLOR8" ]; then COLOR8="a09c90"; fi
if [ -z "$COLOR9" ]; then COLOR9="928B78"; fi

# RGB color conversion function for rgba
hex_to_rgb() {
    hex=$1
    r=$(printf '0x%0.2s' "$hex")
    g=$(printf '0x%0.2s' "${hex#??}")
    b=$(printf '0x%0.2s' "${hex#????}")
    echo "$((r)),$((g)),$((b))"
}

# Lighten a hex color by percentage
lighten_color() {
    hex=$1
    percent=$2

    r=$(printf '0x%0.2s' "$hex")
    g=$(printf '0x%0.2s' "${hex#??}")
    b=$(printf '0x%0.2s' "${hex#????}")

    # Calculate the new values
    r=$(( r + (255 - r) * percent / 100 ))
    g=$(( g + (255 - g) * percent / 100 ))
    b=$(( b + (255 - b) * percent / 100 ))

    # Ensure values are in range
    r=$(( r > 255 ? 255 : r ))
    g=$(( g > 255 ? 255 : g ))
    b=$(( b > 255 ? 255 : b ))

    printf "%02x%02x%02x" "$r" "$g" "$b"
}

# Darken a hex color by percentage
darken_color() {
    hex=$1
    percent=$2

    r=$(printf '0x%0.2s' "$hex")
    g=$(printf '0x%0.2s' "${hex#??}")
    b=$(printf '0x%0.2s' "${hex#????}")

    # Calculate the new values
    r=$(( r - r * percent / 100 ))
    g=$(( g - g * percent / 100 ))
    b=$(( b - b * percent / 100 ))

    # Ensure values are in range
    r=$(( r < 0 ? 0 : r ))
    g=$(( g < 0 ? 0 : g ))
    b=$(( b < 0 ? 0 : b ))

    printf "%02x%02x%02x" "$r" "$g" "$b"
}

# Generate accent colors based on existing colors
ACCENT=$(lighten_color "$COLOR4" 10)
ACCENT_DARK=$(darken_color "$COLOR4" 10)
HIGHLIGHT=$(lighten_color "$COLOR5" 5)
SELECTION_BG=$(lighten_color "$COLOR3" 5)

# Debug output
echo "Extracted and generated colors:"
echo "BACKGROUND: #$BACKGROUND"
echo "FOREGROUND: #$FOREGROUND"
echo "ACCENT: #$ACCENT"
echo "ACCENT_DARK: #$ACCENT_DARK"
echo "HIGHLIGHT: #$HIGHLIGHT"
echo "SELECTION_BG: #$SELECTION_BG"

# Create or update the wofi style.css
cat > ~/.config/wofi/style.css << EOL
/* ~/.config/wofi/style.css */
@import url("./colors.css");

/* Base styling */
window {
    margin: 5px;
    border-radius: 8px;
    background-color: rgba($(hex_to_rgb "$BACKGROUND"), 0.9);
    font-family: "SFMono Nerd Font Mono";
}

/* Search input styling */
#input {
    margin: 8px;
    padding: 8px 12px;
    border: 2px solid #${ACCENT};
    border-radius: 8px;
    color: var(--foreground);
    background-color: rgba($(hex_to_rgb "$COLOR0"), 0.7);
    outline: none;
    caret-color: #${HIGHLIGHT};
}

#input:focus {
    border-color: #${HIGHLIGHT};
}

/* Container styling */
#inner-box {
    margin: 8px;
    border: none;
    background-color: transparent;
    padding-top: 5px;
}

#outer-box {
    margin: 0px;
    border: none;
    background-color: transparent;
    padding: 5px;
}

#scroll {
    margin: 0px;
    border: none;
    padding: 5px;
}

/* Text styling */
#text {
    margin: 3px;
    border: none;
    color: var(--foreground);
    font-size: 13px;
    padding: 3px;
}

#text:selected {
    color: #${HIGHLIGHT};
    font-weight: bold;
}

/* Entry styling */
#entry {
    padding: 7px;
    margin: 2px 5px;
    border-radius: 8px;
    transition: all 0.15s ease;
}

#entry:hover {
    background-color: rgba($(hex_to_rgb "$SELECTION_BG"), 0.15);
}

#entry:selected {
    background-color: rgba($(hex_to_rgb "$SELECTION_BG"), 0.3);
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.15);
}

/* Image/icon styling */
#img {
    margin-right: 10px;
    margin-left: 5px;
}

/* Unselected and urgent styling */
#unselected {
    opacity: 0.9;
}

#urgent {
    background-color: rgba($(hex_to_rgb "$COLOR1"), 0.2);
    color: #${COLOR1};
}
EOL

# Also create a simple config file
cat > ~/.config/wofi/config << EOL
width=600
height=400
location=center
show=drun
prompt=Applications
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
content_halign=fill
insensitive=true
allow_images=true
image_size=32
matching=fuzzy
hide_scroll=true
EOL

echo "Enhanced wofi theme updated with pywal colors"
