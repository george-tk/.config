#!/usr/bin/env bash
set -e

# ----------------------------------------------------------
# Variables & Colors
# ----------------------------------------------------------
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NONE='\033[0m'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CONFIG_DIR=$(dirname "$SCRIPT_DIR")

# Detect Real User (if running as sudo)
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
fi

# ----------------------------------------------------------
# Core Packages List
# ----------------------------------------------------------
PACKAGES=(
    # System & Core
    "wget"
    "unzip"
    "git"
    "gum"
    "jq"
    "cronie"
    "flatpak"
    "brightnessctl"
    "networkmanager"
    "bluez"
    "bluez-utils"
    "blueman"
    
    # Desktop Environment
    "hyprland"
    "xdg-desktop-portal-hyprland"
    "waybar"
    "rofi-wayland"
    "dunst"
    "sddm"
    "hyprpaper"
    "hyprlock"
    "hypridle"
    "wlogout"
    "qt5-wayland"
    "qt6-wayland"

    # Terminal & Shell
    "kitty"
    "zsh"
    "zoxide"
    "oh-my-posh"
    "fastfetch"
    "vim"
    "neovim"
    "ripgrep"
    "fd"
    "fzf"
    "tree-sitter-cli"

    # Apps
    "thunar"
    "google-chrome"
    "pavucontrol"
    "wireplumber"
    "wl-clipboard"
    "cliphist"

    # Development
    "nodejs"
    "npm"

    # Fonts
    "ttf-font-awesome"
    "ttf-fira-sans"
    "ttf-fira-code"
    "ttf-firacode-nerd"
    "ttf-jetbrains-mono-nerd"

    # GTK Themes
    "catppuccin-gtk-theme-mocha"
    "catppuccin-cursors-mocha"
    "papirus-icon-theme"
)

# ----------------------------------------------------------
# Helper Functions
# ----------------------------------------------------------

log_info() { echo -e "${BLUE}:: $1${NONE}"; }
log_success() { echo -e "${GREEN}:: $1${NONE}"; }
log_warn() { echo -e "${YELLOW}:: $1${NONE}"; }
log_error() { echo -e "${RED}:: $1${NONE}"; }

# Ensure script is run with sudo
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script with sudo."
    exit 1
fi

# ----------------------------------------------------------
# 1. Base Setup (Yay & Base Devel)
# ----------------------------------------------------------
setup_base() {
    log_info "Updating system and installing base-devel..."
    pacman -Sy --needed --noconfirm base-devel git

    if ! command -v yay &> /dev/null; then
        log_info "Installing yay..."
        local yay_dir="/tmp/yay_install_temp"
        rm -rf "$yay_dir"
        
        # Clone as the real user to avoid permission issues
        sudo -u "$REAL_USER" git clone https://aur.archlinux.org/yay.git "$yay_dir"
        
        cd "$yay_dir"
        sudo -u "$REAL_USER" makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
        rm -rf "$yay_dir"
        log_success "yay installed successfully."
    else
        log_success "yay is already installed."
    fi
}

# ----------------------------------------------------------
# 2. Package Installation
# ----------------------------------------------------------
install_packages() {
    log_info "Installing packages..."
    
    # Use yay to install everything at once (handles deps and prevents loops)
    # We run yay as the real user
    sudo -u "$REAL_USER" yay -S --needed --noconfirm "${PACKAGES[@]}"
    
    log_success "All packages installed."
}

# ----------------------------------------------------------
# 3. NPM Configuration
# ----------------------------------------------------------
setup_npm() {
    log_info "Configuring NPM for user: $REAL_USER"
    
    local npm_global_dir="$REAL_HOME/.npm-global"
    
    # Create directory and set permissions
    mkdir -p "$npm_global_dir"
    chown -R "$REAL_USER:$REAL_USER" "$npm_global_dir"
    
    # Configure npm prefix
    sudo -u "$REAL_USER" npm config set prefix "$npm_global_dir"
    
    # Install Gemini CLI
    log_info "Installing @google/gemini-cli..."
    sudo -u "$REAL_USER" npm install -g @google/gemini-cli
}

# ----------------------------------------------------------
# 4. SDDM & System Configuration
# ----------------------------------------------------------
setup_sddm() {
    log_info "Configuring SDDM..."
    
    if [ -d "$CONFIG_DIR/sddm/themes" ]; then
        mkdir -p /usr/share/sddm/themes
        cp -r "$CONFIG_DIR/sddm/themes/"* /usr/share/sddm/themes/
        log_success "SDDM themes installed."
    fi

    if [ -f "$CONFIG_DIR/sddm/sddm.conf" ]; then
        cp "$CONFIG_DIR/sddm/sddm.conf" /etc/sddm.conf
        log_success "SDDM config installed."
    fi
}

