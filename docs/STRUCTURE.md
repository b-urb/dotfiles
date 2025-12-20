# Repository Structure

This document explains the organization of this dotfiles repository, how components relate to each other, and the design decisions behind the architecture.

## Table of Contents

- [Directory Overview](#directory-overview)
- [Component Documentation](#component-documentation)
- [Modular Zsh Architecture](#modular-zsh-architecture)
- [Secret Management Flow](#secret-management-flow)
- [Git Workflow](#git-workflow)
- [Platform-Specific Configurations](#platform-specific-configurations)

## Directory Overview

```
~/.dotfiles/
├── config/               # Application-specific configurations
│   ├── atuin/           # Shell history sync configuration
│   ├── codex/           # Codex AI assistant config
│   ├── i3/              # i3 window manager (Linux)
│   ├── k9s/             # Kubernetes TUI config
│   ├── lazygit/         # Git TUI config
│   ├── nvim/            # Neovim configuration
│   ├── sketchybar/      # macOS status bar (with plugins)
│   ├── skhd/            # macOS hotkey daemon
│   ├── spacebar/        # macOS status bar (alternative)
│   ├── sway/            # Sway window manager (Linux)
│   └── yabai/           # Yabai tiling WM (macOS)
│
├── zsh/                 # Modular shell configuration
│   ├── 10-zinit.zsh         # Plugin manager initialization
│   ├── 20-completion.zsh    # Completion system setup
│   ├── 30-history.zsh       # History configuration
│   ├── 40-plugins.zsh       # Zinit plugin declarations
│   ├── 50-prompt.zsh        # Starship prompt
│   ├── 60-exports.zsh       # Environment variables
│   ├── 70-aliases.zsh       # Command aliases
│   ├── 80-functions.zsh     # Shell functions
│   ├── 90-completions.zsh   # Additional completions
│   ├── os/
│   │   ├── darwin.zsh       # macOS-specific config
│   │   └── linux.zsh        # Linux-specific config
│   └── distro/
│       ├── ubuntu.zsh       # Ubuntu/Debian-specific config
│       └── arch.zsh         # Arch Linux-specific config
│
├── templates/           # Secret templates (tracked in git)
│   ├── .env.tmpl            # Base environment variables
│   ├── .env.darwin.tmpl     # macOS-specific env vars
│   ├── .env.linux.tmpl      # Linux-specific env vars
│   ├── gitconfig.tmpl       # Git configuration template
│   ├── bashrc.tmpl          # Bash configuration template
│   ├── codex.config.toml.tmpl  # Codex config template
│   └── README.md            # Template system documentation
│
├── scripts/             # Automation and utility scripts
│   ├── populate-secrets.sh  # Bitwarden → template population
│   ├── setup-bitwarden.sh   # Create Bitwarden folder structure
│   └── pre-commit.sh        # Git hook: sync secrets to Bitwarden
│
├── macos/               # macOS-specific files
│   ├── Brewfile             # Homebrew dependencies
│   └── ssh/
│       └── config           # SSH configuration
│
├── arch/                # Arch Linux-specific files
│   └── install_software.sh  # Package installation script
│
├── ubuntu/              # Ubuntu-specific files
│   └── install_software.sh  # Package installation script
│
├── kube/                # Kubernetes configuration
│   ├── config               # Merged kubeconfig (generated)
│   └── clusters/            # Individual cluster configs
│       └── merge_clusters.sh  # Merge script
│
├── wezterm/             # WezTerm terminal emulator config
│   ├── wezterm.lua          # Main configuration
│   └── ...                  # Additional modules
│
├── idasen-controller/   # Standing desk controller config
│
├── dotbot/              # Git submodule: Dotbot installer
│
├── install              # Main installation script (Dotbot entry point)
├── install.conf.yaml    # Dotbot configuration
│
├── .gitignore           # Ignore generated files and secrets
└── README.md            # Main documentation
```

## Component Documentation

### config/

Application-specific configuration files. Each subdirectory contains config for a single tool.

#### Key Components:

**nvim/**
- Neovim configuration using LazyVim
- Plugin management via Lazy.nvim
- Custom keybindings and LSP configurations
- Symlinked to `~/.config/nvim`

**wezterm/** (also at repository root)
- Modern GPU-accelerated terminal emulator
- Lua-based configuration
- Tab bar, keybindings, color schemes
- Symlinked to `~/.config/wezterm`

**yabai/** (macOS)
- Tiling window manager
- Configuration: `yabairc`
- Requires SIP partially disabled for full functionality
- Symlinked to `~/.config/yabai`

**skhd/** (macOS)
- Simple hotkey daemon
- Keybindings for Yabai window management
- Configuration: `skhdrc`
- Symlinked to `~/.config/skhd`

**sketchybar/** (macOS)
- Highly customizable macOS status bar
- Lua plugins for widgets (battery, CPU, network, etc.)
- Event-driven architecture
- Symlinked to `~/.config/sketchybar`

**i3/** and **sway/** (Linux)
- i3: X11-based tiling window manager
- Sway: Wayland compositor (i3-compatible)
- Configuration syntax is identical
- Symlinked to `~/.config/i3` and `~/.config/sway`

**k9s/**
- Kubernetes TUI (Terminal UI)
- Custom keybindings and color themes
- Symlinked to `~/.config/k9s`

**lazygit/**
- Git TUI with intuitive interface
- Custom keybindings and colors
- Symlinked to `~/.config/lazygit`

**atuin/**
- SQLite-based shell history sync
- Server/client architecture
- Replaces Ctrl+R with searchable history
- Symlinked to `~/.config/atuin`

### zsh/

Modular Zsh configuration system. Instead of a single monolithic `.zshrc`, configuration is split into numbered modules that are concatenated during installation.

#### Module Numbering System:

Modules are numbered 10-90 in increments of 10, allowing insertion of new modules between existing ones.

**Execution Order**:
1. `10-zinit.zsh` - Initialize Zinit plugin manager
2. `20-completion.zsh` - Set up completion system
3. `30-history.zsh` - Configure history settings
4. `40-plugins.zsh` - Load Zinit plugins
5. `50-prompt.zsh` - Set up Starship prompt
6. `60-exports.zsh` - Export environment variables
7. `70-aliases.zsh` - Define command aliases
8. `80-functions.zsh` - Define shell functions
9. `90-completions.zsh` - Additional completions (kubectl, etc.)

#### OS-Specific Modules:

- `os/darwin.zsh` - macOS-specific configuration (Homebrew paths, etc.)
- `os/linux.zsh` - Linux-specific configuration

#### Distro-Specific Modules:

- `distro/ubuntu.zsh` - Ubuntu/Debian-specific configuration
- `distro/arch.zsh` - Arch Linux-specific configuration

See [Modular Zsh Architecture](#modular-zsh-architecture) for detailed explanation.

### templates/

Secret templates using `{{PLACEHOLDER}}` syntax. These files are tracked in git and contain no actual secrets.

**Purpose**: Store configuration file structure while keeping secrets in Bitwarden.

**Workflow**:
1. Template files contain placeholders: `export GITHUB_PAT={{GITHUB_PAT}}`
2. `populate-secrets.sh` fetches secrets from Bitwarden
3. Placeholders replaced with actual values
4. Generated files written with 600 permissions (not tracked in git)

**Template Files**:
- `.env.tmpl` → `.env`
- `.env.darwin.tmpl` → `.env.darwin`
- `.env.linux.tmpl` → `.env.linux`
- `gitconfig.tmpl` → `gitconfig`
- `bashrc.tmpl` → `bashrc`
- `codex.config.toml.tmpl` → `config/codex/config.toml`

See [Secret Management Flow](#secret-management-flow) for detailed explanation.

### scripts/

Automation scripts for secret management and setup.

**populate-secrets.sh**
- Fetches secrets from Bitwarden CLI
- Replaces `{{PLACEHOLDERS}}` in templates
- Generates config files with actual secrets
- Downloads kubeconfig attachments
- Requires: `BW_SESSION` environment variable

**setup-bitwarden.sh**
- Creates required Bitwarden folder structure
- Folders: `dotfiles/env-vars/`, `dotfiles/kubeconfig/`
- One-time setup (or after Bitwarden reset)

**pre-commit.sh**
- Git pre-commit hook
- Syncs secrets FROM generated files BACK to Bitwarden
- Updates templates with placeholders
- Creates/updates Bitwarden items
- Backs up kubeconfigs as Bitwarden attachments
- Bidirectional sync ensures Bitwarden is source of truth

### macos/

macOS-specific files.

**Brewfile**
- Homebrew dependency manifest
- Install with: `brew bundle --file=macos/Brewfile`
- Includes:
  - CLI tools (git, jq, neovim, etc.)
  - GUI apps (WezTerm, etc.)
  - Fonts (Nerd Fonts)
  - Taps (koekeishiya/formulae for Yabai/SKHD)

**ssh/config**
- SSH client configuration
- Host-specific settings
- Symlinked to `~/.ssh/config` (macOS only)

### arch/ and ubuntu/

Linux distribution-specific package installation scripts.

**install_software.sh**
- Installs packages via system package manager
- Arch: `pacman` + `yay` (AUR helper)
- Ubuntu: `apt` + manual installations

### kube/

Kubernetes configuration management.

**clusters/**
- Individual cluster kubeconfig files
- Downloaded from Bitwarden attachments
- Each file is a standalone kubeconfig

**merge_clusters.sh**
- Merges individual cluster configs into single file
- Uses `KUBECONFIG` environment variable trick
- Output: `kube/config` (symlinked to `~/.kube/config`)

**Why separate cluster files?**
- Easier to manage individual clusters
- Can sync to Bitwarden as separate attachments
- Merge on installation for kubectl compatibility

### wezterm/

WezTerm terminal emulator configuration.

**wezterm.lua**
- Main configuration file
- Tab bar customization
- Keybindings
- Color schemes
- Font configuration

### idasen-controller/

Configuration for IKEA IDASEN standing desk controller (Bluetooth).

Platform-specific locations:
- macOS: `~/Library/Application Support/idasen-controller`
- Linux: `~/.config/idasen-controller`

### dotbot/ (submodule)

Git submodule containing the Dotbot installation framework.

**Purpose**: Automate symlink creation and configuration management.

**Key files**:
- `bin/dotbot` - Main executable
- Invoked by `./install` script

**Update submodule**:
```bash
git submodule update --remote dotbot
```

## Modular Zsh Architecture

### Design Philosophy

Traditional `.zshrc` files become unwieldy over time:
- Hard to navigate (hundreds of lines)
- Difficult to debug (where is this setting coming from?)
- Platform-specific code mixed with core config
- No clear organization

**Solution**: Split into numbered modules that are concatenated during installation.

### Generation Process

When you run `./install`, the following happens:

1. **Header Creation**
   ```zsh
   cat > zshrc << 'HEADER'
   #!/bin/zsh
   # ═══════════════════════════════════════════════════════════════════════════
   # ⚠️  AUTOGENERATED FILE - DO NOT EDIT MANUALLY
   # ═══════════════════════════════════════════════════════════════════════════
   ```

2. **Core Module Concatenation**
   ```zsh
   cat zsh/10-zinit.zsh \
       zsh/20-completion.zsh \
       zsh/30-history.zsh \
       zsh/40-plugins.zsh \
       zsh/50-prompt.zsh \
       zsh/60-exports.zsh \
       zsh/70-aliases.zsh \
       zsh/80-functions.zsh \
       zsh/90-completions.zsh >> zshrc
   ```

3. **OS Detection**
   ```zsh
   case "$(uname -s)" in
     Darwin)
       cat zsh/os/darwin.zsh >> zshrc
       ;;
     Linux)
       cat zsh/os/linux.zsh >> zshrc
       # Detect distro...
       ;;
   esac
   ```

4. **Distro Detection** (Linux only)
   ```zsh
   if [ -f /etc/os-release ]; then
     . /etc/os-release
     case "$ID" in
       ubuntu|debian)
         cat zsh/distro/ubuntu.zsh >> zshrc
         ;;
       arch|manjaro)
         cat zsh/distro/arch.zsh >> zshrc
         ;;
     esac
   fi
   ```

5. **Output**: Single `zshrc` file symlinked to `~/.zshrc`

### Benefits

- **Modularity**: Each concern isolated in its own file
- **Readability**: Small, focused files easier to understand
- **Platform-Aware**: OS/distro-specific code automatically included
- **Maintainability**: Add new modules without touching existing ones
- **Debuggability**: Know exactly which file contains a setting

### Making Changes

**To modify shell config**:
1. Edit the relevant module in `zsh/`
2. Run `./install` to regenerate `zshrc`
3. Reload shell: `exec zsh`

**To add new functionality**:
- Aliases → `zsh/70-aliases.zsh`
- Functions → `zsh/80-functions.zsh`
- Plugins → `zsh/40-plugins.zsh`
- Environment variables → `zsh/60-exports.zsh`

## Secret Management Flow

### Overview

This repository uses a **template-based secret management system** with Bitwarden CLI.

**Key Principle**: Never commit secrets to git. Store them in Bitwarden, inject at install time.

### Components

1. **Templates** (`templates/*.tmpl`) - Tracked in git
2. **Bitwarden CLI** - Fetches secrets
3. **populate-secrets.sh** - Performs replacement
4. **Generated files** - Ignored by git (`.gitignore`)
5. **pre-commit.sh** - Syncs changes back to Bitwarden

### Forward Flow (Bitwarden → Local)

```
┌──────────────────────────────────────────────────────────────┐
│ Bitwarden Vault                                              │
│                                                              │
│ dotfiles/env-vars/                                           │
│   ├── github-pat        (Password: ghp_xxxxxxxxxxxx)        │
│   ├── git-email         (Password: you@example.com)         │
│   ├── azure-tenant-id   (Password: xxx-xxx-xxx-xxx)         │
│   └── ...                                                    │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ bw list items --folderid <id>
                            │ (via populate-secrets.sh)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│ Template Files (git-tracked)                                 │
│                                                              │
│ templates/.env.tmpl:                                         │
│   export GITHUB_PAT={{GITHUB_PAT}}                           │
│   export GIT_EMAIL={{GIT_EMAIL}}                             │
│   export AZURE_TENANT_ID={{AZURE_TENANT_ID}}                 │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ String replacement
                            │ ${content//\{\{GITHUB_PAT\}\}/$value}
                            ▼
┌──────────────────────────────────────────────────────────────┐
│ Generated Files (git-ignored)                                │
│                                                              │
│ .env:                                                        │
│   export GITHUB_PAT=ghp_xxxxxxxxxxxx                         │
│   export GIT_EMAIL=you@example.com                           │
│   export AZURE_TENANT_ID=xxx-xxx-xxx-xxx                     │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ Dotbot symlink creation
                            ▼
┌──────────────────────────────────────────────────────────────┐
│ Home Directory                                               │
│                                                              │
│ ~/.env → ~/.dotfiles/.env (symlink)                          │
└──────────────────────────────────────────────────────────────┘
```

### Reverse Flow (Local → Bitwarden)

When you commit changes, `pre-commit.sh` syncs secrets back:

```
┌──────────────────────────────────────────────────────────────┐
│ You edit: .env                                               │
│   export NEW_SECRET=new_value                                │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ git commit
                            │ (triggers pre-commit.sh)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│ Parse .env file                                              │
│   For each KEY=VALUE:                                        │
│     1. Convert KEY to item-name (lowercase, dashes)          │
│     2. Check if item exists in Bitwarden                     │
│     3. Create or update item                                 │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│ Bitwarden Vault (updated)                                    │
│                                                              │
│ dotfiles/env-vars/                                           │
│   ├── github-pat                                             │
│   ├── new-secret  ← NEW ITEM CREATED                         │
│   └── ...                                                    │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│ Regenerate template with placeholders                        │
│                                                              │
│ templates/.env.tmpl:                                         │
│   export GITHUB_PAT={{GITHUB_PAT}}                           │
│   export NEW_SECRET={{NEW_SECRET}}  ← PLACEHOLDER ADDED      │
└──────────────────────────────────────────────────────────────┘
```

### Bidirectional Sync

This system ensures **Bitwarden is always the source of truth**:
- Install: Bitwarden → Templates → Generated files
- Commit: Generated files → Bitwarden → Templates (updated with placeholders)

## Git Workflow

### What's Tracked

Files committed to git:
- Templates (`templates/*.tmpl`)
- Shell modules (`zsh/*.zsh`)
- Config files (`config/*`)
- Scripts (`scripts/*.sh`)
- Platform-specific files (`macos/`, `arch/`, `ubuntu/`)
- Documentation (`*.md`)
- Installation config (`install.conf.yaml`)

### What's Ignored

Files in `.gitignore` (generated, not tracked):
- `.env`, `.env.darwin`, `.env.linux`
- `gitconfig`
- `bashrc`
- `zshrc`
- `kube/config`
- `kube/clusters/*` (except merge script)
- `config/codex/config.toml`

### Submodules

The repository uses Git submodules for external dependencies:
- `dotbot/` - Installation framework
- `wezterm/wezterm-session-manager/` - WezTerm plugin

**Clone with submodules**:
```bash
git clone --recursive <repo-url>
```

**Update submodules**:
```bash
git submodule update --init --recursive
git submodule update --remote
```

## Platform-Specific Configurations

### macOS

**Window Management**:
- Yabai: Tiling window manager
- SKHD: Hotkey daemon
- AeroSpace: Alternative tiling WM
- SketchyBar: Custom status bar

**Dependencies**: `macos/Brewfile`

**Conditionals** in `install.conf.yaml`:
```yaml
~/.ssh/config:
  if: '[ "$(uname)" = Darwin ]'
  path: macos/ssh/config
```

### Linux

**Window Management**:
- i3: X11 tiling WM
- Sway: Wayland compositor

**Distros**:
- Arch Linux: `arch/install_software.sh`
- Ubuntu: `ubuntu/install_software.sh`

**Conditionals** in `install.conf.yaml`:
```yaml
~/.config/i3:
  if: '[ "$(uname)" = Linux ]'
  path: config/i3/
```

### Cross-Platform

Tools that work on both macOS and Linux:
- Neovim
- WezTerm
- K9s
- Lazygit
- Starship
- Atuin
- Zsh + Zinit

These configs are symlinked unconditionally.

## Design Decisions

### Why Dotbot?

- Simple YAML configuration
- Handles symlinks, shell commands, cleanup
- Idempotent (safe to run multiple times)
- Minimal dependencies

### Why Bitwarden CLI?

- Self-hosted option (security)
- CLI access for automation
- Folder organization
- Attachment support (for kubeconfigs)
- Cross-platform

### Why Template System?

- Keep secrets out of git
- Maintain file structure in git
- Bidirectional sync (local ↔ Bitwarden)
- Transparent (can see what secrets exist via placeholders)

### Why Modular Zsh?

- Maintainability (small, focused files)
- Platform-aware (OS/distro detection)
- Extensibility (add modules without touching existing)
- Debuggability (know where settings come from)

## Next Steps

- See [SETUP.md](SETUP.md) for installation instructions
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- See [CONTRIBUTING.md](CONTRIBUTING.md) for customization guide
