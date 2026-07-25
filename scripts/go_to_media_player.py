#!/usr/bin/env python3
import subprocess
import json
import sys

def get_player_title(player_instance):
    try:
        proc = subprocess.run(["playerctl", "-p", player_instance, "metadata", "xesam:title"], capture_output=True, text=True)
        if proc.returncode == 0:
            return proc.stdout.strip()
    except Exception:
        pass
    return None

def get_player_workspace(player_instance, track_title=None):
    try:
        player_instance = player_instance.lower()
        clients = json.loads(subprocess.check_output(["hyprctl", "clients", "-j"]))
        
        # 1. Match by track title first (handles duplicate window classes across different workspaces)
        if track_title:
            track_title_clean = track_title.lower().strip()
            if track_title_clean:
                for c in clients:
                    win_title = c.get("title", "").lower()
                    if track_title_clean in win_title or win_title in track_title_clean:
                        return c.get("workspace", {}).get("id")
        
        # 2. Fall back to window class matching
        player_map = {
            "spotify": "spotify",
            "chrome": "chrome",
            "chromium": "chrome",
            "firefox": "firefox",
            "brave": "brave"
        }
        # Extract base name (e.g. chromium from chromium.instanceXXXX)
        base_name = player_instance.split(".")[0]
        target = player_map.get(base_name, base_name)
        
        for c in clients:
            cls = c.get("class", "").lower()
            if target in cls or cls in target:
                return c.get("workspace", {}).get("id")
                
        for c in clients:
            title = c.get("title", "").lower()
            if target in title or base_name in title or player_instance in title:
                return c.get("workspace", {}).get("id")
    except Exception:
        pass
    return None

def main():
    try:
        # Get active player instance name (very precise, e.g. chromium.instanceXXXX)
        player_proc = subprocess.run(["playerctl", "metadata", "--format", "{{playerInstance}}"], capture_output=True, text=True)
        if player_proc.returncode != 0:
            return
        player = player_proc.stdout.strip()
        if not player:
            return
            
        title = get_player_title(player)
        ws_id = get_player_workspace(player, title)
        
        if ws_id is not None:
            # Switch to workspace
            subprocess.run(["hyprctl", "dispatch", f'hl.dsp.focus({{ workspace = "{ws_id}" }})'], stdout=subprocess.DEVNULL)
            
            # Find the specific window client and focus its address
            clients = json.loads(subprocess.check_output(["hyprctl", "clients", "-j"]))
            player_instance = player.lower()
            base_name = player_instance.split(".")[0]
            player_map = {"spotify": "spotify", "chrome": "chrome", "chromium": "chrome", "firefox": "firefox", "brave": "brave"}
            target_class = player_map.get(base_name, base_name)
            
            for c in clients:
                if c.get("workspace", {}).get("id") == ws_id:
                    cls = c.get("class", "").lower()
                    win_title = c.get("title", "").lower()
                    title_clean = title.lower().strip() if title else ""
                    
                    # Match target client on that workspace
                    if (title_clean and (title_clean in win_title or win_title in title_clean)) or (target_class in cls or cls in target_class):
                        addr = c.get("address")
                        subprocess.run(["hyprctl", "dispatch", f'hl.dsp.focus({{ window = "address:{addr}" }})'], stdout=subprocess.DEVNULL)
                        return
    except Exception as e:
        pass

if __name__ == "__main__":
    main()
