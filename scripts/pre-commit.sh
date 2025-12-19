#!/bin/bash
# Pre-commit hook: Sync secrets and backup kubeconfigs to Bitwarden

set -e

DOTFILES_DIR="$(git rev-parse --show-toplevel)"
KUBE_CLUSTERS_DIR="$DOTFILES_DIR/kube/clusters"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Pre-commit hook: Syncing secrets ===${NC}"

# STRICT: Require BW_SESSION or FAIL
if [ -z "$BW_SESSION" ]; then
    echo -e "${RED}ERROR: BW_SESSION not set${NC}" >&2
    echo -e "${YELLOW}Cannot sync secrets to Bitwarden${NC}" >&2
    echo -e "${YELLOW}Run: export BW_SESSION=\$(bw unlock --raw)${NC}" >&2
    exit 1
fi

# Get folder ID by name
get_folder_id() {
    local folder_name="$1"
    local folder_id=$(bw list folders --session "$BW_SESSION" 2>/dev/null | \
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

# Function to sync env file to template and Bitwarden
sync_env_file() {
    local env_file="$1"
    local template_file="$2"

    if [ ! -f "$env_file" ]; then
        echo -e "${YELLOW}Skipping (file not found): $env_file${NC}"
        return 0
    fi

    echo -e "${GREEN}Syncing: $env_file${NC}"

    # Parse .env file and sync to Bitwarden
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue

        # Remove 'export ' prefix and whitespace
        key=$(echo "$key" | sed 's/^export //' | xargs)

        # Remove quotes from value
        value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/" | xargs)

        # Skip BW_SESSION (it's ephemeral)
        [[ "$key" == "BW_SESSION" ]] && continue

        # Skip empty values
        [[ -z "$value" ]] && continue

        # Convert env var name to Bitwarden item name
        # OPENAI_API_KEY -> openai-api-key
        # AZURE_TENANT_ID -> azure-tenant-id
        item_name=$(echo "$key" | tr '[:upper:]_' '[:lower:]-')

        # Check if item exists in dotfiles/env-vars folder
        existing_value=$(bw list items --folderid "$ENV_VARS_FOLDER_ID" --session "$BW_SESSION" 2>/dev/null | \
            jq -r ".[] | select(.name==\"$item_name\") | .login.password")

        if [ -z "$existing_value" ] || [ "$existing_value" = "null" ]; then
            # Create new item in dotfiles/env-vars folder using template API
            echo -e "${YELLOW}  Creating: $item_name${NC}"

            bw get template item --session "$BW_SESSION" | \
                jq ".folderId=\"$ENV_VARS_FOLDER_ID\" | .type=1 | .name=\"$item_name\" | .login.password=\"$value\"" | \
                bw encode | \
                bw create item --session "$BW_SESSION" > /dev/null 2>&1
        elif [ "$existing_value" != "$value" ]; then
            # Update existing item
            echo -e "${YELLOW}  Updating: $item_name${NC}"
            item_id=$(bw list items --folderid "$ENV_VARS_FOLDER_ID" --session "$BW_SESSION" 2>/dev/null | \
                jq -r ".[] | select(.name==\"$item_name\") | .id")

            item_json=$(bw get item "$item_id" --session "$BW_SESSION")
            updated_json=$(echo "$item_json" | jq ".login.password = \"$value\"")
            echo "$updated_json" | bw encode | bw edit item "$item_id" --session "$BW_SESSION" > /dev/null 2>&1
        fi
    done < "$env_file"

    # Regenerate template from env file (reverse templating)
    if [ -f "$template_file" ]; then
        echo -e "${GREEN}  Updating template: $template_file${NC}"

        # Read env file and replace values with placeholders
        cp "$env_file" "$template_file"

        while IFS='=' read -r key value; do
            [[ "$key" =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue

            key=$(echo "$key" | sed 's/^export //' | xargs)

            # Skip BW_SESSION
            [[ "$key" == "BW_SESSION" ]] && continue

            # Replace value with placeholder {{KEY}}
            # Use a more careful sed that handles special characters
            if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "s|^export $key=.*|export $key={{$key}}|g" "$template_file"
            else
                sed -i "s|^export $key=.*|export $key={{$key}}|g" "$template_file"
            fi
        done < "$env_file"
    fi
}

# Sync .env files
sync_env_file "$DOTFILES_DIR/.env" "$DOTFILES_DIR/templates/.env.tmpl"
sync_env_file "$DOTFILES_DIR/.env.darwin" "$DOTFILES_DIR/templates/.env.darwin.tmpl"
sync_env_file "$DOTFILES_DIR/.env.linux" "$DOTFILES_DIR/templates/.env.linux.tmpl"

echo -e "${GREEN}=== Backing up kubeconfigs to Bitwarden ===${NC}"

# Skip if no kubeconfigs directory
if [ ! -d "$KUBE_CLUSTERS_DIR" ]; then
    echo -e "${YELLOW}Skipping kubeconfig backup (directory not found)${NC}"
else
    # Get or create the kubeconfigs item in dotfiles/kubeconfig folder
    KUBE_ITEM_ID=$(bw list items --folderid "$KUBECONFIG_FOLDER_ID" --session "$BW_SESSION" 2>/dev/null | \
        jq -r '.[] | select(.name=="kubeconfigs") | .id')

    if [ -z "$KUBE_ITEM_ID" ] || [ "$KUBE_ITEM_ID" = "null" ]; then
        echo -e "${YELLOW}Creating kubeconfigs item in Bitwarden...${NC}"
        KUBE_ITEM_ID=$(bw get template item | \
            jq ".type = 2 | .secureNote.type = 0 | .name = \"kubeconfigs\" | .notes = \"Kubernetes cluster configurations\" | .folderId = \"$KUBECONFIG_FOLDER_ID\"" | \
            bw encode | bw create item | jq -r '.id')
    fi

    # Upload each kubeconfig file as an attachment
    for config_file in "$KUBE_CLUSTERS_DIR"/*; do
        # Skip if not a file or if it's a shell script
        [ ! -f "$config_file" ] && continue
        [[ "$config_file" == *.sh ]] && continue
        [[ "$(basename "$config_file")" == ".gitkeep" ]] && continue
        [[ "$(basename "$config_file")" == ".DS_Store" ]] && continue

        filename=$(basename "$config_file")

        # Check if attachment already exists
        ATTACHMENT_ID=$(bw get item "$KUBE_ITEM_ID" --session "$BW_SESSION" | jq -r ".attachments[]? | select(.fileName == \"$filename\") | .id")

        if [ -n "$ATTACHMENT_ID" ] && [ "$ATTACHMENT_ID" != "null" ]; then
            echo -e "${YELLOW}  Updating: $filename${NC}"
            bw delete attachment "$ATTACHMENT_ID" --session "$BW_SESSION" > /dev/null 2>&1
        else
            echo -e "${GREEN}  Adding: $filename${NC}"
        fi

        bw create attachment --file "$config_file" --itemid "$KUBE_ITEM_ID" --session "$BW_SESSION" > /dev/null 2>&1
    done

    echo -e "${GREEN}✓ Kubeconfigs backed up${NC}"
fi

# Sync with Bitwarden server
echo -e "${GREEN}Syncing Bitwarden...${NC}"
bw sync --session "$BW_SESSION" > /dev/null 2>&1

echo -e "${GREEN}=== Pre-commit sync complete ===${NC}"
exit 0
