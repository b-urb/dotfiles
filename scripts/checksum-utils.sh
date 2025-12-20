#!/bin/bash
# Checksum utility functions for Bitwarden sync optimization

CHECKSUMS_FILE="$DOTFILES_DIR/.checksums"

# Calculate checksum for env files
calculate_env_checksum() {
    local checksum=""

    # Concatenate all env files (if they exist) and hash
    {
        [ -f "$DOTFILES_DIR/.env" ] && cat "$DOTFILES_DIR/.env"
        [ -f "$DOTFILES_DIR/.env.darwin" ] && cat "$DOTFILES_DIR/.env.darwin"
        [ -f "$DOTFILES_DIR/.env.linux" ] && cat "$DOTFILES_DIR/.env.linux"
    } | sort | calculate_hash
}

# Calculate checksum for SSH keys
calculate_ssh_checksum() {
    local ssh_dir="$DOTFILES_DIR/ssh"

    if [ ! -d "$ssh_dir" ]; then
        echo "empty"
        return
    fi

    # Hash each file, then hash the combined hashes
    find "$ssh_dir" -type f ! -name '.gitkeep' 2>/dev/null | while IFS= read -r file; do
        if command -v sha256sum >/dev/null 2>&1; then
            sha256sum "$file"
        elif command -v shasum >/dev/null 2>&1; then
            shasum -a 256 "$file"
        fi
    done | sort | calculate_hash
}

# Calculate checksum for kubeconfigs
calculate_kube_checksum() {
    local kube_dir="$DOTFILES_DIR/kube/clusters"

    if [ ! -d "$kube_dir" ]; then
        echo "empty"
        return
    fi

    # Hash each file, then hash the combined hashes
    find "$kube_dir" -type f ! -name '.gitkeep' ! -name '*.sh' ! -name '.DS_Store' 2>/dev/null | while IFS= read -r file; do
        if command -v sha256sum >/dev/null 2>&1; then
            sha256sum "$file"
        elif command -v shasum >/dev/null 2>&1; then
            shasum -a 256 "$file"
        fi
    done | sort | calculate_hash
}

# Platform-agnostic hash calculation (works on macOS and Linux)
calculate_hash() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 | awk '{print $1}'
    else
        echo "ERROR: No SHA256 tool available" >&2
        exit 1
    fi
}

# Calculate hash of a single file
calculate_file_hash() {
    local file="$1"
    if [ -f "$file" ]; then
        if command -v sha256sum >/dev/null 2>&1; then
            sha256sum "$file"
        elif command -v shasum >/dev/null 2>&1; then
            shasum -a 256 "$file"
        fi
    fi
}

# Read checksum from .checksums file
get_stored_checksum() {
    local key="$1"

    if [ ! -f "$CHECKSUMS_FILE" ]; then
        echo ""
        return
    fi

    grep "^${key}=" "$CHECKSUMS_FILE" 2>/dev/null | cut -d'=' -f2
}

# Update checksum in .checksums file
update_checksum() {
    local key="$1"
    local value="$2"

    # Create file if it doesn't exist
    touch "$CHECKSUMS_FILE"

    # Remove old value if exists, then append new value
    grep -v "^${key}=" "$CHECKSUMS_FILE" > "$CHECKSUMS_FILE.tmp" 2>/dev/null || true
    echo "${key}=${value}" >> "$CHECKSUMS_FILE.tmp"

    # Sort for consistent ordering
    sort "$CHECKSUMS_FILE.tmp" > "$CHECKSUMS_FILE"
    rm "$CHECKSUMS_FILE.tmp"
}

# Check if content has changed by comparing checksums
has_changed() {
    local key="$1"
    local current_checksum="$2"
    local stored_checksum=$(get_stored_checksum "$key")

    # If no stored checksum exists, consider it changed
    if [ -z "$stored_checksum" ]; then
        return 0  # Changed (true)
    fi

    # Compare checksums
    if [ "$current_checksum" != "$stored_checksum" ]; then
        return 0  # Changed (true)
    else
        return 1  # Not changed (false)
    fi
}
