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
    "curl"
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
    "nwg-displays"
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
    "less"
    "tree-sitter-cli"
    "lsof"
    "imagemagick"

    # Apps & File Management
    "thunar"
    "thunar-volman"
    "thunar-archive-plugin"
    "thunar-media-tags-plugin"
    "gvfs"
    "gvfs-mtp"
    "udisks2"
    "file-roller"
    "p7zip"
    "unrar"
    "tumbler"
    "ffmpegthumbnailer"
    "poppler-glib"
    "webp-pixbuf-loader"
    "libgsf"
    "dosfstools"
    "exfatprogs"
    "ntfs-3g"
    "google-chrome"
    "pavucontrol"
    "wireplumber"
    "wl-clipboard"
    "cliphist"
    "wtype"
    "playerctl"
    "network-manager-applet"

    # Development
    "nodejs"
    "npm"

    # Fonts
    "ttf-font-awesome"
    "ttf-jetbrains-mono-nerd"

    # GTK Themes
    "catppuccin-gtk-theme-mocha"
    "catppuccin-cursors-mocha"
    "papirus-icon-theme"

    # SDDM QML dependencies
    "qt5-quickcontrols"
    "qt5-quickcontrols2"
    "qt5-graphicaleffects"
    "qt5-svg"
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

# Enable temporary passwordless sudo for REAL_USER during setup
# so sub-processes (yay, makepkg, pacman) won't prompt for passwords repeatedly
SUDOERS_TEMP="/etc/sudoers.d/99_hyprland_setup_temp"
cleanup_sudoers() {
    rm -f "$SUDOERS_TEMP"
}
trap cleanup_sudoers EXIT INT TERM

if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
    echo "$REAL_USER ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_TEMP"
    chmod 0440 "$SUDOERS_TEMP"
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
        sudo -u "$REAL_USER" -H git clone https://aur.archlinux.org/yay.git "$yay_dir"
        
        cd "$yay_dir"
        sudo -u "$REAL_USER" -H makepkg -si --noconfirm
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
    log_info "Synchronizing system and installing packages..."
    
    # Changed -S to -Syu to ensure the whole system stays in sync
    # This prevents the "breaks dependency" errors you just saw
    sudo -u "$REAL_USER" -H yay -Syu --needed --noconfirm "${PACKAGES[@]}"
    
    log_success "All packages installed and system updated."
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
    sudo -u "$REAL_USER" -H npm config set prefix "$npm_global_dir"
}

# ----------------------------------------------------------
# 3b. Antigravity Configuration
# ----------------------------------------------------------
setup_antigravity() {
    log_info "Installing Antigravity CLI for user: $REAL_USER"
    
    # Ensure ~/.local/bin exists
    local local_bin_dir="$REAL_HOME/.local/bin"
    mkdir -p "$local_bin_dir"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local"
    
    # Install via official curl script run as real user
    sudo -u "$REAL_USER" -H bash -c "curl -fsSL https://antigravity.google/cli/install.sh | bash"
}

