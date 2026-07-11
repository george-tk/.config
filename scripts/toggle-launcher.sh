#!/bin/bash

COOLDOWN_FILE="/tmp/rofi_cooldown"

# 1. If we were fired within a split second of Rofi closing, ignore it.
if [ -f "$COOLDOWN_FILE" ]; then
    rm -f "$COOLDOWN_FILE"
    exit 0
fi

# 2. If Rofi is running (e.g. opened from a different shortcut), kill it.
if pgrep -x "rofi" > /dev/null; then
    pkill -x rofi
else
    # 3. Launch Rofi and wait here until the user closes it
    rofi -show combi -kb-cancel "Escape,Super_L"
    
    # 4. Rofi JUST closed. Create a temporary file to flag the cooldown.
    touch "$COOLDOWN_FILE"
    
    # 5. Leave the file there for 200ms to catch the trailing release event, then clean up
    (sleep 0.2 && rm -f "$COOLDOWN_FILE") &
fi
