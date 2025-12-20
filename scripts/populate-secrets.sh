#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$DOTFILES_DIR/templates"
KUBE_CLUSTERS_DIR="$DOTFILES_DIR/kube/clusters"

# Source checksum utilities
source "$SCRIPT_DIR/checksum-utils.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Populating secrets from Bitwarden ===${NC}"

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
ENV_VARS_FOLDER_ID=$(get_folder_id "dotfiles/env-vars")
KUBECONFIG_FOLDER_ID=$(get_folder_id "dotfiles/kubeconfig")

echo -e "${GREEN}Using Bitwarden folder IDs:${NC}"
echo -e "${GREEN}  dotfiles/env-vars: $ENV_VARS_FOLDER_ID${NC}"
echo -e "${GREEN}  dotfiles/kubeconfig: $KUBECONFIG_FOLDER_ID${NC}"

# Get secret from Bitwarden folder
get_secret() {
  local folder_id="$1"
  local item_name="$2"

  local value=$(bw list items --folderid "$folder_id" --session "$BW_SESSION" 2>/dev/null |
    jq -r ".[] | select(.name==\"$item_name\") | .login.password")

  if [ -z "$value" ] || [ "$value" = "null" ]; then
    echo -e "${RED}Error: Could not retrieve '$item_name' from folder${NC}" >&2
    echo -e "${YELLOW}Make sure the item exists in the correct Bitwarden folder${NC}" >&2
    exit 1
  fi
  echo "$value"
}

# Populate template
populate_template() {
  local template_file="$1"
  local output_file="$2"

  if [ ! -f "$template_file" ]; then
    echo -e "${YELLOW}Skipping (template not found): $template_file${NC}"
    return 0
  fi

  echo -e "${GREEN}Populating: $output_file${NC}"

  local content=$(cat "$template_file")

  # Replace placeholders - all from dotfiles/env-vars folder
  content="${content//\{\{GITHUB_PAT\}\}/$(get_secret "$ENV_VARS_FOLDER_ID" 'github-pat')}"
  content="${content//\{\{DIRECTUS_TOKEN\}\}/$(get_secret "$ENV_VARS_FOLDER_ID" 'directus-token')}"
  content="${content//\{\{VAULT_TOKEN\}\}/$(get_secret "$ENV_VARS_FOLDER_ID" 'vault-token')}"
  content="${content//\{\{GIT_EMAIL\}\}/$(get_secret "$ENV_VARS_FOLDER_ID" 'git-email')}"
  #content="${content//\{\{OPENAI_API_KEY\}\}/$(get_secret "$ENV_VARS_FOLDER_ID" 'openai-api-key')}"
  content="${content//\{\{AZURE_TENANT_ID\}\}/$(get_secret "$ENV_VARS_FOLDER_ID" 'azure-tenant-id')}"
  content="${content//\{\{AZURE_DEFAULT_USERNAME\}\}/$(get_secret "$ENV_VARS_FOLDER_ID" 'azure-username')}"

  # Calculate checksum of new content
  local new_checksum=$(echo "$content" | calculate_hash)

  # Calculate checksum of existing file (if it exists)
  local existing_checksum=""
  if [ -f "$output_file" ]; then
    existing_checksum=$(cat "$output_file" | calculate_hash)
  fi

  # Only write if content changed
  if [ "$new_checksum" != "$existing_checksum" ]; then
    echo "  Writing: $output_file"
    echo "$content" >"$output_file"
    chmod 600 "$output_file"
  else
    echo "  Unchanged: $output_file"
  fi
}

# Populate all templates
populate_template "$TEMPLATES_DIR/codex.config.toml.tmpl" "$DOTFILES_DIR/config/codex/config.toml"
populate_template "$TEMPLATES_DIR/gitconfig.tmpl" "$DOTFILES_DIR/gitconfig"
populate_template "$TEMPLATES_DIR/bashrc.tmpl" "$DOTFILES_DIR/bashrc"

# Populate .env files
populate_template "$TEMPLATES_DIR/.env.tmpl" "$DOTFILES_DIR/.env"

# Populate OS-specific .env
case "$(uname -s)" in
Darwin)
  populate_template "$TEMPLATES_DIR/.env.darwin.tmpl" "$DOTFILES_DIR/.env.darwin"
  ;;
Linux)
  populate_template "$TEMPLATES_DIR/.env.linux.tmpl" "$DOTFILES_DIR/.env.linux"
  ;;
esac

echo -e "${GREEN}=== Checking if kubeconfigs need restoration ===${NC}"

# Calculate stored checksum
STORED_KUBE_CHECKSUM=$(get_stored_checksum "kubeconfigs")

# Calculate current checksum of local files
CURRENT_KUBE_CHECKSUM=$(calculate_kube_checksum)

