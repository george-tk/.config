#!/usr/bin/env python3
"""
Hyprland Socket Bridge
Translates legacy IPC dispatch commands from Waybar and other clients
into modern Hyprland Lua eval commands.
"""

import os
import sys
import glob
import time
import socket
import select
import signal
import threading

def get_hypr_dir():
    runtime_dir = os.getenv("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sig = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
    if sig:
        d = os.path.join(runtime_dir, "hypr", sig)
        if os.path.isdir(d):
            return d
    dirs = glob.glob(os.path.join(runtime_dir, "hypr", "*"))
    for d in dirs:
        if os.path.exists(os.path.join(d, ".socket.sock")) or os.path.exists(os.path.join(d, ".socket_real.sock")):
            return d
    return None

def handle_client(client, real_path):
    try:
        client.settimeout(3.0)
        data = b""
        while True:
            chunk = client.recv(4096)
            if not chunk:
                break
            data += chunk
            if len(chunk) < 4096:
                break

        if not data:
            client.close()
            return

        cmd = data.decode("utf-8", errors="replace")

        # Translate legacy dispatch commands
        if cmd.startswith("dispatch workspace ") or cmd.startswith("dispatch /workspace "):
            prefix = "dispatch /workspace " if cmd.startswith("dispatch /workspace ") else "dispatch workspace "
            arg = cmd[len(prefix):].strip()
            escaped_arg = arg.replace('\\', '\\\\').replace('"', '\\"')
            data = f'eval switch_workspace("{escaped_arg}")'.encode("utf-8")
        elif cmd.startswith("dispatch dpms "):
            arg = cmd[len("dispatch dpms "):].strip()
            data = f'eval hl.dispatch(hl.dsp.dpms({{ action = "{arg}" }}))'.encode("utf-8")

        # Forward to real Hyprland socket
        real_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        real_sock.settimeout(3.0)
        real_sock.connect(real_path)
        real_sock.sendall(data)

        resp = b""
        while True:
            try:
                r = real_sock.recv(4096)
                if not r:
                    break
                resp += r
                if len(r) < 4096:
                    break
            except socket.timeout:
                break

        real_sock.close()
        client.sendall(resp)
    except Exception as e:
        try:
            client.sendall(f"error: {e}".encode("utf-8"))
        except Exception:
            pass
    finally:
        try:
            client.close()
        except Exception:
            pass

def main():
    hypr_dir = get_hypr_dir()
    if not hypr_dir:
        print("Hyprland socket directory not found.", file=sys.stderr)
        sys.exit(1)

    sock_path = os.path.join(hypr_dir, ".socket.sock")
    real_path = os.path.join(hypr_dir, ".socket_real.sock")

    # Rename original socket to .socket_real.sock if needed
    if not os.path.exists(real_path) and os.path.exists(sock_path):
        os.rename(sock_path, real_path)
    elif not os.path.exists(real_path) and not os.path.exists(sock_path):
        print("No socket found to bridge.", file=sys.stderr)
        sys.exit(1)

    if os.path.exists(sock_path):
        try:
            os.unlink(sock_path)
        except OSError:
            pass

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(sock_path)
    server.listen(64)

    def cleanup(signum=None, frame=None):
        try:
            server.close()
            if os.path.exists(sock_path):
                os.unlink(sock_path)
            if os.path.exists(real_path):
                os.rename(real_path, sock_path)
        except Exception:
            pass
        sys.exit(0)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    print("Hyprland socket bridge active on", sock_path, flush=True)

    while True:
        try:
            client, _ = server.accept()
            t = threading.Thread(target=handle_client, args=(client, real_path), daemon=True)
            t.start()
        except Exception:
            time.sleep(0.05)

if __name__ == "__main__":
    main()
