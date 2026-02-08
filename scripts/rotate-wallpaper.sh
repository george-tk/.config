#!/bin/bash
# 1. Setup Environment
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export PATH=$PATH:/usr/local/bin:/usr/bin

# 2. Logging
LOG_FILE="$HOME/.cache/rotate_wallpaper.log"
exec > >(tee -a "$LOG_FILE" 2>&1)
echo "--- Starting wallpaper rotation at $(date) ---"

# 3. WAIT logic - This is the most important part
# Wait for the process to exist
while ! pgrep -x "hyprpaper" > /dev/null; do
    echo "Waiting for hyprpaper process..."
    sleep 1
done

# Even if the process exists, the socket takes a moment to initialize.
# We wait an extra 2 seconds here to prevent "failed to connect"
sleep 0.1 

# 4. Get Hyprland Instance
export HYPRLAND_INSTANCE_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance')

# 5. Find Wallpapers
WALLPAPER_DIR="$HOME/.config/wallpapers"
WALLPAPER_FILES=$(find "$WALLPAPER_DIR" -type f \
    -not -path "$WALLPAPER_DIR/not_used/*" \
    \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \))

if [ -z "$WALLPAPER_FILES" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

RANDOM_WALLPAPER=$(echo "$WALLPAPER_FILES" | shuf -n 1)

# 6. Execute with Error Catching
echo "Attempting to set wallpaper: $RANDOM_WALLPAPER"

# We use 'hyprpaper' commands directly via hyprctl
hyprctl hyprpaper unload all || echo "Notice: Nothing to unload yet."
hyprctl hyprpaper preload "$RANDOM_WALLPAPER"
hyprctl hyprpaper wallpaper ",$RANDOM_WALLPAPER"

echo "Wallpaper successfully set to: $RANDOM_WALLPAPER"
echo "--- Finished wallpaper rotation at $(date) ---"
