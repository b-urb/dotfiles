#!/bin/bash
# Pre-commit hook: Sync kubeconfigs and SSH keys to Bitwarden.
#
# NOTE: Env-var sync has been removed. Secrets are now managed directly in
# Bitwarden and rendered into files by chezmoi templates at apply time.
# To update a secret, edit it in Bitwarden and run `chezmoi apply`.

set -e

DOTFILES_DIR="$(git rev-parse --show-toplevel)"
KUBE_CLUSTERS_DIR="$DOTFILES_DIR/kube/clusters"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Source checksum utilities
source "$DOTFILES_DIR/scripts/checksum-utils.sh"

echo -e "${GREEN}=== Pre-commit hook: Syncing to Bitwarden ===${NC}"

# STRICT: Require BW_SESSION or FAIL
if [ -z "$BW_SESSION" ]; then
  echo -e "${RED}ERROR: BW_SESSION not set${NC}" >&2
  echo -e "${YELLOW}Run: export BW_SESSION=\$(bw unlock --raw)${NC}" >&2
  exit 1
fi

# Get folder ID by name
get_folder_id() {
  local folder_name="$1"
  local folder_id=$(bw list folders --session "$BW_SESSION" 2>/dev/null |
    jq -r ".[] | select(.name==\"$folder_name\") | .id")

  if [ -z "$folder_id" ] || [ "$folder_id" = "null" ]; then
    echo -e "${RED}ERROR: Folder '$folder_name' not found in Bitwarden${NC}" >&2
    echo -e "${YELLOW}Run: ./scripts/setup-bitwarden.sh to create folders${NC}" >&2
    exit 1
  fi

  echo "$folder_id"
}

# Get folders
KUBECONFIG_FOLDER_ID=$(get_folder_id "dotfiles/kubeconfig")
SSH_KEYS_FOLDER_ID=$(get_folder_id "dotfiles/ssh-keys")

# ─────────────────────────────────────────────────────────────────────────────
# Kubeconfigs
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${GREEN}=== Checking kubeconfigs for changes ===${NC}"

CURRENT_KUBE_CHECKSUM=$(calculate_kube_checksum)

if [ ! -d "$KUBE_CLUSTERS_DIR" ]; then
  echo -e "${YELLOW}Skipping kubeconfig backup (directory not found)${NC}"
