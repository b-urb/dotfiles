#!/bin/bash
set -e
# Detect distribution: Debian or Ubuntu using /etc/os-release
if [ -f /etc/os-release ]; then
  DISTRO=$(grep '^ID=' /etc/os-release | cut -d= -f2)
  CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2)
else
  echo "Cannot detect distribution"
  exit 1
fi

echo "Detected distribution: $DISTRO $CODENAME"

# Install dependencies for apt-key and apt-transport-https for i3
if ! command -v curl &>/dev/null; then
  echo "curl is required to fetch keys, please install it first"
  exit 1
fi

# Add Repos
# wezterm
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

# add repos for i3 depending on distro
#if [ "$distro" == "debian" ]; then
#    # debian repository
#    curl https://baltocdn.com/i3-window-manager/signing.asc | sudo apt-key add -
#    echo "deb https://baltocdn.com/i3-window-manager/i3/i3-autobuild/ all main" | sudo tee /etc/apt/sources.list.d/i3-autobuild.list
#elif [ "$distro" == "ubuntu" ]; then
#    # ubuntu repository
# /usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2024.03.04_all.deb keyring.deb sha256:f9bb4340b5ce0ded29b7e014ee9ce788006e9bbfe31e96c09b2118ab91fca734
# sudo apt install ./keyring.deb
#echo "deb http://debian.sur5r.net/i3/ $(grep '^distrib_codename=' /etc/lsb-release | cut -f2 -d=) universe" | sudo tee /etc/apt/sources.list.d/sur5r-i3.list
#fi

# kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list # helps tools such as command-not-found to work correctly

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Flatpak + Bitwarden Desktop
sudo apt install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y flathub com.bitwarden.desktop

# Essential development tools
sudo apt install -y build-essential curl wget git \
  gcc g++ make cmake cmake-gui libboost-all-dev libeigen3-dev libusb-1.0-0-dev libpq-dev \
  htop jq neovim vim tmux docker-compose nodejs npm yarn golang-go \
  ffmpeg imagemagick sqlite3 openjdk-17-jdk maven gradle \
  fonts-hack-ttf fonts-jetbrains-mono fonts-noto-color-emoji apt-transport-https ca-certificates curl gnupg

# Networking tools
sudo apt install -y aria2 bat dos2unix iputils-ping ifstat net-tools \
  traceroute telnet sshuttle s3cmd kubectl

# Window Manager - Conditional based on display server type
source "$(dirname "$0")/../scripts/detect-display-server.sh"

DISPLAY_SERVER=$(detect_display_server)
if [ "$DISPLAY_SERVER" = "unknown" ]; then
    echo "⚠️  Display server type could not be detected (TTY or unknown environment)"
    echo "   Defaulting to X11 (i3-wm). To override, set: WM_FORCE_DISPLAY_SERVER=wayland"
    DISPLAY_SERVER="x11"
fi

echo "Installing window manager for: $DISPLAY_SERVER"

if [ "$DISPLAY_SERVER" = "wayland" ]; then
    # Sway and Wayland ecosystem
    echo "Installing Sway (Wayland) window manager and tools..."
    sudo apt install -y sway swaylock swayidle swaybg
    # Wayland-native tools
    sudo apt install -y waybar wofi grim slurp wl-clipboard
    echo "✓ Installed Sway window manager and Wayland tools"
else
    # i3 and X11 ecosystem
    echo "Installing i3 (X11) window manager and tools..."
    sudo apt install -y i3-wm i3lock i3status
    # Note: rofi (X11 launcher) is installed later at line 99
    echo "✓ Installed i3 window manager and X11 tools"
fi

# CLI tools
sudo apt install -y zsh zoxide fd-find ripgrep glances fzf duf bpytop \
  lsd git-lfs

# Graphics and multimedia
sudo apt install -y libjpeg-dev libpng-dev libtiff-dev libwebp-dev libopenjp2-7-dev \
  libheif-dev libraw-dev libass-dev libbluray-dev libharfbuzz-dev libglib2.0-dev \
  libpango1.0-dev libtbb-dev

