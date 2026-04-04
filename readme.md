# Dotfiles

Personal dotfiles for macOS, Linux (Arch/Ubuntu), and Windows, managed with [chezmoi](https://chezmoi.io) and Bitwarden.

## Bootstrap

**macOS / Linux**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/B-urb/dotfiles.git
```

**Windows** (PowerShell as Administrator for the first run)

The first run needs an elevated shell because enabling WSL and the Virtual Machine Platform are admin-only operations. After the initial setup, `chezmoi apply` and `chezmoi update` can be run from a normal PowerShell.

```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
winget install Git.Git twpayne.chezmoi
chezmoi init --apply https://github.com/B-urb/dotfiles.git
```

The init script enables the Virtual Machine Platform and WSL Windows features, installs Ubuntu, and exits asking for a reboot. After rebooting, open a normal PowerShell and run:

```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
bw login
$env:BW_SESSION = $(bw unlock --raw)
chezmoi apply
```

Then open WSL and bootstrap the Linux environment inside it:

```bash
wsl
# inside WSL:
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/B-urb/dotfiles.git
```

This runs the `wsl_ubuntu` Ansible role, which installs CLI tools, dev libraries, Rust, and shell configs inside WSL. GUI apps (WezTerm, Bitwarden Desktop), window managers, fonts, and Docker are skipped since they run on the Windows host.

On Windows, chezmoi runs the `run_once_before_02` PowerShell script automatically to install Git, WezTerm nightly, WSL, Scoop, and the Bitwarden CLI before placing any dotfiles.

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

Software provisioning is managed by an Ansible playbook (`ansible/local.yml`). chezmoi triggers it automatically via a `run_onchange_after_` script on first apply and again whenever any role or variable file changes.

To run it manually at any time:

```bash
ansible-playbook ansible/local.yml

# Override display server on Linux:
ansible-playbook ansible/local.yml --extra-vars "wm_display_server=wayland"
```

The playbook uses Ansible's fact-gathering to detect the OS and runs only the relevant roles:

| Platform | Roles |
|---|---|
| macOS | common, macos (homebrew formulae + casks), rust, vscode_extensions |
| Ubuntu/Debian | common, ubuntu (apt repos + packages + flatpak), linux_common (docker), wm_linux, fonts, rust, vscode_extensions |
| Arch | common, arch (pacman + yay + AUR), linux_common (docker), wm_linux, fonts, rust, vscode_extensions |
| WSL (Ubuntu) | common, wsl_ubuntu (apt repos + CLI packages, no GUI/docker/fonts), rust, vscode_extensions |

Package lists live in `ansible/roles/<role>/vars/main.yml`. Cargo crates and VS Code extensions are in `ansible/group_vars/all.yml` (shared across all platforms).

**Windows** — provisioned by the `run_once_before_02` PowerShell script (winget + Scoop). Installs WezTerm nightly (direct GitHub release download — winget nightly package is broken upstream), Git, WSL + Ubuntu, Bitwarden Desktop + CLI, core CLI tools, and Monaspace font. After it runs, enable **Settings > App Settings > Enable SSH Agent** in Bitwarden Desktop. The Linux environment inside WSL is provisioned separately via `chezmoi init --apply` run from within WSL (see Bootstrap section above).

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
.chezmoiscripts/         run_once and run_onchange scripts (deps, ansible, kubeconfig merge)
ansible/                 Ansible playbook and roles for software provisioning
  local.yml              top-level playbook
  group_vars/all.yml     cargo crates and vscode extensions (all platforms)
  roles/macos/           homebrew formulae and casks
  roles/ubuntu/          apt repos, packages, flatpak
  roles/wsl_ubuntu/      WSL-specific: CLI packages only, no GUI/docker/fonts
  roles/arch/            pacman, yay bootstrap, AUR packages
  roles/linux_common/    docker install and service setup
  roles/wm_linux/        i3 (x11) or sway (wayland) conditional install
  roles/fonts/           Monaspace and Nerd Fonts
  roles/rust/            rustup + cargo crates from group_vars
  roles/vscode_extensions/ VS Code extensions from group_vars
dot_config/              ~/.config contents (nvim, k9s, wezterm, sketchybar, etc.)
private_dot_ssh/         SSH key templates rendered from Bitwarden
scripts/                 setup-bitwarden.sh, pre-commit.sh, checksum-utils.sh
kube/clusters/           kubeconfig files (gitignored, backed up to Bitwarden)
ssh/                     SSH keys (gitignored, backed up to Bitwarden)
```