# ----------------------------------------------------------
# 3c. OpenCode AI Configuration
# ----------------------------------------------------------
setup_opencode() {
    log_info "Installing OpenCode CLI for user: $REAL_USER"
    
    local opencode_bin="$REAL_HOME/.opencode/bin/opencode"
    if [ ! -f "$opencode_bin" ] && ! command -v opencode &> /dev/null; then
        sudo -u "$REAL_USER" -H bash -c "curl -fsSL https://opencode.ai/install.sh | bash"
        log_success "OpenCode CLI installed."
    else
        log_success "OpenCode CLI is already installed."
    fi
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

    # Set up shared active wallpaper file for seamless SDDM transition
    log_info "Setting up shared SDDM wallpaper sync file..."
    local sddm_wallpaper_file="/var/lib/sddm-wallpaper.jpg"
    touch "$sddm_wallpaper_file"
    chown "$REAL_USER:sddm" "$sddm_wallpaper_file"
    chmod 664 "$sddm_wallpaper_file"
    
    # Initialize the wallpaper copy
    if [ -f "$CONFIG_DIR/scripts/rotate-wallpaper.sh" ]; then
        sudo -u "$REAL_USER" -H bash "$CONFIG_DIR/scripts/rotate-wallpaper.sh" || log_warn "Initial wallpaper rotation sync skipped."
    fi
    log_success "SDDM wallpaper sync file configured."
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
        sudo -u "$REAL_USER" -H bash -c "crontab -l 2>/dev/null | grep -vF \"$rotate_script\" | cat - <(echo \"$cron_cmd\") | crontab -"
        log_success "Cron job updated."
    else
        log_warn "Rotate script not found at $rotate_script"
    fi
}
# ----------------------------------------------------------
# X. Time & Localization Configuration
# ----------------------------------------------------------
setup_timezone() {
    log_info "Configuring Timezone (Europe/London) and NTP..."
    
    # Set the timezone
    timedatectl set-timezone Europe/London
    
    # Ensure Hardware Clock is set to UTC (The Linux standard)
    hwclock --systohc
    
    # Enable Network Time Synchronization (NTP)
    timedatectl set-ntp true
    
    # Force systemd-timesyncd to enable/start just in case
    systemctl enable --now systemd-timesyncd
    
    log_success "Timezone set to Europe/London and NTP enabled."
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
    systemctl enable systemd-timesyncd
}

# ----------------------------------------------------------
# 6b. Clamshell Mode & Display Configuration
# ----------------------------------------------------------
setup_clamshell() {
    log_info "Configuring systemd-logind for Laptop Clamshell mode..."
    mkdir -p /etc/systemd/logind.conf.d
    cat > /etc/systemd/logind.conf.d/lid.conf <<'EOF'
[Login]
HandleLidSwitch=suspend
HandleLidSwitchDocked=ignore
HandleLidSwitchExternalPower=ignore
EOF
    log_success "Clamshell mode configuration created in /etc/systemd/logind.conf.d/lid.conf"
}

# ----------------------------------------------------------
# 7. GTK & Theme Configuration
# ----------------------------------------------------------
setup_gtk() {
    log_info "Configuring GTK, Icons & Cursor Themes for Catppuccin Mocha..."
    
    local gtk3_dir="$REAL_HOME/.config/gtk-3.0"
    local gtk4_dir="$REAL_HOME/.config/gtk-4.0"
    local icons_def="$REAL_HOME/.icons/default"
    mkdir -p "$gtk3_dir" "$gtk4_dir" "$icons_def"
    
    # Update GTK 3 & 4 settings.ini
    cat > "$gtk3_dir/settings.ini" <<EOF
[Settings]
gtk-theme-name=catppuccin-mocha-lavender-standard+default
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=catppuccin-mocha-dark-cursors
gtk-cursor-theme-size=24
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-application-prefer-dark-theme=1
EOF
    cp "$gtk3_dir/settings.ini" "$gtk4_dir/settings.ini"

    # Default XCursor inheritance
    cat > "$icons_def/index.theme" <<EOF
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=catppuccin-mocha-dark-cursors
EOF
    
    # Set gsettings for GTK4 and desktop services
    sudo -u "$REAL_USER" -H gsettings set org.gnome.desktop.interface gtk-theme "catppuccin-mocha-lavender-standard+default" 2>/dev/null || true
    sudo -u "$REAL_USER" -H gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
    sudo -u "$REAL_USER" -H gsettings set org.gnome.desktop.interface cursor-theme "catppuccin-mocha-dark-cursors" 2>/dev/null || true
    sudo -u "$REAL_USER" -H gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
    sudo -u "$REAL_USER" -H gsettings set org.gnome.desktop.interface font-name "JetBrainsMono Nerd Font 11" 2>/dev/null || true
    sudo -u "$REAL_USER" -H gsettings set org.gnome.desktop.interface monospace-font-name "JetBrainsMono Nerd Font 11" 2>/dev/null || true
    sudo -u "$REAL_USER" -H gsettings set org.gnome.desktop.interface document-font-name "JetBrainsMono Nerd Font 11" 2>/dev/null || true
    sudo -u "$REAL_USER" -H gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true

    chown -R "$REAL_USER:$REAL_USER" "$gtk3_dir" "$gtk4_dir" "$icons_def" "$REAL_HOME/.config"
    log_success "GTK and cursor settings applied."
}

