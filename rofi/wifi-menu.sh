#!/usr/bin/env bash

# Configuration
ROFI_CMD="rofi -dmenu -i -config ~/.config/rofi/wifi-config.rasi"
SEPARATOR="────────────────────────────────────────"

# 1. Get Radio Status
wifi_state=$(nmcli radio wifi)
[[ "$wifi_state" == "enabled" ]] && toggle="󰖪  Disable Wi-Fi" || toggle="󰖩  Enable Wi-Fi"

# 2. Get Active Connection Details
active_data=$(nmcli -t -f ACTIVE,SIGNAL,FREQ,SSID dev wifi | grep '^yes' | head -n1)

if [[ -n "$active_data" ]]; then
    current_sig=$(echo "$active_data" | cut -d: -f2)
    current_freq=$(echo "$active_data" | cut -d: -f3)
    current_ssid=$(echo "$active_data" | cut -d: -f4)
    current_band=$([[ $current_freq -lt 3000 ]] && echo "2.4G" || echo "5G")
    status="Connected: $current_ssid (${current_sig}% | $current_band)"
    active_id="${current_ssid}${current_band}"
else
    status="Disconnected"
    active_id="---NONE---"
fi

# 3. Get Network List 
# We remove '--rescan no' temporarily to ensure we actually see something if the cache is empty
raw_list=$(nmcli -t -f "SIGNAL,FREQ,SSID" device wifi list | sed 's/^--//')

# If the list is STILL empty, it might be a driver delay. 
if [[ -z "$raw_list" ]]; then
    provider_list="  [ No Networks Found - Try Refresh ]"
else
    provider_list=$(echo "$raw_list" | sort -t: -k1 -rn | awk -F: -v aid="$active_id" '
        {
            sig = $1;
            freq = $2 + 0;
            ssid = $3;
            band = (freq < 3000 ? "2.4G" : "5G");
            id = ssid band;
            
            if (id != aid && ssid != "" && !seen[id]++) {
                printf "%3d%%  %-25s [%s]\n", sig, ssid, band
            }
        }')
fi

# 4. Create Menu
options="$toggle\n󰑐  Refresh List\n󰑐  Manual Entry / Hidden SSID\n󰃢  Disconnect\n$SEPARATOR\n$provider_list"

# 5. Rofi Prompt
chosen=$(echo -e "$options" | $ROFI_CMD -p "$status")

[[ -z "$chosen" || "$chosen" == "$SEPARATOR" || "$chosen" == *"No Networks Found"* ]] && exit

# 6. Logic Case
case "$chosen" in
    "$toggle")
        [[ "$wifi_state" == "enabled" ]] && nmcli radio wifi off || nmcli radio wifi on ;;
    "󰑐  Refresh List")
        nmcli device wifi rescan
        # IMPORTANT: We need to wait for the hardware to actually finish scanning
        # before we restart the script, otherwise the list will still be empty.
        (sleep 2 && notify-send "Wi-Fi" "Scan Complete") & 
        sleep 2
        exec "$0" ;;
    "󰃢  Disconnect")
        WLAN=$(nmcli -t -f DEVICE,TYPE device | grep wifi | cut -d: -f1 | head -n1)
        nmcli device disconnect "$WLAN" ;;
    "󰑐  Manual Entry / Hidden SSID")
        manual_ssid=$($ROFI_CMD -p "Enter SSID:")
        [[ -z "$manual_ssid" ]] && exit
        manual_pass=$($ROFI_CMD -p "Password:" -password)
        nmcli device wifi connect "$manual_ssid" password "$manual_pass" ;;
    *)
        ssid=$(echo "$chosen" | sed -E 's/^[ ]*[0-9]+%[ ]+//; s/[ ]*\[(2\.4G|5G)\]//; s/[ ]*$//')
        if nmcli -t -f name connection show | grep -qx "$ssid"; then
            nmcli connection up "$ssid"
        else
            pass=$($ROFI_CMD -p "Password for $ssid:" -password)
            [[ -z "$pass" ]] && exit
            nmcli device wifi connect "$ssid" password "$pass"
        fi ;;
esac
