#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Arch Linux software installation..."

# Update system
echo "Updating system..."
sudo pacman -Syu --noconfirm

# Install packages from pacman.txt
echo "Installing packages from pacman.txt..."
if [ -f "$SCRIPT_DIR/pacman.txt" ]; then
    # Read packages, skip comments and empty lines
    packages=$(grep -v '^#' "$SCRIPT_DIR/pacman.txt" | grep -v '^$' | tr '\n' ' ')
    if [ -n "$packages" ]; then
        sudo pacman -S --needed --noconfirm $packages
    fi
else
    echo "Warning: pacman.txt not found"
fi

# Install yay if not present
if ! command -v yay &>/dev/null; then
    echo "Installing yay (AUR helper)..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# Install AUR packages from yay file
echo "Installing AUR packages..."
if [ -f "$SCRIPT_DIR/yay" ]; then
    # Read AUR packages, skip comments and empty lines
    aur_packages=$(grep -v '^#' "$SCRIPT_DIR/yay" | grep -v '^$' | tr '\n' ' ')
    if [ -n "$aur_packages" ]; then
        yay -S --needed --noconfirm $aur_packages
    fi
else
    echo "Warning: yay file not found"
fi

# Initialize rustup if installed
if command -v rustup &>/dev/null; then
    echo "Initializing Rust toolchain..."
    rustup default stable
fi

# Enable and start Docker
if command -v docker &>/dev/null; then
    echo "Enabling Docker service..."
    sudo systemctl enable docker.service
    sudo systemctl start docker.service

    # Add user to docker group
    if ! groups $USER | grep -q docker; then
        echo "Adding $USER to docker group..."
        sudo usermod -aG docker $USER
        echo "Note: You'll need to log out and back in for docker group changes to take effect"
    fi
fi

# Install Neovim from source (latest stable)
echo "Installing Neovim from source..."
cd /tmp
git clone https://github.com/neovim/neovim
cd neovim
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
cd ..
rm -rf neovim

# Install AstroNvim configuration
if [ ! -d "$HOME/.config/nvim" ]; then
    echo "Installing AstroNvim configuration..."
    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
    rm -rf ~/.config/nvim/.git
else
    echo "Neovim config already exists, skipping AstroNvim installation"
fi

# Install Monaspace fonts
echo "Installing Monaspace fonts..."
cd /tmp
git clone https://github.com/githubnext/monaspace.git
cd monaspace
mkdir -p ~/.local/share/fonts
cp -r fonts/otf/* ~/.local/share/fonts/
fc-cache -f -v
cd ..
rm -rf monaspace

echo "Arch Linux software installation complete!"
echo "Note: Some changes may require a logout/login to take effect"
