#!/bin/bash

# Log all output to a user cache file for debugging
LOG_FILE="$HOME/.cache/rotate_wallpaper.log"
exec > >(tee -a "$LOG_FILE" 2>&1)
echo "--- Starting wallpaper rotation at $(date) ---"

# This script needs to know which Hyprland instance to communicate with.
# We get it dynamically from hyprctl
export HYPRLAND_INSTANCE_SIGNATURE=$(hyprctl instances | head -n 1 | awk '{print $2}' | sed 's/://g')

# Directory containing the wallpapers
WALLPAPER_DIR="$HOME/.config/wallpapers"

# Find all jpg and png files, excluding the 'not_used' directory
WALLPAPER_FILES=$(find "$WALLPAPER_DIR" -type f \
    -not -path "$WALLPAPER_DIR/not_used/*" \
    \( -name "*.jpg" -o -name "*.png" \))

if [ -z "$WALLPAPER_FILES" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Get a random wallpaper from the list
RANDOM_WALLPAPER=$(echo "$WALLPAPER_FILES" | shuf -n 1)

# Reload hyprpaper with the new random wallpaper
/usr/bin/hyprctl hyprpaper unload all || { echo "Error: hyprctl hyprpaper unload all failed." >> /dev/stderr; exit 1; }
/usr/bin/hyprctl hyprpaper preload "$RANDOM_WALLPAPER" || { echo "Error: hyprctl hyprpaper preload failed." >> /dev/stderr; exit 1; }
/usr/bin/hyprctl hyprpaper wallpaper ",$RANDOM_WALLPAPER" || { echo "Error: hyprctl hyprpaper wallpaper failed." >> /dev/stderr; exit 1; }

echo "Wallpaper set to $RANDOM_WALLPAPER"
echo "--- Finished wallpaper rotation at $(date) ---"