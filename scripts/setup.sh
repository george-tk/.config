#!/usr/bin/env bash

# ----------------------------------------------------------
# Packages
# ----------------------------------------------------------

packages=(
    "wget"
    "unzip"
    "git"
    "gum"	
    "hyprland"
    "waybar"
    "rofi-wayland"
    "kitty"
    "dunst"
    "thunar"
    "xdg-desktop-portal-hyprland"
    "qt5-wayland"
    "qt6-wayland"
    "hyprpaper"
    "hyprlock"
    "firefox"
    "google-chrome"
    "sddm"
    "bluez"
    "bluez-utils"
    "blueman"
    "nodejs"
    "npm"
    "ttf-font-awesome"
    "vim"
    "fastfetch"
    "ttf-fira-sans" 
    "ttf-fira-code" 
    "ttf-firacode-nerd"
    "jq"
    "brightnessctl"
    "networkmanager"
    "wireplumber"
    "wlogout"
    "flatpak"
    "cronie"
)

# ----------------------------------------------------------
# Variables
# ----------------------------------------------------------

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONFIG_DIR=$(dirname "$SCRIPT_DIR")
USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)

if [ -z "$USER_HOME" ]; then
    USER_HOME=$HOME
fi

# ----------------------------------------------------------
# Colors
# ----------------------------------------------------------

GREEN='\033[0;32m'
NONE='\033[0m'

# ----------------------------------------------------------
# Check if command exists
# ----------------------------------------------------------

_checkCommandExists() {
    cmd="$1"
    if ! command -v "$cmd" >/dev/null; then
        echo 1
        return
    fi
    echo 0
    return
}

# ----------------------------------------------------------
# Check if package is already installed
# ----------------------------------------------------------

_isInstalled() {
    package="$1"
    check="$(sudo pacman -Qs --color always "${package}" | grep "local" | grep "${package} ")"
    if [ -n "${check}" ]; then
        echo 0
        return #true
    fi
    echo 1
    return #false
}

# ----------------------------------------------------------
# Install yay
# ----------------------------------------------------------

_installYay() {
    _installPackages "base-devel"
    
    # Create temp directory for yay
    yay_dir="$USER_HOME/yay_install_temp"
    if [ -d "$yay_dir" ]; then
        rm -rf "$yay_dir"
    fi
    mkdir -p "$yay_dir"
    git clone https://aur.archlinux.org/yay.git "$yay_dir"
    
    # Build yay as the non-root user
    current_dir=$(pwd)
    cd "$yay_dir"
    
    # If running as root (sudo), we need to run makepkg as the user
    if [ ! -z "$SUDO_USER" ]; then
        chown -R $SUDO_USER:$SUDO_USER "$yay_dir"
        sudo -u $SUDO_USER makepkg -si --noconfirm
    else
        makepkg -si --noconfirm
    fi
    
    cd "$current_dir"
    rm -rf "$yay_dir"
    echo ":: yay has been installed successfully."
}

# ----------------------------------------------------------
# Install packages
# ----------------------------------------------------------

_installPackages() {
    toInstall=()
    for pkg; do
        if [[ $(_isInstalled "${pkg}") == 0 ]]; then
            echo ":: ${pkg} is already installed."
            continue
        fi
        echo "Package not installed: ${pkg}"
        if [ ! -z "$SUDO_USER" ]; then
            sudo -u $SUDO_USER yay --noconfirm -S "${pkg}"
        else
            yay --noconfirm -S "${pkg}"
        fi
    done
}

# ----------------------------------------------------------
# Header
# ----------------------------------------------------------

clear
echo -e "${GREEN}"
cat <<'EOF'
   ____    __          
  / __/__ / /___ _____ 
 _\ \/ -_) __/ // / _ \
/___/\__/\__/",_/ .__/
                /_/    
ML4W Hyprland Starter for Arch based distros

EOF
echo -e "${NONE}"

# ----------------------------------------------------------
# Content
# ----------------------------------------------------------

