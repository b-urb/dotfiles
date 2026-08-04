# Fedora WSL Workstation Setup

Small, auditable Fedora WSL setup extracted from the main dotfiles. It installs shell and terminal tooling without Chezmoi, Ansible, Bitwarden, Docker, GUI applications, secrets, kubeconfigs, or Windows administration.

## Requirements

- Fedora running under WSL
- Working `sudo` inside Fedora
- Network access to Fedora repositories, crates.io, GitHub, and `dl.k8s.io`
- Corporate proxy and CA configured through approved system settings when required

The installer never disables TLS verification and never creates passwordless sudo rules.

## Install

```bash
./fedora-wsl/install.sh \
  --git-name "Your Name" \
  --git-email "you@company.example"

exec zsh -l
```

Preview first:

```bash
./fedora-wsl/install.sh --dry-run
```

The script is idempotent. Existing shell files receive one guarded source line. Files replaced at standard application paths are backed up once under:

```text
~/.local/state/fedora-wsl-dotfiles/backups/
```

## Installed Tools

Fedora packages are preferred: Git, Git LFS, Zsh, FZF, Neovim, Atuin, Bat, Btop, Dua, Eza, fd, ripgrep, zoxide, Kubernetes client, and packaged Zsh plugins. Package availability varies by Fedora release.

Cargo installs missing Rust tools with their published lockfile. Starship and gping use Cargo when no configured Fedora package exists.

Pinned SHA-256-verified upstream releases provide kubectl, kubectx, kubens, and LazyGit only when no configured Fedora package already provides them.

The setup intentionally uses maintained `btop` instead of `bpytop`. Fedora `dig` remains unchanged instead of replacing it with the old `dog` client.

## Configuration

Managed files live under `~/.config/fedora-wsl-dotfiles`. Atuin and LazyGit use their standard config paths so their existing files are backed up before replacement.

Atuin is local-only:

- automatic synchronization disabled
- update network checks disabled
- daemon disabled
- common token/password command forms excluded from history

No SSH agent is started. Use company-approved SSH or credential tooling separately.

## Windows WezTerm

No Windows software is installed. If WezTerm is already available, copy:

```text
fedora-wsl/windows/.wezterm.lua
```

to:

```text
%USERPROFILE%\.wezterm.lua
```

The file detects the first WSL distribution whose registered name contains `fedora`, launches `zsh -l`, uses common Windows font fallbacks, and has no Bitwarden or external-plugin dependency.

If detection fails, inspect registered names from PowerShell:

```powershell
wsl --list --verbose
```

## Updating

Pull repository changes and rerun `./fedora-wsl/install.sh`. Pinned binary versions and checksums live near the top of the script for reviewable updates.

Cargo-managed tools are not force-upgraded on every run. Upgrade deliberately with `cargo install --locked <crate>` or remove the old binary before rerunning.

## Excluded

- Bitwarden CLI, desktop integration, and SSH agent bridge
- SSH keys and SSH configuration
- kubeconfig files and cluster secrets
- Docker and container services
- VS Code, extensions, AI tools, and language SDK collections
- Complete Neovim/LazyVim configuration
- Windows package installation and font installation
- macOS and Linux desktop/window-manager configuration
