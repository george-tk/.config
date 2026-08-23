#!/bin/bash
if ! pgrep -f hypr-socket-bridge.py >/dev/null; then
    nohup ~/.config/scripts/hypr-socket-bridge.py >/dev/null 2>&1 &
    sleep 0.2
fi
killall -9 waybar 2>/dev/null || true
sleep 0.5
nohup waybar >/dev/null 2>&1 &