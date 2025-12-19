#!/bin/bash
# Pre-commit hook: Backup kubeconfigs to Bitwarden

DOTFILES_DIR="$(git rev-parse --show-toplevel)"
KUBE_CLUSTERS_DIR="$DOTFILES_DIR/kube/clusters"

# Skip if no kubeconfigs directory
[ ! -d "$KUBE_CLUSTERS_DIR" ] && exit 0

# Ensure BW_SESSION is set
if [ -z "$BW_SESSION" ]; then
    echo "Warning: BW_SESSION not set. Kubeconfigs will not be backed up."
    echo "Run: export BW_SESSION=\$(bw unlock --raw)"
    exit 1
fi

echo "Backing up kubeconfigs to Bitwarden..."

# Get or create the dotfiles/kubeconfigs item
ITEM_ID=$(bw get item "dotfiles/kubeconfigs" --session "$BW_SESSION" 2>/dev/null | jq -r '.id')

if [ -z "$ITEM_ID" ] || [ "$ITEM_ID" = "null" ]; then
    echo "Creating dotfiles/kubeconfigs item in Bitwarden..."
    ITEM_ID=$(bw get template item | jq '.type = 2 | .secureNote.type = 0 | .name = "dotfiles/kubeconfigs" | .notes = "Kubernetes cluster configurations"' | bw encode | bw create item | jq -r '.id')
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
    ATTACHMENT_ID=$(bw get item "$ITEM_ID" --session "$BW_SESSION" | jq -r ".attachments[]? | select(.fileName == \"$filename\") | .id")

    if [ -n "$ATTACHMENT_ID" ] && [ "$ATTACHMENT_ID" != "null" ]; then
        echo "  Updating: $filename"
        bw delete attachment "$ATTACHMENT_ID" --session "$BW_SESSION" > /dev/null 2>&1
    else
        echo "  Adding: $filename"
    fi

    bw create attachment --file "$config_file" --itemid "$ITEM_ID" --session "$BW_SESSION" > /dev/null 2>&1
done

# Sync with server
bw sync --session "$BW_SESSION" > /dev/null 2>&1

echo "✓ Kubeconfigs backed up to Bitwarden"
exit 0
