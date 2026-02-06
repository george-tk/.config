#!/usr/bin/env bash

# 1. SET YOUR TERMINAL HERE (e.g., kitty, alacritty, foot, gnome-terminal)
TERM_EMULATOR="kitty" 

# 2. LOGIC
if [ -z "$@" ]; then
    # If no selection, output the list of files
    # looking in Home, hidden files included, ignoring .git
    fd --type f --type d --hidden --follow --exclude .git . $HOME
else
    # If a selection is made, open it in the terminal with nvim
    # setsid decouples the process so it doesn't die when Rofi closes
    setsid $TERM_EMULATOR -e nvim "$@" >/dev/null 2>&1 &
fi
