# Dotfiles

> Personal dotfiles for macOS and Linux (Arch/Ubuntu), managed with Dotbot and Bitwarden

## Features

- 🔐 **Secret Management**: Bitwarden CLI integration for zero-commit secrets
- 🗝️ **SSH Agent**: Bitwarden Desktop SSH agent (default on, opt-out)
- 🧩 **Modular Shell**: Composable Zsh configuration (10+ modules)
- 🖥️ **Multi-Platform**: macOS (Yabai/SKHD/AeroSpace) + Linux (i3/Sway)
- 🔄 **Auto-Sync**: Pre-commit hooks sync secrets bidirectionally
- ⚡ **Modern Tools**: Neovim, WezTerm, K9s, Lazygit, Starship, Atuin

## Quick Start

### Prerequisites

1. **Bitwarden CLI**

   ```bash
   # macOS
   brew install bitwarden-cli

   # Linux
   sudo snap install bw
   ```

2. **Bitwarden Desktop (SSH Agent)**

   ```bash
   # macOS
   brew install --cask bitwarden

   # Linux (Flatpak)
   sudo apt install -y flatpak
   sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
   sudo flatpak install -y flathub com.bitwarden.desktop
   ```

3. **Git with SSH access** to this repository

4. **jq** (JSON processor)

   ```bash
   # macOS
   brew install jq

   # Linux (Ubuntu/Debian)
   sudo apt install jq

   # Linux (Arch)
   sudo pacman -S jq
   ```

### One-Line Installation

For a completely fresh system, run this command to bootstrap everything:

```bash
curl -fsSL https://raw.githubusercontent.com/B-urb/dotfiles/main/init.sh | bash
```

This will:

- Install Git and Bitwarden CLI
- Authenticate with Bitwarden
- Set up SSH keys from Bitwarden
- Clone the dotfiles repository
- Install all dependencies
- Run the full installation

### Manual Installation

If you prefer step-by-step installation:

```bash
# 1. Clone with submodules
git clone --recursive git@github.com:B-urb/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Configure and authenticate Bitwarden
bw config server https://warden.burbn.de
export BW_SESSION=$(bw unlock --raw)

# 3. First-time setup (creates Bitwarden folders)
./scripts/setup-bitwarden.sh

# 4. Populate Bitwarden secrets (manual step - see docs/SETUP.md)

# 5. Install dependencies
# macOS:
brew bundle --file=macos/Brewfile

# Arch Linux:
./arch/install_software.sh

# Ubuntu:
./ubuntu/install_software.sh

# 6. Run installation
./install
```

## Documentation

- **[📚 Detailed Setup Guide](docs/SETUP.md)** - Step-by-step installation with explanations
- **[🏗️ Repository Structure](docs/STRUCTURE.md)** - Architecture and component documentation
- **[🔧 Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[✨ Contributing](docs/CONTRIBUTING.md)** - How to extend and customize

## What Gets Installed

### Window Managers

- **macOS**: Yabai, SKHD, AeroSpace, SketchyBar
- **Linux**: i3, Sway

### Development Tools

- **Editor**: Neovim (LazyVim)
- **Terminal**: WezTerm + Starship prompt
- **Git UI**: Lazygit
- **Kubernetes**: K9s, kubectl aliases
- **Shell**: Zsh + Zinit + 20+ plugins
- **History**: Atuin (SQLite shell history sync)

### Secret Management

- Templates with `{{PLACEHOLDER}}` syntax
- Bitwarden CLI for secret injection
- Pre-commit hooks for bidirectional sync

## Key Concepts

### Template System

Secret-containing files use templates tracked in git:

```
templates/.env.tmpl       → .env (generated, not tracked)
templates/gitconfig.tmpl  → gitconfig (generated, not tracked)
templates/opencode.jsonc.tmpl → config/opencode/opencode.jsonc (generated, not tracked)
```

Secrets stored in Bitwarden folders:

- `dotfiles/env-vars/` - Environment variables (GitHub PAT, API keys, etc.)
- `dotfiles/kubeconfig/` - Kubernetes cluster configurations
- `dotfiles/ssh-keys/` - SSH key items (Bitwarden SSH Key type)

### SSH Agent

Bitwarden Desktop’s SSH agent is used by default. To opt out and force the local
`ssh-agent`, set in `options/dotfiles.options.sh` or
`options/dotfiles.options.local.sh`:

```
export DOTFILES_DISABLE_BITWARDEN_SSH_AGENT=1
export DOTFILES_ZELLIJ_MODE=native  # native|full|bridge

```

### Dotfiles Options

Feature flags live in:

- `options/dotfiles.options.sh` - tracked defaults
- `options/dotfiles.options.local.sh` - optional local overrides (not tracked)

Both `./install` and generated `~/.zshrc` load these options.

### Modular Zsh

Shell configuration split into numbered modules:

```
zsh/00-env.zsh → zsh/10-zinit.zsh → ... → zsh/90-completions.zsh
  + os/darwin.zsh (macOS) or os/linux.zsh (Linux)
  + distro/ubuntu.zsh or distro/arch.zsh
  = zshrc (auto-generated during install)
```

### Dotbot Installation

`./install` → Dotbot reads `install.conf.yaml`:

1. **Phase 1**: Populate secrets from Bitwarden
2. **Phase 2**: Generate zshrc from modular components
3. **Phase 3**: Merge kubeconfig files
4. **Phase 4**: Symlink configs to home directory
5. **Phase 5**: Clean up dead symlinks

## Project Structure

```
.
├── config/           # Application configs (nvim, k9s, yabai, etc.)
├── zsh/              # Modular shell configuration
│   ├── 10-zinit.zsh through 90-completions.zsh
│   ├── os/           # OS-specific (darwin.zsh, linux.zsh)
│   └── distro/       # Distro-specific (ubuntu.zsh, arch.zsh)
├── templates/        # Secret templates (tracked in git)
├── scripts/          # Automation scripts
│   ├── populate-secrets.sh   # Bitwarden → templates
│   ├── setup-bitwarden.sh    # Create folder structure
│   └── pre-commit.sh         # Sync secrets back to Bitwarden
├── macos/            # macOS-specific (Brewfile, ssh)
├── arch/             # Arch Linux packages
├── ubuntu/           # Ubuntu packages
├── kube/             # Kubernetes configs
└── wezterm/          # Terminal configuration
```

## Useful Tips

### IntelliJ IDEA with Yabai

To prevent Yabai from managing IntelliJ popups:

1. Enable full path in window header:
   - Go to: IntelliJ IDEA > Preferences > Appearance & behavior > Appearance
   - Check: "Always show full path in window header"

2. Add to yabai config:

   ```bash
   yabai -m rule --add app="IntelliJ IDEA" manage=off
   yabai -m rule --add app="IntelliJ IDEA" title=".*\[(.*)\].*" manage=on
   ```

This allows Yabai to manage the main window while leaving popups alone.

## License

MIT
