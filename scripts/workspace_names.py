#!/usr/bin/env python3
import os
import socket
import json
import time
import sys

ICON_MAP = {
    "kitty": "",
    "alacritty": "",
    "firefox": "",
    "brave-browser": "",
    "google-chrome": "",
    "chrome-mail.google.com__-default": "󰊫",
    "chrome-gemini.google.com__-default": "󰚩",
    "chrome-www.youtube.com__-default": "",
    "code": "",
    "discord": "󰙯",
    "spotify": "󰓇",
    "thunar": "",
    "nautilus": "",
    "org.gnome.nautilus": "",
    "pavucontrol": "",
    "blueman-manager": "󰂯",
    "neovim": ""
}

# --- UNIX Domain Socket Connections for Blazing Performance ---
signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
if not signature or not runtime_dir:
    sys.exit(1)

cmd_sock_path = os.path.join(runtime_dir, "hypr", signature, ".socket.sock")

def send_hypr_cmd(cmd):
    """Sends a raw command to Hyprland's command socket without spawning any subprocesses."""
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(cmd_sock_path)
            s.sendall(cmd.encode('utf-8'))
            response = b""
            while True:
                chunk = s.recv(4096)
                if not chunk:
                    break
                response += chunk
            return response.decode('utf-8', errors='ignore')
    except Exception as e:
        print(f"Socket error for command '{cmd}': {e}", file=sys.stderr)
        return ""

def get_hypr_json(cmd):
    """Queries Hyprland socket for JSON data."""
    raw = send_hypr_cmd(cmd)
    try:
        return json.loads(raw)
    except Exception as e:
        return {}

# Track states in a global dictionary to minimize redundant socket writes
workspace_states = {}

def update_workspaces():
    global workspace_states
    try:
        # Get clients, workspaces, and active workspace in parallel or sequentially over raw sockets
        clients = get_hypr_json("j/clients")
        if not isinstance(clients, list):
            clients = []
            
        active_ws = get_hypr_json("j/activeworkspace")
        active_ws_id = active_ws.get("id", 1) if isinstance(active_ws, dict) else 1
        
        workspaces = get_hypr_json("j/workspaces")
        if not isinstance(workspaces, list):
            workspaces = []
        
        # Find maximum occupied workspace ID
        max_occupied_id = 1
        workspace_clients = {}
        for c in clients:
            ws_id = c.get("workspace", {}).get("id")
            if ws_id is not None and ws_id > 0:
                max_occupied_id = max(max_occupied_id, ws_id)
                if ws_id not in workspace_clients:
                    workspace_clients[ws_id] = []
                workspace_clients[ws_id].append(c)
        
        # Determine the maximum workspace we want to show (occupied or active)
        limit = max(max_occupied_id, active_ws_id)
        
        # Loop through a reasonable range of workspaces (e.g. 1 to 20)
        for i in range(1, 21):
            if i <= limit:
                # Workspace should exist (either occupied or an in-between dot)
                clients_in_ws = workspace_clients.get(i, [])
                if clients_in_ws:
                    first_client = clients_in_ws[0]
                    cls = first_client.get("class", "").lower()
                    icon = None
                    for key, val in ICON_MAP.items():
                        if key in cls or cls in key:
                            icon = val
                            break
                    if not icon:
                        icon = ""
                    target_state = ("icon", icon)
                else:
                    target_state = ("dot", "·")
            else:
                # Trailing empty workspaces should be hidden
                target_state = ("hidden", "")
            
            # Update state if changed
            current_state = workspace_states.get(i)
            if current_state != target_state:
                state_type, value = target_state
                if state_type == "hidden":
                    # Make it non-persistent. Hyprland will automatically destroy it if empty and inactive.
                    send_hypr_cmd(f'eval hl.workspace_rule({{ workspace = "{i}", persistent = false }})')
                else:
                    # Make it persistent so Hyprland keeps it alive in-between active ones
                    send_hypr_cmd(f'eval hl.workspace_rule({{ workspace = "{i}", persistent = true }})')
                    # Rename it
                    new_name = value + ("\u200b" * i)
                    send_hypr_cmd(f'dispatch hl.dsp.workspace.rename({{ workspace = "{i}", name = "{new_name}" }})')
                
                workspace_states[i] = target_state
                
    except Exception as e:
        print(f"Error in update_workspaces: {e}", file=sys.stderr)
        sys.stderr.flush()

def main():
    socket2_path = os.path.join(runtime_dir, "hypr", signature, ".socket2.sock")
    
    update_workspaces()
    
    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(socket2_path)
                while True:
                    data = s.recv(4096).decode('utf-8', errors='ignore')
                    if not data:
                        break
                    events = data.strip().split('\n')
                    needs_update = False
                    for event in events:
                        if any(ev in event for ev in ["openwindow", "closewindow", "movewindow", "workspace"]):
                            needs_update = True
                            break
                    if needs_update:
                        # Negligible delay to let Hyprland stabilize state
                        time.sleep(0.01)
                        update_workspaces()
        except Exception as e:
            time.sleep(1)

if __name__ == "__main__":
    main()
