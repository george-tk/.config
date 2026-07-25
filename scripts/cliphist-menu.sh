#!/usr/bin/env bash
# Rofi clipboard history menu using cliphist and wl-copy

# 1. If we were fired within a split second of Rofi closing, ignore it.
COOLDOWN_FILE="/tmp/rofi_cooldown"
if [ -f "$COOLDOWN_FILE" ]; then
    rm -f "$COOLDOWN_FILE"
    exit 0
fi

# 2. Get the list of clipboard texts (strip IDs and tabs entirely)
list_items=$(cliphist list | cut -f2-)

# 3. Get selection from Rofi
chosen=$(echo "$list_items" | rofi -dmenu -i -no-show-icons -config ~/.config/rofi/config.rasi -kb-cancel "Escape,Super_L" -p "󰅍  ")

# 4. Cooldown to prevent SUPER release from triggering main launcher
touch "$COOLDOWN_FILE"
(sleep 0.2 && rm -f "$COOLDOWN_FILE") &

# 5. Decode, copy, and auto-paste
if [ -n "$chosen" ]; then
    # Look up the ID corresponding to the selected text
    id=$(cliphist list | awk -F'\t' -v val="$chosen" '$2 == val {print $1; exit}')
    
    if [ -n "$id" ]; then
        # Reconstruct the line cliphist expects and decode it
        echo -e "${id}\t${chosen}" | cliphist decode | wl-copy
        
        # Give the active window a brief moment to regain focus after Rofi exits
        sleep 0.15
        
        # Query the class of the newly focused window (lowercase)
        active_class=$(hyprctl activewindow -j | jq -r '.class' | tr '[:upper:]' '[:lower:]' 2>/dev/null)
        
        # Paste shortcut selection (terminals use Ctrl+Shift+V, others use Ctrl+V)
        if [[ "$active_class" == *"terminal"* || "$active_class" == "kitty" || "$active_class" == "alacritty" || "$active_class" == "foot" || "$active_class" == "wezterm" ]]; then
            wtype -M ctrl -M shift v -m shift -m ctrl
        else
            wtype -M ctrl v -m ctrl
        fi
    fi
fi
