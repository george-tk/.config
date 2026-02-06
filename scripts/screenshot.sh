#!/bin/bash

# Define the directory where screenshots will be saved
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"

# Create the directory if it doesn't exist
mkdir -p "$SCREENSHOT_DIR"

# Get the current date and time to use in the filename
FILENAME="$SCREENSHOT_DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

# Function to take a screenshot of a selected region
screenshot_region() {
    grim -g "$(slurp)" "$FILENAME"
    wl-copy < "$FILENAME"
    notify-send "Screenshot taken" "Region saved to $FILENAME and copied to clipboard."
}

# Function to take a screenshot of the active window
screenshot_window() {
    grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$FILENAME"
    wl-copy < "$FILENAME"
    notify-send "Screenshot taken" "Active window saved to $FILENAME and copied to clipboard."
}

# Function to take a full-screen screenshot
screenshot_fullscreen() {
    grim "$FILENAME"
    wl-copy < "$FILENAME"
    notify-send "Screenshot taken" "Fullscreen saved to $FILENAME and copied to clipboard."
}

# Main logic
case "$1" in
    --region)
        screenshot_region
        ;;
    --window)
        screenshot_window
        ;;
    --fullscreen)
        screenshot_fullscreen
        ;;
    *)
        echo "Usage: $0 {--region|--window|--fullscreen}"
        exit 1
        ;;
esac
