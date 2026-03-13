#!/usr/bin/env python3
import json
import subprocess
import sys

def get_hyprctl(cmd):
    result = subprocess.run(['hyprctl', '-j', *cmd.split()], capture_output=True, text=True)
    return json.loads(result.stdout)

def main():
    if len(sys.argv) < 2:
        return

    mode = sys.argv[1] # 'focus' or 'swap'
    direction = sys.argv[2] if len(sys.argv) > 2 else 'next' # 'next' or 'prev'

    # Get active workspace and clients
    active_workspace = get_hyprctl('activeworkspace')['id']
    clients = [c for c in get_hyprctl('clients') if c['workspace']['id'] == active_workspace]
    
    if not clients:
        return

    # Sort clients by visual position: top-to-bottom, then left-to-right
    # This matches the "Fibonacci" visual order in dwindle layout
    clients.sort(key=lambda c: (c['at'][1], c['at'][0]))

    # Find current focused window
    active_window = get_hyprctl('activewindow')
    if not active_window:
        current_idx = 0
    else:
        current_addr = active_window['address']
        current_idx = next((i for i, c in enumerate(clients) if c['address'] == current_addr), 0)

    # Determine next/prev index
    if direction == 'next':
        target_idx = (current_idx + 1) % len(clients)
    else:
        target_idx = (current_idx - 1) % len(clients)

    target_addr = clients[target_idx]['address']

    if mode == 'focus':
        subprocess.run(['hyprctl', 'dispatch', 'focuswindow', f'address:{target_addr}'])
    elif mode == 'swap':
        # Swap current with target and keep focus on current
        subprocess.run(['hyprctl', 'dispatch', 'swapwindow', f'address:{target_addr}'])
        # Ensure focus stays on the "moving" window
        subprocess.run(['hyprctl', 'dispatch', 'focuswindow', f'address:{active_window["address"]}'])

if __name__ == "__main__":
    main()