# ----------------------------------------------------------
# 7b. Thunar & File Management Configuration
# ----------------------------------------------------------
setup_thunar() {
    log_info "Configuring Thunar and File Management..."

    # Configure Papirus folder icons to sleek grey
    log_info "Setting Papirus folder icons to grey..."
    if command -v papirus-folders &>/dev/null; then
        papirus-folders -C grey -t Papirus-Dark -u 2>/dev/null || true
    else
        curl -sL https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders -o /usr/local/bin/papirus-folders 2>/dev/null || true
        chmod +x /usr/local/bin/papirus-folders 2>/dev/null || true
        /usr/local/bin/papirus-folders -C grey -t Papirus-Dark -u 2>/dev/null || true
    fi

    # Disable built-in inactive XFCE wallpaper plugin (so only Hyprland wallpaper action appears)
    local xfce_wallpaper_plugin="/usr/lib/thunarx-3/thunar-wallpaper-plugin.so"
    if [ -f "$xfce_wallpaper_plugin" ]; then
        log_info "Disabling inactive XFCE wallpaper plugin..."
        rm -f "$xfce_wallpaper_plugin"
    fi

    log_success "Thunar configured successfully."
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
            chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.zshrc.bak" 2>/dev/null || true
            log_info "Backed up existing .zshrc to .zshrc.bak"
        fi
        
        # Create symlink as the user
        sudo -u "$REAL_USER" -H ln -sf "$CONFIG_DIR/zsh/zshrc" "$REAL_HOME/.zshrc"
        log_success "Linked .zshrc"
    fi

    # Change default shell to zsh
    if [ "$SHELL" != "/usr/bin/zsh" ] && [ -x "/usr/bin/zsh" ]; then
        log_info "Changing default shell to zsh for $REAL_USER..."
        chsh -s /usr/bin/zsh "$REAL_USER"
    fi

    # Install custom desktop applications launchers
    if [ -d "$CONFIG_DIR/applications" ]; then
        log_info "Installing custom desktop entries..."
        local dest_apps="$REAL_HOME/.local/share/applications"
        mkdir -p "$dest_apps"
        cp "$CONFIG_DIR/applications/"* "$dest_apps/"
        
        # User-independent path adjustment in launcher files
        sed -i "s|/home/[^/]*|$REAL_HOME|g" "$dest_apps/"*.desktop 2>/dev/null || true
        
        chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local"
        log_success "Custom desktop entries installed."
    fi

    # Streamline Application Launcher (Hide unwanted helper / dependency GUI entries)
    log_info "Hiding unwanted application launcher entries..."
    local dest_apps="$REAL_HOME/.local/share/applications"
    mkdir -p "$dest_apps"
    local hide_apps=(
        "avahi-discover.desktop"
        "bssh.desktop"
        "bvnc.desktop"
        "xgps.desktop"
        "xgpsspeed.desktop"
        "lstopo.desktop"
        "xfce4-about.desktop"
        "rofi.desktop"
        "rofi-theme-selector.desktop"
        "thunar-bulk-rename.desktop"
        "thunar-settings.desktop"
        "blueman-adapters.desktop"
        "vim.desktop"
    )
    for app in "${hide_apps[@]}"; do
        cat > "$dest_apps/$app" <<'EOF'
[Desktop Entry]
Type=Application
Name=Hidden
Hidden=true
NoDisplay=true
EOF
    done
    chown -R "$REAL_USER:$REAL_USER" "$dest_apps"
    log_success "Unwanted launcher entries hidden."

    # Set up custom icons for Chrome web apps in Rofi window switcher
    log_info "Installing custom web app icons for window switcher..."
    local dest_icons="$REAL_HOME/.local/share/icons/hicolor/scalable/apps"
    mkdir -p "$dest_icons"
    ln -sf "/usr/share/icons/Papirus/64x64/apps/gmail.svg" "$dest_icons/chrome-mail.google.com__-default.svg"
    ln -sf "/usr/share/icons/Papirus/64x64/apps/gmail.svg" "$dest_icons/chrome-mail.google.com_-default.svg"
    ln -sf "/usr/share/icons/Papirus/64x64/apps/gemini.svg" "$dest_icons/chrome-gemini.google.com__-default.svg"
    ln -sf "/usr/share/icons/Papirus/64x64/apps/gemini.svg" "$dest_icons/chrome-gemini.google.com_-default.svg"
    ln -sf "/usr/share/icons/Papirus/64x64/apps/youtube.svg" "$dest_icons/chrome-www.youtube.com__-default.svg"
    ln -sf "/usr/share/icons/Papirus/64x64/apps/youtube.svg" "$dest_icons/chrome-www.youtube.com_-default.svg"
    
    sudo -u "$REAL_USER" -H gtk-update-icon-cache -f -t "$REAL_HOME/.local/share/icons/hicolor" 2>/dev/null || true
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local/share/icons" "$REAL_HOME/.local"
    log_success "Custom web app icons installed."

    # Ensure all helper and daemon scripts are executable
    log_info "Setting execute permissions on all helper and daemon scripts..."
    chmod +x "$CONFIG_DIR/scripts/"*.py "$CONFIG_DIR/scripts/"*.sh || true
}