elif has_changed "kubeconfigs" "$CURRENT_KUBE_CHECKSUM"; then
  echo -e "${YELLOW}Kubeconfigs changed, syncing to Bitwarden...${NC}"

  KUBE_ITEM_ID=$(bw list items --folderid "$KUBECONFIG_FOLDER_ID" --session "$BW_SESSION" 2>/dev/null |
    jq -r '.[] | select(.name=="kubeconfigs") | .id')

  if [ -z "$KUBE_ITEM_ID" ] || [ "$KUBE_ITEM_ID" = "null" ]; then
    echo -e "${YELLOW}Creating kubeconfigs item in Bitwarden...${NC}"
    KUBE_ITEM_ID=$(bw get template item |
      jq ".type = 2 | .secureNote.type = 0 | .name = \"kubeconfigs\" | .notes = \"Kubernetes cluster configurations\" | .folderId = \"$KUBECONFIG_FOLDER_ID\"" |
      bw encode | bw create item | jq -r '.id')
  fi

  for config_file in "$KUBE_CLUSTERS_DIR"/*; do
    [ ! -f "$config_file" ] && continue
    [[ "$config_file" == *.sh ]] && continue
    [[ "$(basename "$config_file")" == ".gitkeep" ]] && continue
    [[ "$(basename "$config_file")" == ".DS_Store" ]] && continue

    filename=$(basename "$config_file")
    ATTACHMENT_ID=$(bw get item "$KUBE_ITEM_ID" --session "$BW_SESSION" | \
      jq -r ".attachments[]? | select(.fileName == \"$filename\") | .id")

    if [ -n "$ATTACHMENT_ID" ] && [ "$ATTACHMENT_ID" != "null" ]; then
      echo -e "${YELLOW}  Updating: $filename${NC}"
      bw delete attachment "$ATTACHMENT_ID" --itemid "$KUBE_ITEM_ID" --session "$BW_SESSION" >/dev/null 2>&1
    else
      echo -e "${GREEN}  Adding: $filename${NC}"
    fi

    bw create attachment --file "$config_file" --itemid "$KUBE_ITEM_ID" --session "$BW_SESSION" >/dev/null 2>&1
  done

  update_checksum "kubeconfigs" "$CURRENT_KUBE_CHECKSUM"
  echo -e "${GREEN}✓ Kubeconfigs synced${NC}"
else
  echo -e "${GREEN}✓ Kubeconfigs unchanged, skipping sync${NC}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# SSH keys
# ─────────────────────────────────────────────────────────────────────────────
echo -e "${GREEN}=== Checking SSH keys for changes ===${NC}"

CURRENT_SSH_CHECKSUM=$(calculate_ssh_checksum)
SSH_DIR="$DOTFILES_DIR/ssh"

if [ ! -d "$SSH_DIR" ]; then
  echo -e "${YELLOW}Skipping SSH key backup (directory not found)${NC}"
elif has_changed "ssh_keys" "$CURRENT_SSH_CHECKSUM"; then
  echo -e "${YELLOW}SSH keys changed, syncing to Bitwarden...${NC}"

  if ! SSH_ITEMS_JSON=$(bw list items --folderid "$SSH_KEYS_FOLDER_ID" --session "$BW_SESSION" 2>&1); then
    echo -e "${RED}ERROR: Failed to list SSH key items from Bitwarden${NC}" >&2
    echo "$SSH_ITEMS_JSON" >&2
    exit 1
  fi

  for key_file in "$SSH_DIR"/*; do
    [ ! -f "$key_file" ] && continue
    [[ "$(basename "$key_file")" == ".gitkeep" ]] && continue
    [[ "$key_file" == *.pub ]] && continue

    filename=$(basename "$key_file")
    if ! grep -q "PRIVATE KEY" "$key_file"; then
      echo -e "${YELLOW}  Skipping $filename (not an SSH private key)${NC}"
      continue
    fi

    item_name="ssh:$filename"
    pub_file="${key_file}.pub"

    if [ -f "$pub_file" ]; then
      public_key=$(cat "$pub_file")
      pub_for_fp="$pub_file"
    else
      if command -v ssh-keygen >/dev/null 2>&1; then
        public_key=$(ssh-keygen -y -f "$key_file" 2>/dev/null || true)
      else
        public_key=""
      fi

      if [ -z "$public_key" ]; then
        echo -e "${YELLOW}  Skipping $filename (missing public key or passphrase-protected)${NC}"
        continue
      fi

      pub_for_fp="$(mktemp)"
      echo "$public_key" >"$pub_for_fp"
    fi

    fingerprint=""
    if command -v ssh-keygen >/dev/null 2>&1; then
      fingerprint=$(ssh-keygen -lf "$pub_for_fp" 2>/dev/null | awk '{print $2}')
    fi

    if [ -z "$fingerprint" ]; then
      echo -e "${YELLOW}  Skipping $filename (could not compute fingerprint)${NC}"
      [ -f "$pub_for_fp" ] && [ "$pub_for_fp" != "$pub_file" ] && rm -f "$pub_for_fp"
      continue
    fi

    [ -f "$pub_for_fp" ] && [ "$pub_for_fp" != "$pub_file" ] && rm -f "$pub_for_fp"

    private_key=$(cat "$key_file")
    item_id=$(echo "$SSH_ITEMS_JSON" | jq -r --arg name "$item_name" '.[] | select(.name==$name) | .id' | head -n 1)

    if [ -z "$item_id" ] || [ "$item_id" = "null" ]; then
      echo -e "${YELLOW}  Creating: $item_name${NC}"
      template_json=$(bw get template item --session "$BW_SESSION")
      payload=$(echo "$template_json" | jq --arg name "$item_name" \
        --arg folder "$SSH_KEYS_FOLDER_ID" \
        --arg private "$private_key" \
        --arg public "$public_key" \
        --arg fp "$fingerprint" \
        '.type=5 | .name=$name | .folderId=$folder | .sshKey={privateKey:$private, publicKey:$public, fingerprint:$fp, keyFingerprint:$fp}')
      printf '%s' "$payload" | bw encode | bw create item --session "$BW_SESSION" >/dev/null
    else
      echo -e "${YELLOW}  Updating: $item_name${NC}"
      item_json=$(bw get item "$item_id" --session "$BW_SESSION")
      updated_json=$(echo "$item_json" | jq --arg private "$private_key" --arg public "$public_key" --arg fp "$fingerprint" \
        '.type=5 | .sshKey.privateKey=$private | .sshKey.publicKey=$public | .sshKey.fingerprint=$fp | .sshKey.keyFingerprint=$fp')
      printf '%s' "$updated_json" | bw encode | bw edit item "$item_id" --session "$BW_SESSION" >/dev/null
    fi
  done

  update_checksum "ssh_keys" "$CURRENT_SSH_CHECKSUM"
  echo -e "${GREEN}✓ SSH keys synced${NC}"
else
  echo -e "${GREEN}✓ SSH keys unchanged, skipping sync${NC}"
fi

# Stage .checksums file for commit
if [ -f "$DOTFILES_DIR/.checksums" ]; then
  git add "$DOTFILES_DIR/.checksums"
fi

# Sync with Bitwarden server
echo -e "${GREEN}Syncing Bitwarden...${NC}"
bw sync --session "$BW_SESSION" >/dev/null 2>&1

echo -e "${GREEN}=== Pre-commit sync complete ===${NC}"
exit 0