# ----------------------------------------------------------
# 5. Cron Setup (Wallpaper Rotation)
# ----------------------------------------------------------
setup_cron() {
    log_info "Setting up Wallpaper Rotation Cron Job..."
    local rotate_script="$CONFIG_DIR/scripts/rotate-wallpaper.sh"
    
    if [ -f "$rotate_script" ]; then
        chmod +x "$rotate_script"
        local cron_cmd="*/15 * * * * $rotate_script"
        
        # Add cron job idempotently for the real user
        sudo -u "$REAL_USER" bash -c "crontab -l 2>/dev/null | grep -vF \"$rotate_script\" | cat - <(echo \"$cron_cmd\") | crontab -"
        log_success "Cron job updated."
    else
        log_warn "Rotate script not found at $rotate_script"
    fi
}

# ----------------------------------------------------------
# 6. Service Enabling
# ----------------------------------------------------------
enable_services() {
    log_info "Enabling system services (will start on next boot)..."
    # standard services
    systemctl enable sddm
    systemctl enable NetworkManager
    systemctl enable bluetooth
    systemctl enable cronie
}

# ----------------------------------------------------------
# 7. GTK Configuration
# ----------------------------------------------------------
setup_gtk() {
    log_info "Configuring GTK Themes for Catppuccin Mocha Blue..."
    
    local gtk3_dir="$REAL_HOME/.config/gtk-3.0"
    mkdir -p "$gtk3_dir"
    
    # Update settings.ini
    cat > "$gtk3_dir/settings.ini" <<EOF
[Settings]
gtk-theme-name=catppuccin-mocha-blue-standard+default
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=catppuccin-mocha-blue-cursors
gtk-application-prefer-dark-theme=1
EOF
    
    # Set gsettings for GTK4 and desktop services
    sudo -u "$REAL_USER" gsettings set org.gnome.desktop.interface gtk-theme "catppuccin-mocha-blue-standard+default"
    sudo -u "$REAL_USER" gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
    sudo -u "$REAL_USER" gsettings set org.gnome.desktop.interface cursor-theme "catppuccin-mocha-blue-cursors"
    sudo -u "$REAL_USER" gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

    chown -R "$REAL_USER:$REAL_USER" "$gtk3_dir"
    log_success "GTK settings applied."
}

# ----------------------------------------------------------
# 8. Shell & Dotfiles
# ----------------------------------------------------------
setup_shell() {
    log_info "Setting up Zsh and Dotfiles..."
    
    # Link .zshrc
    if [ -f "$CONFIG_DIR/zsh/zshrc" ]; then
        # Backup existing .zshrc if it's not a symlink
        if [ -f "$REAL_HOME/.zshrc" ] && [ ! -L "$REAL_HOME/.zshrc" ]; then
            mv "$REAL_HOME/.zshrc" "$REAL_HOME/.zshrc.bak"
            log_info "Backed up existing .zshrc to .zshrc.bak"
        fi
        
        # Create symlink as the user
        sudo -u "$REAL_USER" ln -sf "$CONFIG_DIR/zsh/zshrc" "$REAL_HOME/.zshrc"
        log_success "Linked .zshrc"
    fi

    # Change default shell to zsh
    if [ "$SHELL" != "/usr/bin/zsh" ] && [ -x "/usr/bin/zsh" ]; then
        log_info "Changing default shell to zsh for $REAL_USER..."
        chsh -s /usr/bin/zsh "$REAL_USER"
    fi
}

# ----------------------------------------------------------
# Main Execution
# ----------------------------------------------------------

clear
cat <<'EOF'
   ____    __          
  / __/__ / /___ _____ 
 _\ \/ -_) __/ // / _ \
/___/\__/\__/",_/ .__/
                /_/    
Hyprland Starter for Arch based distros
EOF

# 1. Network Check
if ! ping -c 1 google.com &>/dev/null; then
    log_error "No internet connection. Please connect to the internet first."
    exit 1
fi

# 2. Optimized Prompt (Standard read because gum isn't installed yet)
echo -ne "${YELLOW}:: Start installation? (y/N): ${NONE}"
read -r start_install
if [[ ! "$start_install" =~ ^[Yy]$ ]]; then
    log_warn "Installation canceled."
    exit 0
fi

# 3. Pacman Optimization (Parallel Downloads)
if grep -q "#ParallelDownloads" /etc/pacman.conf; then
    log_info "Enabling parallel downloads in pacman..."
    sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
fi

# 4. Pacman Update
pacman -Sy --noconfirm

setup_base
install_packages

# 5. Flatpak Remotes
if command -v flatpak &> /dev/null; then
    log_info "Adding Flathub remote..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

setup_npm
setup_sddm
setup_cron
enable_services
setup_gtk
setup_shell

echo
log_success "Installation complete!"
if gum confirm "Reboot now?" --default=true; then
    reboot
else
    log_info "Please reboot manually to finalize the setup."
fi