if [ -z "$STORED_KUBE_CHECKSUM" ] || [ "$CURRENT_KUBE_CHECKSUM" != "$STORED_KUBE_CHECKSUM" ]; then
    echo -e "${YELLOW}Kubeconfigs need restoration${NC}"
    RESTORE_KUBECONFIGS=true
else
    echo -e "${GREEN}✓ Kubeconfigs already up-to-date${NC}"
    RESTORE_KUBECONFIGS=false
fi

if [ "$RESTORE_KUBECONFIGS" = "true" ]; then
    echo -e "${GREEN}=== Restoring kubeconfigs from Bitwarden ===${NC}"

    # Create kube/clusters directory if it doesn't exist
    mkdir -p "$KUBE_CLUSTERS_DIR"

# Get the kubeconfigs item from dotfiles/kubeconfig folder
KUBE_ITEM_ID=$(bw list items --folderid "$KUBECONFIG_FOLDER_ID" --session "$BW_SESSION" 2>/dev/null |
  jq -r '.[] | select(.name=="kubeconfigs") | .id')

if [ -z "$KUBE_ITEM_ID" ] || [ "$KUBE_ITEM_ID" = "null" ]; then
  echo -e "${YELLOW}No kubeconfigs found in Bitwarden (this is OK on first setup)${NC}"
else
  # List and download all attachments
  bw get item "$KUBE_ITEM_ID" --session "$BW_SESSION" | jq -r '.attachments[]? | .id + " " + .fileName' | while read -r attachment_id filename; do
    if [ -n "$attachment_id" ] && [ -n "$filename" ]; then
      echo -e "${GREEN}  Restoring kubeconfig: $filename${NC}"
      bw get attachment "$attachment_id" --itemid "$KUBE_ITEM_ID" --output "$KUBE_CLUSTERS_DIR/$filename" --session "$BW_SESSION" 2>/dev/null
      chmod 600 "$KUBE_CLUSTERS_DIR/$filename"
    fi
  done

  echo -e "${GREEN}✓ Kubeconfigs restored${NC}"
fi
fi

echo -e "${GREEN}=== Checking if SSH keys need restoration ===${NC}"

# Calculate stored checksum
STORED_SSH_CHECKSUM=$(get_stored_checksum "ssh_keys")

# Calculate current checksum of local files
CURRENT_SSH_CHECKSUM=$(calculate_ssh_checksum)

if [ -z "$STORED_SSH_CHECKSUM" ] || [ "$CURRENT_SSH_CHECKSUM" != "$STORED_SSH_CHECKSUM" ]; then
    echo -e "${YELLOW}SSH keys need restoration${NC}"
    RESTORE_SSH_KEYS=true
else
    echo -e "${GREEN}✓ SSH keys already up-to-date${NC}"
    RESTORE_SSH_KEYS=false
fi

if [ "$RESTORE_SSH_KEYS" = "true" ]; then
    echo -e "${GREEN}=== Restoring SSH keys from Bitwarden ===${NC}"

    # Create ssh directory if it doesn't exist
    SSH_DIR="$DOTFILES_DIR/ssh"
    mkdir -p "$SSH_DIR"

# Get folder ID
SSH_KEYS_FOLDER_ID=$(get_folder_id "dotfiles/ssh-keys")

# Get the ssh-keys item from dotfiles/ssh-keys folder
SSH_ITEM_ID=$(bw list items --folderid "$SSH_KEYS_FOLDER_ID" --session "$BW_SESSION" 2>/dev/null | \
  jq -r '.[] | select(.name=="ssh-keys") | .id')

if [ -z "$SSH_ITEM_ID" ] || [ "$SSH_ITEM_ID" = "null" ]; then
  echo -e "${YELLOW}No SSH keys found in Bitwarden (this is OK on first setup)${NC}"
else
  # List and download all attachments
  bw get item "$SSH_ITEM_ID" --session "$BW_SESSION" | jq -r '.attachments[]? | .id + " " + .fileName' | while read -r attachment_id filename; do
    if [ -n "$attachment_id" ] && [ -n "$filename" ]; then
      echo -e "${GREEN}  Restoring SSH key: $filename${NC}"
      bw get attachment "$attachment_id" --itemid "$SSH_ITEM_ID" --output "$SSH_DIR/$filename" --session "$BW_SESSION" 2>/dev/null

      # Set proper permissions based on file type
      if [[ "$filename" == *.pub ]]; then
        chmod 644 "$SSH_DIR/$filename"  # Public keys
      else
        chmod 600 "$SSH_DIR/$filename"  # Private keys
      fi
    fi
  done

  echo -e "${GREEN}✓ SSH keys restored to $SSH_DIR${NC}"
fi
fi

echo -e "${GREEN}=== All secrets populated successfully ===${NC}"