while true; do
    read -p "DO YOU WANT TO START THE PACKAGE INSTALLATION NOW? (Yy/Nn): " yn
    case $yn in
        [Yy]*) 
            echo ":: Installation started."
            echo
            break
            ;; 
        [Nn]*) 
            echo ":: Installation canceled"
            exit
            break
            ;; 
        *) 
            echo ":: Please answer yes or no."
            ;; 
    esac
done

# Install yay if needed
if [[ $(_checkCommandExists "yay") == 0 ]]; then
    echo ":: yay is already installed"
else
    echo ":: The installer requires yay. yay will be installed now"
    _installYay
fi

# Packages
_installPackages "${packages[@]}"


# ----------------------------------------------------------
# NPM Packages
# ----------------------------------------------------------

echo ":: Installing global npm packages..."
if ! command -v npm &> /dev/null; then
    echo ":: npm is not installed. Skipping."
else
    if command -v gemini &> /dev/null; then
        echo ":: @google/gemini-cli is already installed."
    else
        echo ":: Installing @google/gemini-cli..."
        npm install -g @google/gemini-cli
    fi
fi

# ----------------------------------------------------------
# SDDM Configuration
# ----------------------------------------------------------
echo ":: Configuring SDDM..."
if [ -d "$CONFIG_DIR/sddm" ]; then
    # Copy themes
    if [ -d "$CONFIG_DIR/sddm/themes" ]; then
        echo ":: Installing SDDM themes..."
        mkdir -p /usr/share/sddm/themes
        cp -r "$CONFIG_DIR/sddm/themes/"* /usr/share/sddm/themes/
    fi

    # Copy config
    if [ -f "$CONFIG_DIR/sddm/sddm.conf" ]; then
        echo ":: Installing SDDM configuration..."
        cp "$CONFIG_DIR/sddm/sddm.conf" /etc/sddm.conf
    fi
else
    echo ":: No 'sddm' folder found in $CONFIG_DIR. Skipping SDDM config."
fi

# ----------------------------------------------------------
# Wallpaper Rotation (Cron)
# ----------------------------------------------------------
echo ":: Setting up Wallpaper Rotation Cron Job..."

ROTATE_SCRIPT="$CONFIG_DIR/scripts/rotate-wallpaper.sh"

if [ ! -f "$ROTATE_SCRIPT" ]; then
    echo ":: Error: Rotate script not found at $ROTATE_SCRIPT"
else
    # Ensure executable
    chmod +x "$ROTATE_SCRIPT"

    CRON_CMD="*/15 * * * * $ROTATE_SCRIPT"

    # Helper function to update cron safely
    _update_cron() {
        local user_cron
        user_cron=$(crontab -l 2>/dev/null)
        if [[ "$user_cron" != *"$ROTATE_SCRIPT"* ]]; then
            (echo "$user_cron"; echo "$CRON_CMD") | crontab -
            echo ":: Cron job added."
        else
            echo ":: Cron job already exists."
        fi
    }

    if [ ! -z "$SUDO_USER" ]; then
        # Running with sudo, switch to user
        sudo -u $SUDO_USER bash -c "$(declare -f _update_cron); ROTATE_SCRIPT='$ROTATE_SCRIPT' CRON_CMD='$CRON_CMD' _update_cron"
    else
        # Running as user
        _update_cron
    fi
fi

# ----------------------------------------------------------
# Enable Systemd Services
# ----------------------------------------------------------

_enableService() {
    service="$1"
    echo ":: Enabling service: $service"
    if systemctl is-active --quiet "$service"; then
        echo ":: $service is already running."
    else
        systemctl enable --now "$service"
        echo ":: $service enabled and started."
    fi
}

echo ":: Enabling essential systemd services..."
_enableService sddm
_enableService NetworkManager
_enableService bluetooth
_enableService cronie

echo ":: Services enabled."

# ----------------------------------------------------------
# Completed
# ----------------------------------------------------------

echo ":: Installation complete."
echo ":: Please reboot your system."
