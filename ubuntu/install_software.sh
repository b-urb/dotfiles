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

# i3
sudo apt install -y i3-wm

# CLI tools
sudo apt install -y zoxide fd-find ripgrep glances exa fzf duf bpytop \
  lsd git-lfs

# Graphics and multimedia
sudo apt install -y libjpeg-dev libpng-dev libtiff-dev libwebp-dev libopenjp2-7-dev \
  libheif-dev libraw-dev libass-dev libbluray-dev libharfbuzz-dev libglib2.0-dev \
  libpango1.0-dev libtbb-dev

# Libraries and scientific tools
sudo apt install -y \
  libhdf5-dev libnetcdf-dev

# install correct neovim version
sudo apt remove neovim neovim-runtime -y
sudo apt install ninja-build gettext cmake unzip curl
git clone https://github.com/neovim/neovim
cd neovim
make CMAKE_BUILD_TYPE=RelWithDebInfo
cd build
cpack -G DEB
sudo dpkg -i nvim-linux64.deb
cd ../..
rm -rf neovim
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
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  source "$HOME/.cargo/env"
fi

# Vim configuration
git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
rm -rf ~/.config/nvim/.git

# Github Monaspace
git clone git@github.com:githubnext/monaspace.git ~/fonts
bash ~/fonts/util/install_linux.sh
rm -rf ~/fonts
