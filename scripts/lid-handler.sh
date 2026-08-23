#!/usr/bin/env bash
# ~/.config/scripts/lid-handler.sh
# Handles laptop lid open/close events for Clamshell mode in Hyprland (Lua configuration).

ACTION="${1:-close}"

# Detect internal display (eDP-1, LVDS-1, etc.)
INTERNAL_MONITOR=$(hyprctl monitors all -j 2>/dev/null | jq -r '.[].name | select(startswith("eDP") or startswith("LVDS") or startswith("DSI"))' 2>/dev/null | head -n 1)
if [ -z "$INTERNAL_MONITOR" ]; then
    INTERNAL_MONITOR="eDP-1"
fi

# Detect external monitors (connected outputs other than internal display)
EXTERNAL_COUNT=$(hyprctl monitors all -j 2>/dev/null | jq -r --arg int "$INTERNAL_MONITOR" '[.[] | select(.name != $int)] | length' 2>/dev/null)
if [ -z "$EXTERNAL_COUNT" ]; then
    EXTERNAL_COUNT=0
fi

case "$ACTION" in
    close)
        if [ "$EXTERNAL_COUNT" -gt 0 ]; then
            # External monitor attached -> Clamshell mode (disable internal screen)
            hyprctl eval "hl.monitor({ output = '${INTERNAL_MONITOR}', disabled = true })"
        else
            # No external display -> Lock session and suspend laptop
            loginctl lock-session
            systemctl suspend
        fi
        ;;
    open)
        # Re-enable internal display and wake up monitors
        hyprctl eval "hl.monitor({ output = '${INTERNAL_MONITOR}', disabled = false, mode = 'preferred', position = 'auto', scale = 1 })"
        hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
        ;;
    *)
        echo "Usage: $0 {close|open}"
        exit 1
        ;;
esac
