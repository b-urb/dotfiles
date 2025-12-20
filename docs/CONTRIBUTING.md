# Contributing Guide

This guide explains how to customize and extend these dotfiles for your own needs.

## Table of Contents

- [Adding New Tools](#adding-new-tools)
- [Adding Shell Aliases and Functions](#adding-shell-aliases-and-functions)
- [Adding Secrets](#adding-secrets)
- [Adding Zsh Plugins](#adding-zsh-plugins)
- [Platform-Specific Configs](#platform-specific-configs)
- [Testing Changes](#testing-changes)
- [Git Workflow](#git-workflow)

## Adding New Tools

To add configuration for a new tool, follow these steps:

### Step 1: Create Config Directory

Create a directory in `config/` for your tool:
```bash
mkdir -p ~/.dotfiles/config/mytool
```

### Step 2: Add Configuration Files

Create your config files:
```bash
cat > ~/.dotfiles/config/mytool/config.yml << 'EOF'
# Your tool configuration
setting: value
EOF
```

### Step 3: Add Symlink to install.conf.yaml

Edit `~/.dotfiles/install.conf.yaml` and add to the `link` section:

```yaml
- link:
    # ... existing entries ...

    ~/.config/mytool:
      path: config/mytool
      create: true
```

**Options**:
- `create: true` - Create parent directory if it doesn't exist
- `relink: true` - Replace existing symlink
- `force: true` - Replace existing file (use with caution)

### Step 4: Platform-Specific Symlink (Optional)

If your tool only works on specific platforms:

```yaml
~/.config/mytool:
  if: '[ "$(uname)" = Darwin ]'  # macOS only
  path: config/mytool
  create: true
```

Or for Linux:
```yaml
~/.config/mytool:
  if: '[ "$(uname)" = Linux ]'  # Linux only
  path: config/mytool
  create: true
```

### Step 5: Run Installation

Apply changes:
```bash
cd ~/.dotfiles
./install
```

Verify symlink was created:
```bash
ls -la ~/.config/mytool
```

## Adding Shell Aliases and Functions

### Adding Aliases

Edit `~/.dotfiles/zsh/70-aliases.zsh`:

```bash
# Custom aliases
alias myalias='command to run'
alias gs='git status'
alias ll='ls -lah'
```

**Alias Categories** (for organization):
```bash
# ──────────────────────────────────────────────────────────────────────────
# Git Aliases
# ──────────────────────────────────────────────────────────────────────────
alias gs='git status'
alias gp='git push'

# ──────────────────────────────────────────────────────────────────────────
# Directory Navigation
# ──────────────────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
```

### Adding Functions

Edit `~/.dotfiles/zsh/80-functions.zsh`:

```bash
# Create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Git commit with message
gcm() {
  git commit -m "$1"
}

# Find and replace in files
replace() {
  local search="$1"
  local replace="$2"
  local path="${3:-.}"

  rg "$search" -l "$path" | xargs sed -i '' "s/$search/$replace/g"
}
```

**Function Best Practices**:
- Add docstrings for complex functions
- Use `local` for variables
- Quote variables: `"$var"` not `$var`
- Provide usage examples in comments

### Applying Changes

After editing shell modules:
```bash
cd ~/.dotfiles
./install  # Regenerates zshrc
exec zsh   # Reload shell
```

## Adding Secrets

To add a new secret to the template system:

### Step 1: Add Placeholder to Template

Edit the appropriate template file:

**For general secrets** (`templates/.env.tmpl`):
```bash
export MY_NEW_SECRET={{MY_NEW_SECRET}}
```

**For macOS-specific** (`templates/.env.darwin.tmpl`):
```bash
export MACOS_SPECIFIC_SECRET={{MACOS_SPECIFIC_SECRET}}
```

**For Linux-specific** (`templates/.env.linux.tmpl`):
```bash
export LINUX_SPECIFIC_SECRET={{LINUX_SPECIFIC_SECRET}}
```

### Step 2: Create Bitwarden Item

Create the secret in Bitwarden CLI:

```bash
# Get folder ID
ENV_VARS_FOLDER_ID=$(bw list folders | jq -r '.[] | select(.name=="dotfiles/env-vars") | .id')

# Create item (convert env var name to lowercase with dashes)
# MY_NEW_SECRET → my-new-secret
bw get template item | \
  jq ".folderId=\"$ENV_VARS_FOLDER_ID\" | .type=1 | .name=\"my-new-secret\" | .login.password=\"your_secret_value_here\"" | \
  bw encode | \
  bw create item
```

**Naming Convention**:
- Environment variable: `MY_NEW_SECRET` (uppercase, underscores)
- Bitwarden item name: `my-new-secret` (lowercase, dashes)

### Step 3: Update populate-secrets.sh

Edit `~/.dotfiles/scripts/populate-secrets.sh` and add replacement line:

```bash
# Around line 78 in the populate_template() function
content="${content//\{\{MY_NEW_SECRET\}\}/$(get_secret "$ENV_VARS_FOLDER_ID" 'my-new-secret')}"
```

### Step 4: Update Documentation

Add your secret to `~/.dotfiles/templates/README.md`:

```markdown
| my-new-secret | Password | Description of what this secret is for |
```

### Step 5: Test

Populate secrets and verify:
```bash
export BW_SESSION=$(bw unlock --raw)
./scripts/populate-secrets.sh

# Check that placeholder was replaced
grep MY_NEW_SECRET ~/.dotfiles/.env
```

Should show actual value, not `{{MY_NEW_SECRET}}`.

## Adding Zsh Plugins

This configuration uses [Zinit](https://github.com/zdharma-continuum/zinit) as the plugin manager.

### Step 1: Add Plugin Declaration

Edit `~/.dotfiles/zsh/40-plugins.zsh`:

```bash
# Basic plugin (GitHub)
zinit light username/repo-name

# With options
zinit ice wait lucid
zinit light username/repo-name

# Oh-My-Zsh plugin
zinit snippet OMZP::plugin-name

# Program binary (installed via Zinit)
zinit ice as"program" pick"bin/tool"
zinit light username/tool-repo
```

### Step 2: Understand Zinit Ice Modifiers

**Common ice modifiers**:
- `wait` - Load plugin after prompt appears (faster startup)
- `lucid` - Don't show loading message
- `as"program"` - Install as binary
- `pick"file"` - Specify which file to source
- `atload"command"` - Run command after loading
- `atinit"command"` - Run command before loading

### Step 3: Example Plugins

```bash
# Syntax highlighting (load last)
zinit light zsh-users/zsh-syntax-highlighting

# Autosuggestions
zinit ice wait lucid atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

# Fast syntax highlighting (alternative)
zinit ice wait lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# Completions
zinit ice wait lucid blockf atpull"zinit creinstall -q ."
zinit light zsh-users/zsh-completions

# Oh-My-Zsh plugin
zinit snippet OMZP::kubectl

# Binary tool (fzf)
zinit ice from"gh-r" as"program"
zinit light junegunn/fzf
```

### Step 4: Regenerate and Test

```bash
cd ~/.dotfiles
./install
exec zsh
```

First load will download and compile plugins (30-60 seconds).

### Step 5: Optimize Startup Time

If shell startup is slow, use `wait` and `lucid`:

```bash
# Before (loads immediately)
zinit light username/plugin

# After (loads after prompt)
zinit ice wait lucid
zinit light username/plugin
```

Profile startup time:
```bash
time zsh -i -c exit
```

## Platform-Specific Configs

### macOS-Specific Configuration

Edit `~/.dotfiles/zsh/os/darwin.zsh`:

```bash
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# macOS-specific aliases
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# macOS-specific environment variables
export EDITOR='nvim'
```

### Linux-Specific Configuration

Edit `~/.dotfiles/zsh/os/linux.zsh`:

```bash
# Linux-specific aliases
alias open='xdg-open'
alias pbcopy='xclip -selection clipboard'

# Linux-specific environment variables
export EDITOR='nvim'
```

### Ubuntu-Specific Configuration

Edit `~/.dotfiles/zsh/distro/ubuntu.zsh`:

```bash
# Ubuntu package manager aliases
alias update='sudo apt update && sudo apt upgrade'

# Ubuntu-specific paths
export PATH="/snap/bin:$PATH"
```

### Arch Linux-Specific Configuration

Edit `~/.dotfiles/zsh/distro/arch.zsh`:

```bash
# Arch package manager aliases
alias update='yay -Syu'
alias pacman='sudo pacman'

# Arch-specific paths
export PATH="$HOME/.local/bin:$PATH"
```

### Adding Dependencies

**macOS** - Edit `~/.dotfiles/macos/Brewfile`:
```ruby
# CLI tools
brew "tool-name"

# GUI applications
cask "app-name"

# Fonts
cask "font-fira-code-nerd-font"
```

Install:
```bash
brew bundle --file=macos/Brewfile
```

**Arch Linux** - Edit `~/.dotfiles/arch/install_software.sh`:
```bash
# Official repositories
pacman_packages=(
  "package-name"
)

# AUR packages
aur_packages=(
  "aur-package-name"
)
```

**Ubuntu** - Edit `~/.dotfiles/ubuntu/install_software.sh`:
```bash
# APT packages
apt_packages=(
  "package-name"
)
```

## Testing Changes

### Test on Current System

```bash
# Make changes
vim ~/.dotfiles/zsh/70-aliases.zsh

# Regenerate configs
./install

# Test in new shell
exec zsh

# Verify changes
alias | grep myalias
```

### Test Without Installing

Source individual modules:
```bash
source ~/.dotfiles/zsh/70-aliases.zsh
```

### Test in Clean Environment

```bash
# Start new shell without loading config
zsh -f

# Manually source to test
source ~/.dotfiles/zshrc
```

### Test on Multiple Platforms

If you have access to different systems:
1. Commit changes to a branch
2. Clone on test system
3. Run installation
4. Verify platform-specific code works

### Validate YAML Syntax

Before committing changes to `install.conf.yaml`:
```bash
python3 -c "import yaml; yaml.safe_load(open('install.conf.yaml'))"
```

No output = valid YAML.

## Git Workflow

### Making Changes

```bash
# Create feature branch
git checkout -b feature/my-changes

# Make changes
vim config/nvim/init.lua

# Test changes
./install
```

### Committing Changes

```bash
# Stage changes
git add -A

# Commit (pre-commit hook will sync secrets)
export BW_SESSION=$(bw unlock --raw)
git commit -m "Add new feature"
```

**Pre-commit Hook**:
- Syncs secrets from local files to Bitwarden
- Updates templates with placeholders
- Backs up kubeconfigs

### Pushing Changes

```bash
git push origin feature/my-changes
```

### Keeping Up to Date

```bash
# Pull latest changes
git pull origin main

# Update submodules
git submodule update --init --recursive

# Re-run installation
./install
```

## Advanced Customization

### Creating New Zsh Module

If you have a lot of configuration for a specific topic, create a new module:

```bash
# Create new module (use next available number)
cat > ~/.dotfiles/zsh/85-docker.zsh << 'EOF'
# ═══════════════════════════════════════════════════════════════════════════
# Docker Configuration
# ═══════════════════════════════════════════════════════════════════════════

# Aliases
alias dps='docker ps'
alias dimg='docker images'

# Functions
dexec() {
  docker exec -it "$1" /bin/bash
}
EOF
```

**Update zshrc generation** in `install.conf.yaml` (around line 29):
```bash
cat zsh/10-zinit.zsh \
    zsh/20-completion.zsh \
    zsh/30-history.zsh \
    zsh/40-plugins.zsh \
    zsh/50-prompt.zsh \
    zsh/60-exports.zsh \
    zsh/70-aliases.zsh \
    zsh/80-functions.zsh \
    zsh/85-docker.zsh \    # NEW MODULE
    zsh/90-completions.zsh >> zshrc
```

### Custom Dotbot Plugins

Dotbot supports custom plugins. See [Dotbot documentation](https://github.com/anishathalye/dotbot#plugins) for details.

### Environment-Specific Overrides

Create `~/.zshrc.local` for machine-specific config (not tracked in git):

```bash
# In ~/.zshrc.local
export CUSTOM_PATH="/my/local/path"
alias localonly='echo "This machine only"'
```

Source at end of generated `zshrc`:
```bash
# Add to zsh/90-completions.zsh
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
```

## Best Practices

1. **Keep secrets in Bitwarden** - Never commit secrets to git
2. **Test before committing** - Run `./install` and verify changes work
3. **Use descriptive commit messages** - Explain what and why
4. **Document complex changes** - Add comments for non-obvious code
5. **Follow existing patterns** - Match the style of existing configs
6. **Keep modules focused** - Each module should have a single purpose
7. **Use platform conditionals** - Don't break other platforms with your changes

## Getting Help

- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- Review [STRUCTURE.md](STRUCTURE.md) to understand the architecture
- Search GitHub issues for similar problems
- Open a new issue with details about your customization

## Contributing Upstream

If you've made improvements that could benefit others:

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test on multiple platforms (if applicable)
5. Submit a pull request with:
   - Clear description of changes
   - Why the change is useful
   - Test results

Pull requests are welcome!