# ----------------------------------------------------------
# 9. Initramfs Optimization (The New Function)
# ----------------------------------------------------------
setup_initramfs() {
    if [ -f /etc/mkinitcpio.conf ]; then
        log_info "Surgically replacing udev hook with systemd..."
        
        if grep -q "^HOOKS=.*udev" /etc/mkinitcpio.conf; then
            sed -i '/^HOOKS=/s/\budev\b/systemd/g' /etc/mkinitcpio.conf
            log_success "HOOKS line updated in /etc/mkinitcpio.conf"
            
            log_info "Regenerating initramfs presets..."
            mkinitcpio -P
            log_success "Initramfs optimized successfully."
        else
            log_warn "udev hook not found on the HOOKS line. Skipping modification."
        fi
    else
        log_error "/etc/mkinitcpio.conf not found!"
    fi
}

# ----------------------------------------------------------
# 10. Fix Permissions & Ownership
# ----------------------------------------------------------
fix_permissions() {
    log_info "Restoring ownership of user configuration and data files to $REAL_USER..."
    
    # Ensure all user config and local files under $REAL_HOME are owned by $REAL_USER
    chown -R "$REAL_USER:$REAL_USER" \
        "$REAL_HOME/.config" \
        "$REAL_HOME/.local" \
        "$REAL_HOME/.cache" \
        "$REAL_HOME/.opencode" \
        "$REAL_HOME/.npm-global" 2>/dev/null || true

    if [ -f "$REAL_HOME/.zshrc" ]; then
        chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.zshrc"
    fi
    if [ -f "$REAL_HOME/.zshrc.bak" ]; then
        chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.zshrc.bak"
    fi
    
    log_success "User permissions restored successfully."
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
setup_antigravity
setup_opencode
setup_sddm
setup_timezone
setup_cron
enable_services
setup_clamshell
setup_gtk
setup_thunar
setup_shell
setup_initramfs
fix_permissions

echo
log_success "Installation complete!"
if gum confirm "Reboot now?" --default=true; then
    reboot
else
    log_info "Please reboot manually to finalize the setup."
fi
