# Dotfiles

Personal dotfiles for macOS, Linux (Arch/Ubuntu), and Windows, managed with [chezmoi](https://chezmoi.io) and Bitwarden.

## Bootstrap

**macOS / Linux**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:B-urb/dotfiles.git
```

**Windows** (PowerShell, run as Administrator)

```powershell
winget install twpayne.chezmoi
chezmoi init --apply git@github.com:B-urb/dotfiles.git
```

On Windows, chezmoi runs the `run_once_before_02` PowerShell script automatically to install Git, WezTerm, WSL, Scoop, and the Bitwarden CLI before placing any dotfiles.

chezmoi will prompt for a Bitwarden unlock and for a few machine-local settings (display server on Linux, whether to disable the Bitwarden SSH agent). It then renders all templates and places files.

If this is the first time setting up Bitwarden folders for these dotfiles, run `scripts/setup-bitwarden.sh` before the above.

## Daily use

```bash
chezmoi apply          # re-render templates and sync files to $HOME
chezmoi update         # pull latest from git, then apply
chezmoi edit ~/.zshrc  # open the source template in $EDITOR
chezmoi diff           # preview what would change
```

## How it works

**chezmoi** manages files in `$HOME` from a source directory (`~/.local/share/chezmoi`, which is this repo). It renders Go templates on apply and copies or symlinks the results.

Secrets never touch the repository. Files that contain secrets are `.tmpl` files in the source tree; the `bitwarden` template function fetches values from the vault at apply time.

```
dot_gitconfig.tmpl  →  ~/.gitconfig          (email from Bitwarden)
private_dot_env.tmpl  →  ~/.env              (global env vars, chmod 600)
private_dot_env.darwin.tmpl  →  ~/.env.darwin
private_dot_ssh/private_id_rsa.tmpl  →  ~/.ssh/id_rsa  (from BW SSH Key item)
dot_config/opencode/opencode.jsonc.tmpl  →  ~/.config/opencode/opencode.jsonc
```

The generated `~/.zshrc` is assembled from partials in `.chezmoitemplates/zsh/`. Edit those files and run `chezmoi apply` to regenerate.

## Software install

**macOS** — `brew bundle` runs automatically via a `run_onchange_after_` script whenever `Brewfile` changes.

**Linux** — run the appropriate script manually after `chezmoi apply`:

```bash
# Arch
./arch/install_software.sh

# Ubuntu
./ubuntu/install_software.sh
```

Rust crates (eza, zoxide, atuin, starship, etc.) are installed via:

```bash
./install_cargo.sh
```

**Windows** — the `run_once_before_02` PowerShell script installs the following via winget and Scoop:

- WezTerm, Git, WSL + Ubuntu
- Bitwarden Desktop (with SSH agent) and Bitwarden CLI
- neovim, ripgrep, fzf, jq, starship, lazygit, kubectl, helm
- Monaspace font

After the script runs, open Bitwarden Desktop and enable **Settings > App Settings > Enable SSH Agent** so that WezTerm picks up the SSH agent pipe.

## Bitwarden structure

Secrets are stored in these vault folders:

```
dotfiles/env-vars/    key/value login items (password field = value)
dotfiles/kubeconfig/  kubeconfig files as attachments on a secure note
dotfiles/ssh-keys/    SSH Key items (type 5), one per key pair
```

The pre-commit hook (`scripts/pre-commit.sh`) syncs kubeconfig files and SSH keys back to the vault on commit. Env vars are edited directly in Bitwarden; there is no reverse sync for those.

## Machine-local config

`chezmoi init` generates `~/.config/chezmoi/chezmoi.toml` with per-machine settings:

```toml
[data]
    disableBwSshAgent    = false   # set true to use system ssh-agent instead
    wmForceDisplayServer = ""      # "x11" or "wayland" to override auto-detect (Linux only)
```

Edit this file directly and run `chezmoi apply` to update the rendered output.

On Windows only WezTerm and the codex/opencode configs are placed. Shell configs (zshrc, bashrc, SSH keys, kubeconfigs) are excluded — those live inside WSL and are managed from there independently.

## Structure

```
.chezmoitemplates/zsh/   zshrc partials (00-env through 90-completions, os-darwin, os-linux, distro-*)
.chezmoiscripts/         run_once and run_onchange scripts (deps, brew bundle, kubeconfig merge)
dot_config/              ~/.config contents (nvim, k9s, wezterm, sketchybar, etc.)
private_dot_ssh/         SSH key templates rendered from Bitwarden
scripts/                 setup-bitwarden.sh, pre-commit.sh, checksum-utils.sh
kube/clusters/           kubeconfig files (gitignored, backed up to Bitwarden)
ssh/                     SSH keys (gitignored, backed up to Bitwarden)
Brewfile                 macOS packages
```
