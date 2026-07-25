#!/usr/bin/env python3
import json
import os
import subprocess
import sys

CLASS_MAP = {
    "chrome-mail.google.com__-Default": "Gmail",
    "chrome-mail.google.com_-Default": "Gmail",
    "chrome-gemini.google.com__-Default": "Gemini",
    "chrome-gemini.google.com_-Default": "Gemini",
    "chrome-www.youtube.com__-Default": "YouTube",
    "chrome-www.youtube.com_-Default": "YouTube",
    "google-chrome": "Google Chrome",
    "kitty": "Kitty",
    "neovim": "Neovim",
}

ICON_MAP = {
    "chrome-mail.google.com__-Default": "gmail",
    "chrome-mail.google.com_-Default": "gmail",
    "chrome-gemini.google.com__-Default": "gemini",
    "chrome-gemini.google.com_-Default": "gemini",
    "chrome-www.youtube.com__-Default": "youtube",
    "chrome-www.youtube.com_-Default": "youtube",
    "google-chrome": "google-chrome",
    "neovim": "nvim",
}

def get_windows():
    try:
        # Get active clients from Hyprland
        result = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, check=True)
        clients = json.loads(result.stdout)
    except Exception as e:
        print(f"Error fetching Hyprland clients: {e}", file=sys.stderr)
        return []

    # Filter only mapped and non-special windows
    windows = []
    for client in clients:
        if client.get("mapped") and client.get("class") and client.get("title"):
            windows.append(client)
    return windows

def focus_window(address):
    try:
        # Using the custom Lua dispatch focus API from hyprland-lua
        cmd = f'hl.dsp.focus({{ window = "address:{address}" }})'
        subprocess.run(["hyprctl", "dispatch", cmd], stdout=subprocess.DEVNULL, check=True)
    except Exception as e:
        print(f"Error focusing window: {e}", file=sys.stderr)

def get_rofi_line(client):
    raw_class = client["class"]
    title = client["title"]
    address = client["address"]
    
    # Get clean class and icon names
    clean_class = CLASS_MAP.get(raw_class, raw_class.capitalize())
    icon = ICON_MAP.get(raw_class, raw_class)
    
    # Pad class name to align separators
    clean_class_padded = clean_class.ljust(15)
    
    # Escape XML/HTML special characters for Pango markup in Rofi
    title_escaped = title.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    clean_class_padded_escaped = clean_class_padded.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    
    # Format for Rofi script mode with info (metadata) and icon
    return f"<b>{clean_class_padded_escaped}</b><span fgcolor='#45475a'>│</span>  {title_escaped}\0info\x1f{address}\x1ficon\x1f{icon}"

def print_window_list():
    print("\0markup-rows\x1ftrue")
    windows = get_windows()
    for client in windows:
        print(get_rofi_line(client))

def run_dmenu_mode():
    windows = get_windows()
    if not windows:
        sys.exit(0)

    rofi_lines = [get_rofi_line(client) for client in windows]
    rofi_input = "\n".join(rofi_lines)

    rofi_cmd = [
        "rofi",
        "-dmenu",
        "-format", "i",
        "-markup-rows",
        "-show-icons",
        "-p", "  ",
        "-kb-cancel", "Escape,Super_L"
    ]
    
    try:
        proc = subprocess.Popen(rofi_cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        stdout, _ = proc.communicate(input=rofi_input)
    except Exception as e:
        print(f"Error running Rofi: {e}", file=sys.stderr)
        sys.exit(1)

    selection = stdout.strip()
    if not selection:
        sys.exit(0)

    try:
        idx = int(selection)
        selected_window = windows[idx]
        focus_window(selected_window["address"])
    except Exception as e:
        print(f"Error processing selection: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    retv = os.environ.get("ROFI_RETV")
    if retv is not None:
        # Running in Rofi Script Mode
        if retv == "0":
            print_window_list()
        else:
            address = os.environ.get("ROFI_INFO")
            if address:
                focus_window(address)
    else:
        # Running in Standalone (dmenu) Mode
        run_dmenu_mode()

if __name__ == "__main__":
    main()
