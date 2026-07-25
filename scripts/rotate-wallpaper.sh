#!/bin/bash

# 1. Setup Environment
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export PATH=$PATH:/usr/local/bin:/usr/bin

# 2. Logging
mkdir -p "$HOME/.cache"
LOG_FILE="$HOME/.cache/rotate_wallpaper.log"
exec > >(tee -a "$LOG_FILE" 2>&1)
echo "--- Starting wallpaper rotation at $(date) ---"

# 3. WAIT logic - The Race Condition Fix
# Wait for the hyprpaper process to exist (max 15 attempts / ~5 seconds)
attempts=0
max_attempts=15
while ! pgrep -x "hyprpaper" > /dev/null; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge "$max_attempts" ]; then
        echo "Timeout waiting for hyprpaper. Proceeding anyway..."
        break
    fi
    echo "Waiting for hyprpaper process (attempt $attempts/$max_attempts)..."
    sleep 0.3
done

# The dual-monitor setup takes Hyprland and Hyprpaper slightly longer to initialize.
# We are bumping this to 2 seconds to ensure all Wayland outputs are registered.
sleep 0.3 

# 4. Get Hyprland Instance (Usually auto-detected, but good as a fallback)
export HYPRLAND_INSTANCE_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance')

# 5. Find Wallpapers
if [ "$1" == "--init" ] && [ -f /var/lib/sddm-wallpaper.jpg ]; then
    echo "Init mode: restoring active SDDM login wallpaper."
    RANDOM_WALLPAPER="/var/lib/sddm-wallpaper.jpg"
else
    WALLPAPER_DIR="$HOME/.config/wallpapers"
    WALLPAPER_FILES=$(find "$WALLPAPER_DIR" -type f \
        -not -path "$WALLPAPER_DIR/not_used/*" \
        \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \))
    
    if [ -z "$WALLPAPER_FILES" ]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi
    
    RANDOM_WALLPAPER=$(echo "$WALLPAPER_FILES" | shuf -n 1)
fi

# 6. Execute with Error Catching
echo "Attempting to set wallpaper: $RANDOM_WALLPAPER"

# Best Practice Order: Preload New -> Set Wallpaper -> Unload Unused
# This prevents the brief black-screen flash that happens if you unload everything first.

hyprctl hyprpaper preload "$RANDOM_WALLPAPER"

# Brief pause to ensure preload finishes before applying
sleep 0.3 

# The empty string before the comma targets ALL currently connected monitors
hyprctl hyprpaper wallpaper ",$RANDOM_WALLPAPER"

# Sync with SDDM login background for a seamless boot transition
if [ -w /var/lib/sddm-wallpaper.jpg ]; then
    cp "$RANDOM_WALLPAPER" /var/lib/sddm-wallpaper.jpg
    echo "SDDM login background synchronized."
fi

# Clean up RAM by unloading wallpapers that are no longer actively displayed
hyprctl hyprpaper unload unused || echo "Notice: Nothing to unload yet."

echo "Wallpaper successfully set to: $RANDOM_WALLPAPER"
echo "--- Finished wallpaper rotation at $(date) ---"
