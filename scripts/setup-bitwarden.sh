#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Bitwarden Dotfiles Setup ===${NC}"
echo
echo "This script will create the following folder structure in Bitwarden:"
echo
echo -e "${YELLOW}  dotfiles/${NC}"
echo -e "${YELLOW}    ├── dotfiles/env-vars${NC} - Environment variable secrets"
echo -e "${YELLOW}    └── dotfiles/kubeconfig${NC} - Kubernetes configurations"
echo
echo -e "${RED}WARNING: This should only be run ONCE when setting up dotfiles.${NC}"
echo -e "${RED}Running this multiple times will create duplicate folders!${NC}"
echo

# Prompt for confirmation
read -p "Continue? (yes/NO): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Setup cancelled.${NC}"
    exit 0
fi

# Check BW_SESSION
if [ -z "$BW_SESSION" ]; then
    echo -e "${RED}ERROR: BW_SESSION not set${NC}" >&2
    echo -e "${YELLOW}Run: export BW_SESSION=\$(bw unlock --raw)${NC}" >&2
    exit 1
fi

echo
echo -e "${GREEN}Creating Bitwarden folders...${NC}"

# Function to create folder if it doesn't exist
create_folder_if_missing() {
    local folder_name="$1"

    # Check if folder exists
    local folder_id=$(bw list folders --session "$BW_SESSION" 2>/dev/null | \
        jq -r ".[] | select(.name==\"$folder_name\") | .id")

    if [ -z "$folder_id" ] || [ "$folder_id" = "null" ]; then
        echo -e "${BLUE}  Creating folder: $folder_name${NC}"

        # Use proper folder creation via template
        folder_id=$(bw get template folder --session "$BW_SESSION" | \
            jq ".name=\"$folder_name\"" | \
            bw encode | \
            bw create folder --session "$BW_SESSION" 2>/dev/null | \
            jq -r '.id')

        if [ -z "$folder_id" ] || [ "$folder_id" = "null" ]; then
            echo -e "${RED}  ERROR: Failed to create folder: $folder_name${NC}" >&2
            exit 1
        fi

        echo -e "${GREEN}  ✓ Created: $folder_name (ID: $folder_id)${NC}"
    else
        echo -e "${YELLOW}  ⚠ Already exists: $folder_name (ID: $folder_id)${NC}"
    fi
}

# Create folders (slash notation creates nested structure)
create_folder_if_missing "dotfiles"
create_folder_if_missing "dotfiles/env-vars"
create_folder_if_missing "dotfiles/kubeconfig"

# Sync Bitwarden
echo
echo -e "${BLUE}Syncing Bitwarden...${NC}"
bw sync --session "$BW_SESSION" > /dev/null 2>&1
echo -e "${GREEN}✓ Sync complete${NC}"

echo
echo -e "${GREEN}=== Setup complete! ===${NC}"
echo
echo "Next steps:"
echo "  1. Populate secrets in Bitwarden folders (manually or via CLI)"
echo "  2. Run: ./scripts/populate-secrets.sh"
echo "  3. Run: ./install"
