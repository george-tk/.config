#!/bin/bash
#  _                            _     _           _     
# | | _____ _   _ _ __  _ _ __  __| | | | '_ \ / _` / __|
# |  <  __/ |_| | |_) | | | | | (_| | | | | | | (_| \__ \
# |_|\_\___|\__, |_.__/|_|_| |_|\__,_|_|_| |_|\__, |___/ 
#           |___/                             |___/     
# Pure State Key Simulator with Rofi Escape Buffer
# -------------------------------------------------------------------------

mapfile -t data < <(hyprctl binds | awk '
BEGIN { RS = "" }

{
    modmask = ""
    key = ""
    keycode = ""
    desc = ""
    dispatcher = ""
    arg = ""

    # 1. Parse the blocks into variables
    for (i = 1; i <= NF; i++) {
        if ($i == "modmask:")     { modmask = $(i+1) }
        if ($i == "key:")         { key = $(i+1) }
        if ($i == "keycode:")     { keycode = $(i+1) }
        if ($i == "dispatcher:")  { dispatcher = $(i+1) }
        if ($i == "arg:")         { arg = $(i+1) }
        if ($i == "description:") { 
            match($0, /description: .*/)
            desc = substr($0, RSTART + 13, RLENGTH - 13)
            gsub(/\n.*/, "", desc)
        }
    }

    if (key != "") {
        # Create a safe display variable for the key
        clean_key = key
        if (clean_key == "SUPER_L" || clean_key == "CTRL_L" || clean_key == "ALT_L" || clean_key == "SHIFT_L") {
            clean_key = ""
        }

        # 2. Map Modmasks explicitly to Rofi Display Layouts (Your logic sequence)
        if (modmask == "65") {
            bind_part = "󰍲 + " clean_key " + SHIFT"
        } else if (key == "SUPER_L") {
            bind_part = "󰍲"
        } else if (modmask == "72") {
            bind_part = "󰍲 + " clean_key " + ALT"
        } else if (modmask == "73") {
            bind_part = "󰍲 + " clean_key " + ALT + SHIFT"
        } else if (modmask == "64") {
            bind_part = "󰍲 + " clean_key
        } else if (modmask == "68") {
            bind_part = "󰍲 + " clean_key " + CTRL"
        } else if (modmask == "69") {
            bind_part = "󰍲 + " clean_key " + CTRL + SHIFT"
        } else {
            bind_part = clean_key
        }

        # Handle formatting cleanups for standalone mod presses or loose spaces
        gsub(/[ \t]*\+[ \t]*$/, "", bind_part)
        gsub(/^[ \t]*\+[ \t]* /, "", bind_part)
        if (bind_part == "") { bind_part = "󰍲" }

        # 3. Map Modmasks explicitly to wtype arguments
        if (modmask == "64")      { w_mods = "-M win" }
        else if (modmask == "65") { w_mods = "-M win -M shift" }
        else if (modmask == "68") { w_mods = "-M win -M ctrl" }
        else if (modmask == "69") { w_mods = "-M win -M ctrl -M shift" }
        else if (modmask == "72") { w_mods = "-M win -M alt" }
        else if (modmask == "73") { w_mods = "-M win -M alt -M shift" }
        else                      { w_mods = "" }

        # Lowercase symbol parsing for virtual device injection
        w_key = tolower(key)
        if (w_key == "super_l") { w_key = "" }

        # Fallback if description field is empty
        if (desc == "") { desc = "No description" }

        # Output Line 1: Colored Rofi String
        printf "<b><span color=\"#b4befe\">%-26s</span></b>  <span color=\"#45475a\">│</span>  <span color=\"#a6adc8\">%s</span>\n", bind_part, desc
        
        # Output Line 2: The shortcut packaged arguments
        print dispatcher ";" arg ";" w_mods ";" w_key
    }
}')

# Distribute array lines sequentially
menu_items=()
shortcuts=()
for ((i=0; i<${#data[@]}; i+=2)); do
    menu_items+=("${data[i]}")
    shortcuts+=("${data[i+1]}")
done

# Feed and deploy Rofi
rofi_input=$(printf "%s\n" "${menu_items[@]}")
chosen_index=$(echo -e "${rofi_input}" | rofi -dmenu -i -p "  " -format 'i' -markup -no-show-icons -kb-cancel "Escape,Super_L")

# Cooldown to prevent SUPER release from triggering main launcher
touch "/tmp/rofi_cooldown"
(sleep 0.2 && rm -f "/tmp/rofi_cooldown") &

# Virtual Injector Command Event Fire
if [[ -n "$chosen_index" ]] && [[ "$chosen_index" -lt "${#shortcuts[@]}" ]]; then
    IFS=";" read -r dispatcher arg target_mods target_key <<< "${shortcuts[$chosen_index]}"
    
    # CRITICAL: Allow Rofi to completely shut down and release its keyboard focus
    sleep 0.1
    
    if [ "$dispatcher" = "__lua" ] && [ -n "$arg" ]; then
        # Execute the Lua bind callback directly using hyprctl eval (synchronously)
        hyprctl eval "debug.getregistry()[$arg]()" &>/dev/null
    elif [ -n "$dispatcher" ] && [ "$dispatcher" != "none" ]; then
        # Execute the dispatcher directly via hyprctl dispatch (synchronously)
        hyprctl dispatch "$dispatcher" "$arg" &>/dev/null
    elif [ -n "$target_mods" ] || [ -n "$target_key" ]; then
        # Fallback: Inject the key combo perfectly back into the active Wayland session
        eval "wtype $target_mods $target_key" &>/dev/null &
    fi
fi
