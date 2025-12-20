# Modular Zsh Configuration

This directory contains the modular Zsh configuration system. Instead of a single monolithic `.zshrc` file, the configuration is split into numbered modules that are concatenated during installation.

## Table of Contents

- [Why Modular?](#why-modular)
- [Module Structure](#module-structure)
- [Module Descriptions](#module-descriptions)
- [Generation Process](#generation-process)
- [Making Changes](#making-changes)
- [Platform-Specific Configuration](#platform-specific-configuration)

## Why Modular?

### Traditional .zshrc Problems

A typical `.zshrc` file grows over time and becomes:
- **Hard to navigate**: Hundreds of lines with mixed concerns
- **Difficult to debug**: Where is this setting coming from?
- **Platform-messy**: macOS and Linux code intermingled
- **Unorganized**: No clear structure or sections

### Modular Solution

By splitting configuration into numbered modules:
- **Easy navigation**: Each file has a single purpose
- **Simple debugging**: Know exactly which file contains what
- **Platform-aware**: OS-specific code in separate files
- **Organized**: Clear, predictable structure
- **Maintainable**: Add new modules without touching existing ones

## Module Structure

```
zsh/
├── 10-zinit.zsh         # Plugin manager initialization
├── 20-completion.zsh    # Completion system setup
├── 30-history.zsh       # History configuration
├── 40-plugins.zsh       # Zinit plugin declarations
├── 50-prompt.zsh        # Starship prompt
├── 60-exports.zsh       # Environment variables
├── 70-aliases.zsh       # Command aliases
├── 80-functions.zsh     # Shell functions
├── 90-completions.zsh   # Additional completions
├── os/
│   ├── darwin.zsh       # macOS-specific config
│   └── linux.zsh        # Linux-specific config
└── distro/
    ├── ubuntu.zsh       # Ubuntu/Debian-specific config
    └── arch.zsh         # Arch Linux-specific config
```

### Numbering System

Modules are numbered **10-90 in increments of 10**, allowing insertion of new modules between existing ones.

Example: Need to add Docker config between functions (80) and completions (90)?
→ Create `85-docker.zsh`

## Module Descriptions

### 10-zinit.zsh - Plugin Manager

**Purpose**: Initialize Zinit plugin manager

**Contents**:
- Zinit installation path setup
- Auto-install Zinit if missing
- Zinit load and initialization

**Why first?**: All subsequent plugin declarations depend on Zinit being available.

```bash
# Example content
declare -A ZINIT
ZINIT[HOME_DIR]="${HOME}/.local/share/zinit"
ZINIT[BIN_DIR]="${ZINIT[HOME_DIR]}/bin"

# Auto-install Zinit
if [[ ! -f ${ZINIT[BIN_DIR]}/zinit.zsh ]]; then
  print -P "%F{33}▓▒░ Installing Zinit...%f"
  command mkdir -p "${ZINIT[HOME_DIR]}"
  command git clone https://github.com/zdharma-continuum/zinit.git "${ZINIT[BIN_DIR]}"
fi

source "${ZINIT[BIN_DIR]}/zinit.zsh"
```

### 20-completion.zsh - Completion System

**Purpose**: Configure Zsh's powerful completion system

**Contents**:
- Enable compinit (completion initialization)
- Completion options (case-insensitive, menu selection)
- Completion caching
- Match behavior

**Key Settings**:
```bash
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
```

### 30-history.zsh - History

**Purpose**: Configure command history behavior

**Contents**:
- History file location
- History size limits
- History options (share between sessions, remove duplicates)

**Key Settings**:
```bash
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
```

### 40-plugins.zsh - Zinit Plugins

**Purpose**: Declare all Zinit plugins to load

**Contents**:
- Plugin declarations using Zinit syntax
- Oh-My-Zsh snippets
- Binary tools

**Example Plugins**:
```bash
# Syntax highlighting (load last for best performance)
zinit light zsh-users/zsh-syntax-highlighting

# Autosuggestions
zinit ice wait lucid atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

# Oh-My-Zsh plugins
zinit snippet OMZP::kubectl
zinit snippet OMZP::docker

# Fast syntax highlighting (alternative)
zinit ice wait lucid
zinit light zdharma-continuum/fast-syntax-highlighting
```

**Optimization**: Use `wait` and `lucid` for faster startup.

### 50-prompt.zsh - Starship Prompt

**Purpose**: Initialize Starship prompt

**Contents**:
- Starship initialization
- Prompt customization

**Key Setting**:
```bash
eval "$(starship init zsh)"
```

**Note**: Starship config is in `~/.config/starship.toml`, not here.

### 60-exports.zsh - Environment Variables

**Purpose**: Export environment variables

**Contents**:
- Editor preferences
- PATH modifications
- Tool-specific environment variables
- Language/SDK paths

**Example Exports**:
```bash
# Editor
export EDITOR='nvim'
export VISUAL='nvim'

# PATH additions
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# Tool configs
export FZF_DEFAULT_OPTS='--height 40% --border'
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# Language SDKs
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
```

### 70-aliases.zsh - Command Aliases

**Purpose**: Define command shortcuts

**Contents**:
- Common command aliases
- Git aliases
- Navigation shortcuts
- Tool-specific aliases

**Example Aliases**:
```bash
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# Tools
alias vim='nvim'
alias v='nvim'
alias k='kubectl'
alias tf='terraform'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
```

### 80-functions.zsh - Shell Functions

**Purpose**: Define reusable shell functions

**Contents**:
- Utility functions
- Complex operations
- Multi-command workflows

**Example Functions**:
```bash
# Create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Git commit with message
gcm() {
  git commit -m "$1"
}

# Extract any archive
extract() {
  case $1 in
    *.tar.gz)  tar xzf $1   ;;
    *.zip)     unzip $1     ;;
    *.rar)     unrar x $1   ;;
    *)         echo "Unknown archive type" ;;
  esac
}
```

### 90-completions.zsh - Additional Completions

**Purpose**: Load tool-specific completions

**Contents**:
- kubectl completion
- Custom completion sources
- Third-party completions

**Example Completions**:
```bash
# kubectl
source <(kubectl completion zsh)

# Custom completions
[ -f ~/.kubectl_aliases ] && source ~/.kubectl_aliases

# fzf key bindings
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
```

## Generation Process

When you run `./install`, the following happens:

### 1. Header Creation
```bash
cat > zshrc << 'HEADER'
#!/bin/zsh
# ═══════════════════════════════════════════════════════════════════════════
# ⚠️  AUTOGENERATED FILE - DO NOT EDIT MANUALLY
# ═══════════════════════════════════════════════════════════════════════════
# This file is automatically generated during dotfiles installation.
# To make changes, edit the modular files in ~/.dotfiles/zsh/ instead:
#   - Core modules: 10-zinit.zsh through 90-completions.zsh
#   - OS-specific: os/darwin.zsh, os/linux.zsh
#   - Distro-specific: distro/ubuntu.zsh, distro/arch.zsh
# Then run ./install to regenerate this file.
# ═══════════════════════════════════════════════════════════════════════════
HEADER
```

### 2. Core Module Concatenation

```bash
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

### 3. OS Detection

```bash
case "$(uname -s)" in
  Darwin)
    echo "" >> zshrc
    echo "# macOS-specific Configuration" >> zshrc
    cat zsh/os/darwin.zsh >> zshrc
    ;;
  Linux)
    echo "" >> zshrc
    echo "# Linux-specific Configuration" >> zshrc
    cat zsh/os/linux.zsh >> zshrc
    ;;
esac
```

### 4. Distro Detection (Linux Only)

```bash
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

### 5. Output

Single `zshrc` file at repository root, symlinked to `~/.zshrc`.

## Making Changes

### Edit Existing Module

1. Edit the relevant module:
   ```bash
   vim ~/.dotfiles/zsh/70-aliases.zsh
   ```

2. Regenerate `zshrc`:
   ```bash
   cd ~/.dotfiles
   ./install
   ```

3. Reload shell:
   ```bash
   exec zsh
   ```

### Add New Module

1. Create file with next available number:
   ```bash
   vim ~/.dotfiles/zsh/85-docker.zsh
   ```

2. Update `install.conf.yaml` to include new module:
   ```bash
   # Edit line ~29 in install.conf.yaml
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

3. Regenerate and reload:
   ```bash
   ./install
   exec zsh
   ```

### Test Changes Without Installing

Source module directly:
```bash
source ~/.dotfiles/zsh/70-aliases.zsh
```

**Note**: This won't affect the generated `zshrc`. Only for testing.

## Platform-Specific Configuration

### OS-Specific Modules

**os/darwin.zsh** (macOS):
```bash
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
# eval "$(/usr/local/bin/brew shellenv)"   # Intel

# macOS-specific aliases
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'

# macOS-specific environment variables
export BROWSER='open'
```

**os/linux.zsh** (Linux):
```bash
# Linux-specific aliases
alias open='xdg-open'
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

# Linux-specific environment variables
export BROWSER='firefox'
```

### Distro-Specific Modules

**distro/ubuntu.zsh** (Ubuntu/Debian):
```bash
# Package manager aliases
alias update='sudo apt update && sudo apt upgrade'
alias install='sudo apt install'
alias remove='sudo apt remove'

# Ubuntu-specific paths
export PATH="/snap/bin:$PATH"
```

**distro/arch.zsh** (Arch Linux):
```bash
# Package manager aliases
alias update='yay -Syu'
alias install='yay -S'
alias remove='yay -R'

# Arch-specific paths
export PATH="$HOME/.local/bin:$PATH"
```

## Debugging

### Find Which Module Defines Something

```bash
# Find which module contains an alias
grep -r "alias gs=" ~/.dotfiles/zsh/

# Find which module sets a variable
grep -r "EDITOR" ~/.dotfiles/zsh/
```

### View Generated zshrc

```bash
cat ~/.dotfiles/zshrc
```

### Profile Startup Time

```bash
# Add to top of a module
zmodload zsh/zprof

# Add to bottom of 90-completions.zsh
zprof
```

Then reload shell to see profiling output.

### Disable a Module Temporarily

Comment out in `install.conf.yaml`:
```bash
cat zsh/10-zinit.zsh \
    zsh/20-completion.zsh \
    zsh/30-history.zsh \
    # zsh/40-plugins.zsh \    # DISABLED FOR TESTING
    zsh/50-prompt.zsh \
    ...
```

## Best Practices

1. **Keep modules focused**: One concern per file
2. **Use descriptive comments**: Explain non-obvious code
3. **Group related items**: Organize aliases/functions by category
4. **Optimize for speed**: Use `wait` and `lucid` for plugins
5. **Test before committing**: Verify changes don't break shell
6. **Follow naming convention**: `NN-description.zsh` format
7. **Document complex functions**: Add usage examples

## Related Documentation

- [CONTRIBUTING.md](../docs/CONTRIBUTING.md) - How to extend and customize
- [STRUCTURE.md](../docs/STRUCTURE.md) - Repository architecture
- [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) - Common issues
