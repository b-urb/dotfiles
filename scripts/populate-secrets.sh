#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$DOTFILES_DIR/templates"
KUBE_CLUSTERS_DIR="$DOTFILES_DIR/kube/clusters"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Populating secrets from Bitwarden ===${NC}"

# Ensure Bitwarden is unlocked
if [ -z "$BW_SESSION" ]; then
    echo -e "${YELLOW}BW_SESSION not set. Please unlock Bitwarden:${NC}"
    echo "Run: export BW_SESSION=\$(bw unlock --raw)"
    exit 1
fi

# Function to get secret from Bitwarden
get_secret() {
    local item_name="$1"
    local value=$(bw get password "$item_name" --session "$BW_SESSION" 2>/dev/null)
    if [ -z "$value" ]; then
        echo -e "${RED}Error: Could not retrieve '$item_name' from Bitwarden${NC}" >&2
        echo -e "${YELLOW}Make sure the item exists and you have access to it${NC}" >&2
        exit 1
    fi
    echo "$value"
}

# Function to populate template
populate_template() {
    local template_file="$1"
    local output_file="$2"

    if [ ! -f "$template_file" ]; then
        echo -e "${RED}Template not found: $template_file${NC}" >&2
        return 1
    fi

    echo -e "${GREEN}Populating: $output_file${NC}"

    # Read template
    local content=$(cat "$template_file")

    # Replace placeholders
    content="${content//\{\{GITHUB_PAT\}\}/$(get_secret 'dotfiles/github-pat')}"
    content="${content//\{\{DIRECTUS_TOKEN\}\}/$(get_secret 'dotfiles/directus-token')}"
    content="${content//\{\{VAULT_TOKEN\}\}/$(get_secret 'dotfiles/vault-token')}"
    content="${content//\{\{GIT_EMAIL\}\}/$(get_secret 'dotfiles/git-email')}"

    # Write output
    echo "$content" > "$output_file"

    # Set appropriate permissions
    chmod 600 "$output_file"
}

# Populate all templates
populate_template "$TEMPLATES_DIR/codex.config.toml.tmpl" "$DOTFILES_DIR/config/codex/config.toml"
populate_template "$TEMPLATES_DIR/gitconfig.tmpl" "$DOTFILES_DIR/gitconfig"
populate_template "$TEMPLATES_DIR/bashrc.tmpl" "$DOTFILES_DIR/bashrc"

echo -e "${GREEN}=== Restoring kubeconfigs from Bitwarden ===${NC}"

# Create kube/clusters directory if it doesn't exist
mkdir -p "$KUBE_CLUSTERS_DIR"

# Get the item ID for dotfiles/kubeconfigs
KUBE_ITEM_ID=$(bw get item "dotfiles/kubeconfigs" --session "$BW_SESSION" 2>/dev/null | jq -r '.id')

if [ -z "$KUBE_ITEM_ID" ] || [ "$KUBE_ITEM_ID" = "null" ]; then
    echo -e "${YELLOW}Warning: dotfiles/kubeconfigs item not found in Bitwarden${NC}"
    echo -e "${YELLOW}Skipping kubeconfig restoration${NC}"
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

echo -e "${GREEN}=== All secrets populated successfully ===${NC}"