# Libraries and scientific tools
sudo apt install -y \
  libhdf5-dev libnetcdf-dev

# install latest neovim
sudo apt remove neovim neovim-runtime -y || true

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    DISTRO=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
fi

if [ "$DISTRO" = "ubuntu" ]; then
    echo "Installing Neovim from PPA (Ubuntu)..."
    sudo add-apt-repository ppa:neovim-ppa/unstable -y
    sudo apt update
    sudo apt install -y neovim
elif [ "$DISTRO" = "debian" ]; then
    if command -v nvim &>/dev/null && [ "$(nvim --version | head -n1 | grep -oP 'v\d+\.\d+' | cut -d'v' -f2 | cut -d'.' -f1)" -ge "0" ]; then
        echo "Neovim already installed, skipping build"
    else
        echo "Installing Neovim from source (Debian - no PPA support)..."
        sudo apt install -y ninja-build gettext cmake unzip curl build-essential
        git clone https://github.com/neovim/neovim
        cd neovim
        make CMAKE_BUILD_TYPE=RelWithDebInfo
        cd build
        cpack -G DEB
        # Use correct package name (build creates nvim-linux-x86_64.deb)
        sudo dpkg -i nvim-linux-*.deb
        cd ../..
        rm -rf neovim
    fi
else
    echo "Unknown distribution, installing from apt..."
    sudo apt install -y neovim
fi
# install wezterm
sudo apt install wezterm-nightly

# Containers and Kubernetes
sudo apt install -y docker.io kubectl

# Version control and CI/CD tools
sudo apt install -y git git-filter-repo git-lfs

# install rofi launcher
sudo apt install -y rofi

# Install Cargo (Rust package manager)
if ! command -v cargo &>/dev/null; then
  echo "Installing Rust and Cargo..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
  echo "✓ Rust and Cargo installed"
else
  echo "Rust and Cargo already installed, skipping"
fi

# Github Monaspace fonts
if fc-list | grep -qi "monaspace"; then
    echo "Monaspace fonts already installed, skipping"
else
    echo "Installing Monaspace fonts..."
    # Clean up any previous failed clone
    rm -rf ~/fonts
    git clone https://github.com/githubnext/monaspace.git ~/fonts
    mkdir -p ~/.local/share/fonts
    # Copy all font types (NerdFonts, Static OTF, Variable TTF, Frozen TTF)
    # NerdFonts (OTF) - patched with icon glyphs for terminal use
    find ~/fonts/fonts/NerdFonts -name "*.otf" -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
    # Static Fonts (OTF) - includes all weights like Bold
    find ~/fonts/fonts/"Static Fonts" -name "*.otf" -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
    # Variable Fonts (TTF) - single variable font per family
    find ~/fonts/fonts/"Variable Fonts" -name "*.ttf" -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
    # Frozen Fonts (TTF) - includes all weights
    find ~/fonts/fonts/"Frozen Fonts" -name "*.ttf" -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
    # Rebuild font cache
    fc-cache -f
    rm -rf ~/fonts
    echo "✓ Monaspace fonts installed"
fi

# Nerd Fonts - popular patched fonts with icons
if fc-list | grep -qi "nerd font"; then
    echo "Nerd Fonts already installed, skipping"
else
    echo "Installing Nerd Fonts..."
    mkdir -p ~/.local/share/fonts

    # Download and install Nerd Fonts from latest release
    NERD_FONTS_VERSION="v3.3.0"
    NERD_FONTS=(
        "Hack"
        "JetBrainsMono"
        "FiraCode"
        "Meslo"
        "UbuntuMono"
    )

    for font in "${NERD_FONTS[@]}"; do
        echo "  Installing ${font} Nerd Font..."
        wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/${font}.zip" -O "/tmp/${font}.zip"
        unzip -qo "/tmp/${font}.zip" -d ~/.local/share/fonts/
        rm "/tmp/${font}.zip"
    done

    # Rebuild font cache
    fc-cache -f
    echo "✓ Nerd Fonts installed"
fi
