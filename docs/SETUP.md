# Detailed Setup Guide

This guide walks through the complete installation process for setting up these dotfiles on a new system.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Bitwarden Setup](#bitwarden-setup)
- [First-Time Installation](#first-time-installation)
- [What Happens During Install](#what-happens-during-install)
- [Post-Installation](#post-installation)
- [Updating Dotfiles](#updating-dotfiles)

## Prerequisites

### System Requirements

- **macOS**: 12 (Monterey) or later
- **Linux**: Ubuntu 20.04+, Arch Linux (current)
- **Disk Space**: ~500MB for dependencies

### Required Tools

Before starting, you need these tools installed:

#### 1. Git

Should already be installed on most systems. Verify:
```bash
git --version
```

If not installed:
```bash
# macOS (install Xcode Command Line Tools)
xcode-select --install

# Ubuntu/Debian
sudo apt install git

# Arch Linux
sudo pacman -S git
```

#### 2. Bitwarden CLI

Required for secret management:
```bash
# macOS
brew install bitwarden-cli

# Linux (using snap)
sudo snap install bw

# Arch Linux
yay -S bitwarden-cli
```

Verify installation:
```bash
bw --version
```

#### 3. jq (JSON processor)

Required by secret management scripts:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Arch Linux
sudo pacman -S jq
```

#### 4. SSH Access

You need SSH access configured for GitHub to clone this repository:
```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key and add to GitHub
cat ~/.ssh/id_ed25519.pub
```

Add the public key to your GitHub account: https://github.com/settings/keys

### Optional Tools

#### Homebrew (macOS)

While not strictly required, most macOS dependencies are installed via Homebrew:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Cargo (Rust)

Some tools (like Starship) can be installed via Cargo:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Bitwarden Setup

This repository uses Bitwarden CLI to manage secrets. You'll need to configure your Bitwarden server and create the required folder structure.

### Step 1: Configure Bitwarden Server

```bash
bw config server https://warden.burbn.de
```

### Step 2: Log In

```bash
bw login your-email@example.com
```

Enter your master password when prompted.

### Step 3: Unlock and Set Session

Every time you work with Bitwarden CLI, you need an active session:
```bash
export BW_SESSION=$(bw unlock --raw)
```

**Important**: The `BW_SESSION` environment variable is ephemeral and will expire. You'll need to re-run this command:
- After terminal restarts
- After session timeout (default: 15 minutes of inactivity)
- When you see "BW_SESSION not set" errors

### Step 4: Create Bitwarden Folder Structure

Run the setup script to create required folders:
```bash
cd ~/.dotfiles
./scripts/setup-bitwarden.sh
```

This creates the following nested folder structure in your Bitwarden vault:
```
dotfiles/
├── dotfiles/env-vars/     (for environment variables)
└── dotfiles/kubeconfig/   (for Kubernetes configurations)
```

### Step 5: Populate Bitwarden Secrets

You now need to manually add secrets to the `dotfiles/env-vars/` folder in your Bitwarden vault.

#### Required Items

The following items MUST exist in the `dotfiles/env-vars/` folder:

| Item Name | Type | Description | Example Value |
|-----------|------|-------------|---------------|
| `github-pat` | Password | GitHub Personal Access Token | `ghp_xxxxxxxxxxxx` |
| `git-email` | Password | Git commit email address | `you@example.com` |
| `azure-tenant-id` | Password | Azure Tenant ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `azure-username` | Password | Azure default username | `user@company.com` |

#### Optional Items

| Item Name | Type | Description |
|-----------|------|-------------|
| `directus-token` | Password | Directus API Bearer Token |
| `vault-token` | Password | HashiCorp Vault Token |
| `openai-api-key` | Password | OpenAI API Key |

#### Creating Items via CLI

You can create items using the Bitwarden CLI template API:

```bash
# Get the folder ID
ENV_VARS_FOLDER_ID=$(bw list folders | jq -r '.[] | select(.name=="dotfiles/env-vars") | .id')

# Create a new secret
bw get template item | \
  jq ".folderId=\"$ENV_VARS_FOLDER_ID\" | .type=1 | .name=\"github-pat\" | .login.password=\"ghp_your_token_here\"" | \
  bw encode | \
  bw create item
```

#### Creating Items via Web Vault

Alternatively, use the Bitwarden web interface:
1. Navigate to your vault
2. Find the `dotfiles/env-vars` folder
3. Click "Add Item"
4. Select type: "Login"
5. Name: Use the exact names from the table above (e.g., `github-pat`)
6. Password: Enter your secret value
7. Save

#### Syncing After Adding Items

After adding items via web vault, sync:
```bash
bw sync --session "$BW_SESSION"
```

## First-Time Installation

### Step 1: Clone Repository

Clone the repository with submodules (Dotbot and WezTerm session manager):
```bash
git clone --recursive git@github.com:B-urb/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

If you already cloned without `--recursive`, initialize submodules:
```bash
git submodule update --init --recursive
```

### Step 2: Authenticate Bitwarden

Ensure your Bitwarden session is active:
```bash
export BW_SESSION=$(bw unlock --raw)
```

### Step 3: Install Dependencies

Install platform-specific dependencies:

#### macOS

```bash
brew bundle --file=macos/Brewfile
```

This installs all tools defined in `macos/Brewfile` including:
- Window managers (Yabai, SKHD, AeroSpace)
- Status bars (SketchyBar)
- Development tools (Neovim, WezTerm, K9s, etc.)

#### Arch Linux

```bash
./arch/install_software.sh
```

This installs packages via `pacman` and AUR helper (`yay`).

#### Ubuntu

```bash
./ubuntu/install_software.sh
```

This installs packages via `apt`.

### Step 4: Run Installation

Execute the Dotbot installer:
```bash
./install
```

This will:
1. Populate secrets from Bitwarden
2. Generate modular zshrc
3. Merge kubeconfig files
4. Create symlinks to all config files
5. Clean up dead symlinks

### Step 5: Set Up Git Hooks (Optional but Recommended)

To enable automatic syncing of secrets back to Bitwarden:
```bash
ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Now, whenever you commit changes, secrets will be synced back to Bitwarden.

## What Happens During Install

When you run `./install`, Dotbot executes tasks defined in `install.conf.yaml`:

### Phase 1: Secret Population

**Script**: `scripts/populate-secrets.sh`

1. Verifies `BW_SESSION` is set
2. Retrieves folder IDs for `dotfiles/env-vars` and `dotfiles/kubeconfig`
3. Reads template files from `templates/`
4. Fetches secrets from Bitwarden
5. Replaces `{{PLACEHOLDERS}}` with actual values
6. Writes generated files with 600 permissions

**Generated files**:
- `.env` (from `templates/.env.tmpl`)
- `.env.darwin` or `.env.linux` (OS-specific)
- `gitconfig` (from `templates/gitconfig.tmpl`)
- `bashrc` (from `templates/bashrc.tmpl`)
- `config/codex/config.toml` (from `templates/codex.config.toml.tmpl`)

### Phase 2: Zshrc Generation

**Location**: Inline shell command in `install.conf.yaml` (lines 11-76)

1. Creates header warning (file is auto-generated)
2. Concatenates core modules in order:
   - `zsh/10-zinit.zsh` (plugin manager)
   - `zsh/20-completion.zsh` (completion system)
   - `zsh/30-history.zsh` (history settings)
   - `zsh/40-plugins.zsh` (Zinit plugins)
   - `zsh/50-prompt.zsh` (Starship prompt)
   - `zsh/60-exports.zsh` (environment variables)
   - `zsh/70-aliases.zsh` (command aliases)
   - `zsh/80-functions.zsh` (shell functions)
   - `zsh/90-completions.zsh` (additional completions)
3. Detects OS (`uname -s`)
4. Appends OS-specific config:
   - macOS: `zsh/os/darwin.zsh`
   - Linux: `zsh/os/linux.zsh`
5. If Linux, detects distro and appends:
   - Ubuntu/Debian: `zsh/distro/ubuntu.zsh`
   - Arch/Manjaro: `zsh/distro/arch.zsh`
6. Outputs to `zshrc` (root of dotfiles)

### Phase 3: Kubeconfig Merging

**Script**: `kube/clusters/merge_clusters.sh`

1. Downloads kubeconfig attachments from Bitwarden (if they exist)
2. Merges individual cluster configs into single `kube/config`
3. Sets proper permissions (600)

### Phase 4: Symlink Creation

**Dotbot**: Reads `link` section of `install.conf.yaml`

Creates symlinks from home directory to dotfiles repository:

```
~/.zshrc          → ~/.dotfiles/zshrc
~/.gitconfig      → ~/.dotfiles/gitconfig
~/.config/nvim    → ~/.dotfiles/config/nvim
~/.config/wezterm → ~/.dotfiles/wezterm
~/.kube/config    → ~/.dotfiles/kube/config
... and many more
```

Platform-specific symlinks are created based on `if` conditions:
- macOS: `~/.ssh/config`, `~/.aerospace.toml`, `~/.config/yabai`, etc.
- Linux: `~/.config/i3`, `~/.config/sway`

### Phase 5: Cleanup

**Dotbot**: Reads `clean` section of `install.conf.yaml`

Removes dead symlinks from:
- `~/.config` (recursive)
- `~/.kube` (recursive)
- `~/.ssh`

## Post-Installation

### Step 1: Reload Shell

Start a new terminal session or reload your shell:
```bash
exec zsh
```

On first load, Zinit will download and compile all plugins. This may take 30-60 seconds.

### Step 2: Verify Installation

Check that key symlinks exist:
```bash
ls -la ~/.zshrc ~/.gitconfig ~/.config/nvim ~/.config/wezterm
```

All should be symlinks pointing to `~/.dotfiles/...`

Test that tools are accessible:
```bash
nvim --version
wezterm --version
starship --version
```

### Step 3: Configure Neovim

On first launch, Neovim will install plugins:
```bash
nvim
```

Wait for LazyVim to finish installing plugins. Press `q` to exit the installation screen when done.

### Step 4: Test Window Manager (Optional)

#### macOS (Yabai)

Start Yabai and SKHD services:
```bash
brew services start yabai
brew services start skhd
```

**Note**: Yabai requires System Integrity Protection (SIP) to be partially disabled for full functionality. See [Yabai documentation](https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection) for details.

#### Linux (i3/Sway)

Log out and select i3 or Sway from your display manager.

## Updating Dotfiles

### Pull Latest Changes

```bash
cd ~/.dotfiles
git pull origin main
```

### Update Submodules

```bash
git submodule update --init --recursive
```

### Re-run Installation

After pulling changes, re-run the installer to update symlinks and regenerate configs:
```bash
./install
```

### Sync Secrets from Bitwarden

If secrets changed in Bitwarden:
```bash
export BW_SESSION=$(bw unlock --raw)
./scripts/populate-secrets.sh
```

### Sync Secrets to Bitwarden

If you edited secret files locally:
```bash
export BW_SESSION=$(bw unlock --raw)
./scripts/pre-commit.sh
```

Or simply commit your changes (if you set up the git hook):
```bash
git add -A
git commit -m "Update configurations"
```

The pre-commit hook will automatically sync secrets to Bitwarden.

## Common Issues

For troubleshooting common problems, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Next Steps

- Read [STRUCTURE.md](STRUCTURE.md) to understand the repository architecture
- Read [CONTRIBUTING.md](CONTRIBUTING.md) to learn how to customize and extend
- Explore individual tool configs in `config/` directory
- Customize your shell by editing files in `zsh/` (then re-run `./install`)
