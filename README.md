# ❄️ Arch Linux (Hyprland) Dotfiles & System Guide

This repository contains my personal dotfiles, scripts, and automated installer to deploy a fully configured **Arch Linux** environment featuring **Hyprland**, **Catppuccin Mocha** theming, **Waybar**, **Rofi**, **SDDM**, and custom desktop scripts.

---

## 📋 Table of Contents
- [🚀 Installation & Setup Guide](#-installation--setup-guide)
  - [Step 1: Boot from Laptop Boot Menu](#step-1-boot-from-laptop-boot-menu)
  - [Step 2: Install Base Arch Linux (`archinstall`)](#step-2-install-base-arch-linux-archinstall)
  - [Step 3: Clone Configuration & Run Setup Script](#step-3-clone-configuration--run-setup-script)
- [🔄 Updating the Repository](#-updating-the-repository)
- [🔧 Key Configuration Systems](#-key-configuration-systems)
  - [1. Bluetooth & Peripherals](#1-bluetooth--peripherals)
  - [2. GTK Theming & Legacy App Consistency](#2-gtk-theming--legacy-app-consistency)
  - [3. SDDM Login Screen & Dynamic Wallpaper Sync](#3-sddm-login-screen--dynamic-wallpaper-sync)
  - [4. Automated Wallpaper Rotation](#4-automated-wallpaper-rotation)
  - [5. Window Switcher & Focus Logic](#5-window-switcher-window_switcherpy)
  - [6. Google Chrome Web Apps (PWAs)](#6-google-chrome-web-apps-pwas)
- [📂 Utility Scripts Index](#-utility-scripts-index)
- [🛠️ Guide: Adding Custom Applications](#-guide-adding-custom-applications)
- [🚨 Troubleshooting](#-troubleshooting)

---

## 🚀 Installation & Setup Guide

### Step 1: Boot from Laptop Boot Menu
1. **Flash ISO:** Write the official Arch Linux ISO onto a USB flash drive (using Ventoy, Rufus, or `dd`).
2. **Open Boot Menu:** Insert the USB drive into your laptop and power on. Repeatedly press your laptop's **Boot Menu key** (commonly **F12**, **F11**, **F8**, **F2**, or **Esc** depending on vendor, e.g., Lenovo, Dell, HP, Asus).
3. **Select USB:** Choose your USB drive from the list to boot into the Arch Linux Live ISO environment.

### Step 2: Install Base Arch Linux (`archinstall`)
1. *(Optional Wi-Fi connection)*: If using Wi-Fi, run `iwctl` to connect to your network before proceeding.
2. Update the installer package:
   ```bash
   pacman -Sy archinstall
   ```
3. Run the installer:
   ```bash
   archinstall
   ```
4. Configure the following settings in `archinstall`:
   * **Locale / Keymap:** Set Keymap to `uk`, Timezone to `Europe/London`.
   * **Profile:** Select `Minimal` (the setup script handles Hyprland, applications, and desktop environment).
   * **Disk Configuration:** Select target drive and filesystem (`ext4`).
   * **User Account:** Create your username/password, and enable **sudo** privileges (add user to `wheel` group).
   * **Network Configuration:** Select `NetworkManager`.
   * **Audio:** Enable `PipeWire`.
   * **Bluetooth:** Enable Bluetooth (`bluez`).
5. Select **Install**, wait for completion, unplug the USB drive, and reboot into Arch Linux.

### Step 3: Clone Configuration & Run Setup Script
1. **Log in** as your normal user on the new Arch Linux system.
2. **Connect to Wi-Fi/Internet** (if not automatically connected):
   ```bash
   nmtui
   ```
3. **Install Git & Clone Repository:**
   ```bash
   sudo pacman -S git
   git clone --recursive https://github.com/george-tk/.config ~/.config
   ```
4. **Run Automated Setup Script:**
   The setup script installs all core packages (AUR via `yay`), sets up systemd services, GTK/SDDM themes, cron jobs, and dotfiles:
   ```bash
   sudo ~/.config/scripts/setup.sh
   ```

---

## 🔄 Updating the Repository

To pull latest dotfile changes and submodule updates:
```bash
# Pull main repo and all submodules
git pull --recurse-submodules

# If already pulled, sync submodules:
git submodule update --init --recursive

# Update submodules to latest remote commits:
git submodule update --remote --recursive
```

---

## 🔧 Key Configuration Systems

### 1. Bluetooth & Peripherals
* **GUI Manager:** `blueman-manager` (launch via **`Super + Shift + B`**).
* **CLI Alternative:** Use `bluetoothctl`:
  ```bash
  bluetoothctl
  # Inside prompt:
  power on
  agent on
  default-agent
  scan on
  pair <MAC_ADDRESS>
  connect <MAC_ADDRESS>
  trust <MAC_ADDRESS>
  ```
* **Service:** Managed automatically via `sudo systemctl enable --now bluetooth`.

### 2. GTK Theming & Legacy App Consistency
* **Theme:** Catppuccin Mocha Blue (`catppuccin-gtk-theme-mocha`) with Papirus-Dark icons.
* **Legacy Apps Fix (e.g. Thunar):** If GTK3/GTK4 apps show light/Adwaita theme, ensure `xdg-desktop-portal-gtk` is installed (`sudo pacman -S xdg-desktop-portal-gtk`). GTK settings are configured in `~/.config/gtk-3.0/settings.ini` and applied via `gsettings`.

### 3. SDDM Login Screen & Dynamic Wallpaper Sync
* **Theme Location:** `/usr/share/sddm/themes/catppuccin-mocha-blue/`
* **Dynamic Background:** The SDDM theme background points to `/var/lib/sddm-wallpaper.jpg`.
* **Sync Mechanism:** [setup.sh](file:///home/georgek/.config/scripts/setup.sh) configures permissions (`chmod 664`, `chown $USER:sddm`) so the desktop wallpaper rotation script can write to `/var/lib/sddm-wallpaper.jpg` on each update. This guarantees a seamless transition from the SDDM login screen into your desktop session.

### 4. Automated Wallpaper Rotation
* **Script:** [rotate-wallpaper.sh](file:///home/georgek/.config/scripts/rotate-wallpaper.sh)
* **Schedule:** A user `cron` job runs every 15 minutes (`cronie.service`).
* **Manual Trigger:** Run `~/.config/scripts/rotate-wallpaper.sh`.
* **Logs:** Output logged to `~/.cache/rotate_wallpaper.log`.

### 5. Window Switcher (`window_switcher.py`)
* **Shortcut:** **`Super + Shift + I`** (configured in [binds.lua](file:///home/georgek/.config/hypr/conf/binds.lua)).
* **Script:** [window_switcher.py](file:///home/georgek/.config/scripts/window_switcher.py)
* **Functionality:**
  1. Queries active windows via `hyprctl clients -j`.
  2. Formats entries with application titles & Nerd Font/system icons using Rofi (`rofi -dmenu`).
  3. Focuses the target window address via Hyprland Lua IPC (`hyprctl dispatch 'hl.dsp.focus({ window = "address:<address>" })'`).
  *Note:* All Python status outputs during window focus redirect to `DEVNULL` to keep the Rofi interface clean.

### 6. Google Chrome Web Apps (PWAs)
* **Launcher Script:** [open_web_app.sh](file:///home/georgek/.config/scripts/open_web_app.sh)
* **Execution:** Runs Google Chrome in `--app="<URL>"` mode to remove browser chrome, turning sites like YouTube, Gmail, and Gemini into standalone desktop windows.
* **App Icons & Titles:**
  - Chrome generates domain window classes (e.g. `chrome-mail.google.com__-Default`).
  - Waybar icons are assigned in [workspace_names.py](file:///home/georgek/.config/scripts/workspace_names.py).
  - Rofi switcher names/icons are mapped in [window_switcher.py](file:///home/georgek/.config/scripts/window_switcher.py).

---

## 📂 Utility Scripts Index

All custom desktop scripts are located in `~/.config/scripts/`:

| Script | Purpose & Function |
| :--- | :--- |
| [setup.sh](file:///home/georgek/.config/scripts/setup.sh) | Automated system installer, package setup, service configuration, and GTK/SDDM provisioning. |
| [rotate-wallpaper.sh](file:///home/georgek/.config/scripts/rotate-wallpaper.sh) | Rotates desktop wallpapers and syncs active image to SDDM login screen. |
| [window_switcher.py](file:///home/georgek/.config/scripts/window_switcher.py) | Rofi-based window switcher with custom app title/icon mappings. |
| [workspace_names.py](file:///home/georgek/.config/scripts/workspace_names.py) | Background daemon updating Waybar workspace titles and Nerd Font app icons dynamically. |
| [open_web_app.sh](file:///home/georgek/.config/scripts/open_web_app.sh) | Launches URLs in Google Chrome standalone PWA app mode. |
| [cliphist-menu.sh](file:///home/georgek/.config/scripts/cliphist-menu.sh) | Rofi clipboard history manager. |
| [keybindings.sh](file:///home/georgek/.config/scripts/keybindings.sh) | Interactive Rofi menu listing all active Hyprland keyboard shortcuts. |
| [go_to_media_player.py](file:///home/georgek/.config/scripts/go_to_media_player.py) | Finds and focuses the window/workspace currently playing active media. |
| [screenshot.sh](file:///home/georgek/.config/scripts/screenshot.sh) | Region, active window, and full-screen screenshot tool. |
| [toggle-launcher.sh](file:///home/georgek/.config/scripts/toggle-launcher.sh) | Toggles Rofi application launcher menu. |

---

## 🛠️ Guide: Adding Custom Applications

### Route A: Adding a Terminal App (e.g. `htop`)
1. **Create Desktop Entry** (`~/.local/share/applications/htop.desktop`):
   ```ini
   [Desktop Entry]
   Name=Htop
   Exec=kitty --class htop htop
   Terminal=false
   Type=Application
   Icon=htop
   ```
2. **Add Hyprland Keybind** in [binds.lua](file:///home/georgek/.config/hypr/conf/binds.lua):
   ```lua
   hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("kitty --class htop htop"), { description = "Open Htop" })
   ```
3. **Register Waybar Icon** in [workspace_names.py](file:///home/georgek/.config/scripts/workspace_names.py):
   ```python
   "htop": "",  # CPU icon
   ```
4. **Register Rofi Switcher** in [window_switcher.py](file:///home/georgek/.config/scripts/window_switcher.py):
   * `CLASS_MAP`: `"htop": "System Monitor"`
   * `ICON_MAP`: `"htop": "htop"`

---

### Route B: Adding a Web App / PWA (e.g. ChatGPT)
1. **Add Keybind** in [binds.lua](file:///home/georgek/.config/hypr/conf/binds.lua):
   ```lua
   hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(home .. "/.config/scripts/open_web_app.sh https://chat.openai.com/"), { description = "Open ChatGPT" })
   ```
2. **Identify Window Class:** Launch app and run `hyprctl clients` (class will resemble `chrome-chat.openai.com__-Default`).
3. **Register Waybar Icon** in [workspace_names.py](file:///home/georgek/.config/scripts/workspace_names.py):
   ```python
   "chrome-chat.openai.com": "󰚩",
   ```
4. **Register Rofi Switcher** in [window_switcher.py](file:///home/georgek/.config/scripts/window_switcher.py):
   * `CLASS_MAP`: `"chrome-chat.openai.com__-Default": "ChatGPT"`
   * `ICON_MAP`: `"chrome-chat.openai.com__-Default": "chatgpt"`

---

### Applying Changes
```bash
hyprctl reload

# Restart workspace daemon
killall -9 python3
export HYPRLAND_INSTANCE_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance')
export XDG_RUNTIME_DIR=/run/user/$(id -u)
nohup python3 ~/.config/scripts/workspace_names.py >/dev/null 2>&1 &
```

---

## 🚨 Troubleshooting

* **Workspace Icons Not Updating:** Restart the daemon:
  ```bash
  killall -9 python3
  export HYPRLAND_INSTANCE_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance')
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  nohup python3 ~/.config/scripts/workspace_names.py >/dev/null 2>&1 &
  ```
* **Gemini CLI Issues:** Reinstall globally via NPM:
  ```bash
  sudo npm install -g @google/gemini-cli@latest
  ```
* **Display / Monitor Behavior:** Adjust monitor layouts in `~/.config/hypr/conf/general.conf` or `hyprland.conf`.
