#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
MANAGED_DIR="${HOME}/.config/fedora-wsl-dotfiles"
STATE_DIR="${HOME}/.local/state/fedora-wsl-dotfiles"
BACKUP_DIR="${STATE_DIR}/backups"
LOCAL_BIN="${HOME}/.local/bin"

DRY_RUN=0
GIT_NAME=""
GIT_EMAIL=""

KUBECTL_VERSION="v1.36.3"
KUBECTX_VERSION="0.11.0"
LAZYGIT_VERSION="0.64.0"

usage() {
    cat <<'EOF'
Usage: install.sh [options]

Options:
  --dry-run           Print changes without applying them
  --git-name NAME     Configure Git user.name
  --git-email EMAIL   Configure Git user.email
  -h, --help          Show this help
EOF
}

log() {
    printf '==> %s\n' "$*"
}

warn() {
    printf 'WARNING: %s\n' "$*" >&2
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

run() {
    if (( DRY_RUN )); then
        printf '+'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

while (( $# > 0 )); do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --git-name)
            (( $# >= 2 )) || die "--git-name requires a value"
            GIT_NAME=$2
            shift 2
            ;;
        --git-email)
            (( $# >= 2 )) || die "--git-email requires a value"
            GIT_EMAIL=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown option: $1"
            ;;
    esac
done

[[ -r /etc/os-release ]] || die "/etc/os-release not found"
# shellcheck source=/dev/null
source /etc/os-release
[[ ${ID:-} == "fedora" ]] || die "this installer supports Fedora only (found ${ID:-unknown})"

if [[ -z ${WSL_INTEROP:-} ]] && ! grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease /proc/version; then
    die "WSL not detected"
fi

command -v dnf >/dev/null || die "dnf not found"
command -v sudo >/dev/null || die "sudo not found"

case "$(uname -m)" in
    x86_64)
        RELEASE_ARCH="x86_64"
        KUBECTL_ARCH="amd64"
        ;;
    aarch64|arm64)
        RELEASE_ARCH="arm64"
        KUBECTL_ARCH="arm64"
        ;;
    *)
        die "unsupported architecture: $(uname -m)"
        ;;
esac

if (( ! DRY_RUN )); then
    sudo -v
fi

dnf_package_available() {
    rpm -q "$1" >/dev/null 2>&1 || dnf -q list --available "$1" >/dev/null 2>&1
}

BASE_PACKAGES=(
    ca-certificates
    cargo
    curl
    fzf
    gcc
    gcc-c++
    git
    git-lfs
    gzip
    iputils
    jq
    make
    neovim
    openssh-clients
    openssl-devel
    pkgconf-pkg-config
    python3
    rust
    shadow-utils
    tar
    zsh
)

OPTIONAL_PACKAGES=(
    atuin
    bat
    bind-utils
    btop
    dua-cli
    eza
    fd-find
    kubernetes-client
    lazygit
    ripgrep
    starship
    zoxide
    zsh-autosuggestions
    zsh-syntax-highlighting
)

DNF_PACKAGES=("${BASE_PACKAGES[@]}")
for package in "${OPTIONAL_PACKAGES[@]}"; do
    if dnf_package_available "$package"; then
        DNF_PACKAGES+=("$package")
    else
        warn "Fedora package unavailable in configured repositories: $package"
    fi
done

log "Installing Fedora packages"
run sudo dnf install -y "${DNF_PACKAGES[@]}"

export PATH="${LOCAL_BIN}:${HOME}/.cargo/bin:${PATH}"

cargo_install_if_missing() {
    local command_name=$1
    local crate_name=$2

    if command -v "$command_name" >/dev/null 2>&1; then
        return
    fi

    log "Installing ${crate_name} with Cargo"
    run cargo install --locked "$crate_name"
}

# Fedora packages remain preferred. These are Cargo fallbacks for releases where
# a package is absent, plus tools not shipped in Fedora's standard repositories.
cargo_install_if_missing starship starship
cargo_install_if_missing gping gping
cargo_install_if_missing atuin atuin
cargo_install_if_missing bat bat
cargo_install_if_missing dua dua-cli
cargo_install_if_missing eza eza
cargo_install_if_missing fd fd-find
cargo_install_if_missing rg ripgrep
cargo_install_if_missing zoxide zoxide

install_verified_archive() {
    local command_name=$1
    local url=$2
    local expected_sha=$3
    local binary_name=$4
    local archive_name=${url##*/}
    local temp_dir

    if command -v "$command_name" >/dev/null 2>&1; then
        return
    fi

    if (( DRY_RUN )); then
        printf '+ download and verify %s\n' "$url"
        printf '+ install %s to %s/%s\n' "$binary_name" "$LOCAL_BIN" "$binary_name"
        return
    fi

    temp_dir=$(mktemp -d)
    curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
        "$url" --output "${temp_dir}/${archive_name}"
    printf '%s  %s\n' "$expected_sha" "${temp_dir}/${archive_name}" | sha256sum --check --status \
        || die "checksum verification failed for ${archive_name}"

    mkdir -p "${temp_dir}/extract" "$LOCAL_BIN"
    tar -xzf "${temp_dir}/${archive_name}" -C "${temp_dir}/extract"
    [[ -f "${temp_dir}/extract/${binary_name}" ]] \
        || die "${binary_name} missing from ${archive_name}"
    install -m 0755 "${temp_dir}/extract/${binary_name}" "${LOCAL_BIN}/${binary_name}"

    rm -rf "$temp_dir"
}

install_kubectl() {
    local expected_sha
    local url
    local temp_dir

    if command -v kubectl >/dev/null 2>&1; then
        return
    fi

    case "$KUBECTL_ARCH" in
        amd64) expected_sha="ebbd080e7c2e275093b55915722043257eb24004363e20acb3c4d71919f88336" ;;
        arm64) expected_sha="3d86f24401c41ae5a46ac50eef8865fe891d3647d324a0836f6c63757a126e62" ;;
    esac
    url="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"

    if (( DRY_RUN )); then
        printf '+ download and verify %s\n' "$url"
        printf '+ install kubectl to %s/kubectl\n' "$LOCAL_BIN"
        return
    fi

    temp_dir=$(mktemp -d)
    curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
        "$url" --output "${temp_dir}/kubectl"
    printf '%s  %s\n' "$expected_sha" "${temp_dir}/kubectl" | sha256sum --check --status \
        || die "checksum verification failed for kubectl"
    mkdir -p "$LOCAL_BIN"
    install -m 0755 "${temp_dir}/kubectl" "${LOCAL_BIN}/kubectl"
    rm -rf "$temp_dir"
}

install_kubernetes_helpers() {
    local kubectx_sha
    local kubens_sha
    local lazygit_sha

    case "$RELEASE_ARCH" in
        x86_64)
            kubectx_sha="08e031c54fbffb3f100e904e4eae94bba2730fedf4869921fda79e4d7a8f5d4c"
            kubens_sha="326c021c7b35468ed9a187b361198d0f22ae32828139c65eb6670c0d8301cc09"
            lazygit_sha="7996236f2c1dd2643d96c3d67a1f7fcd2560bf08bcb7f6be073e26fb29167ac6"
            ;;
        arm64)
            kubectx_sha="1dac2072216689e773325cb7587b858ea7415706ebcf04e23bf80e7e70555340"
            kubens_sha="37058abe82ef20c93b44f3dc8ca2382dbb95d416cec958fbf7b8f79f011be86c"
            lazygit_sha="d286487eb18b2b82fccfd0f1c55d8445e6eb82c08ced3b9eb3e5be0e7c627fd0"
            ;;
    esac

    install_verified_archive \
        kubectx \
        "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubectx_v${KUBECTX_VERSION}_linux_${RELEASE_ARCH}.tar.gz" \
        "$kubectx_sha" \
        kubectx
    install_verified_archive \
        kubens \
        "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubens_v${KUBECTX_VERSION}_linux_${RELEASE_ARCH}.tar.gz" \
        "$kubens_sha" \
        kubens
    install_verified_archive \
        lazygit \
        "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_${RELEASE_ARCH}.tar.gz" \
        "$lazygit_sha" \
        lazygit
}

log "Installing Kubernetes and Git helpers"
install_kubectl
install_kubernetes_helpers

backup_once() {
    local destination=$1
    local relative=${destination#"${HOME}/"}
    local backup_name=${relative//\//__}

    [[ -e "$destination" || -L "$destination" ]] || return
    [[ -e "${BACKUP_DIR}/${backup_name}" || -L "${BACKUP_DIR}/${backup_name}" ]] && return

    log "Backing up ${destination}"
    run mkdir -p "$BACKUP_DIR"
    run cp -a "$destination" "${BACKUP_DIR}/${backup_name}"
}

install_config() {
    local source_file=$1
    local destination=$2

    backup_once "$destination"
    run install -D -m 0644 "$source_file" "$destination"
}

ensure_source_line() {
    local shell_file=$1
    local source_line=$2

    if [[ -f "$shell_file" ]] && grep -Fqx "$source_line" "$shell_file"; then
        return
    fi

    backup_once "$shell_file"
    if (( DRY_RUN )); then
        printf '+ append managed source line to %s\n' "$shell_file"
        return
    fi

    mkdir -p "$(dirname "$shell_file")"
    touch "$shell_file"
    printf '\n%s\n' "$source_line" >> "$shell_file"
}

log "Installing managed configuration"
install_config "${ROOT_DIR}/config/env.zsh" "${MANAGED_DIR}/env.zsh"
install_config "${ROOT_DIR}/config/zshrc" "${MANAGED_DIR}/zshrc"
install_config "${ROOT_DIR}/config/starship.toml" "${MANAGED_DIR}/starship.toml"
install_config "${ROOT_DIR}/config/gitconfig" "${MANAGED_DIR}/gitconfig"
install_config "${ROOT_DIR}/config/gitignore" "${MANAGED_DIR}/gitignore"
install_config "${ROOT_DIR}/config/kubectl_aliases" "${MANAGED_DIR}/kubectl_aliases"
install_config "${ROOT_DIR}/config/atuin.toml" "${HOME}/.config/atuin/config.toml"
install_config "${ROOT_DIR}/config/lazygit.yml" "${HOME}/.config/lazygit/config.yml"

ensure_source_line \
    "${HOME}/.zprofile" \
    '[[ -r "$HOME/.config/fedora-wsl-dotfiles/env.zsh" ]] && source "$HOME/.config/fedora-wsl-dotfiles/env.zsh"'
ensure_source_line \
    "${HOME}/.zshrc" \
    '[[ -r "$HOME/.config/fedora-wsl-dotfiles/zshrc" ]] && source "$HOME/.config/fedora-wsl-dotfiles/zshrc"'

if ! git config --global --get-all include.path 2>/dev/null | grep -Fxq "$MANAGED_DIR/gitconfig"; then
    run git config --global --add include.path "$MANAGED_DIR/gitconfig"
fi

if [[ -n "$GIT_NAME" ]]; then
    run git config --global user.name "$GIT_NAME"
fi
if [[ -n "$GIT_EMAIL" ]]; then
    run git config --global user.email "$GIT_EMAIL"
fi

ZSH_BIN=$(command -v zsh)
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [[ "$CURRENT_SHELL" != "$ZSH_BIN" ]]; then
    log "Setting login shell to ${ZSH_BIN}"
    run sudo usermod --shell "$ZSH_BIN" "$USER"
fi

log "Setup complete"
printf 'Start a fresh shell with: exec zsh -l\n'
if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
    printf 'Set Git identity when ready:\n'
    printf '  git config --global user.name "Your Name"\n'
    printf '  git config --global user.email "you@company.example"\n'
fi
printf 'Windows WezTerm config: %s\n' "${ROOT_DIR}/windows/.wezterm.lua"
