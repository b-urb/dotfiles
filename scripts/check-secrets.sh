#!/bin/bash
# Check which secrets have changed (without committing)

set -e

DOTFILES_DIR="$(git rev-parse --show-toplevel)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Source checksum utilities
source "$DOTFILES_DIR/scripts/checksum-utils.sh"

echo -e "${BLUE}=== Checking for secret changes ===${NC}"
echo

# Track if anything changed
ANYTHING_CHANGED=false

# Check env files
echo -e "${GREEN}Env files:${NC}"
CURRENT_ENV_CHECKSUM=$(calculate_env_checksum)
STORED_ENV_CHECKSUM=$(get_stored_checksum "env_files")

if [ -z "$STORED_ENV_CHECKSUM" ]; then
    echo -e "  ${YELLOW}⚠ No stored checksum (would sync on commit)${NC}"
    ANYTHING_CHANGED=true
elif [ "$CURRENT_ENV_CHECKSUM" != "$STORED_ENV_CHECKSUM" ]; then
    echo -e "  ${YELLOW}✗ Changed (would sync to Bitwarden)${NC}"
    echo -e "    Current:  $CURRENT_ENV_CHECKSUM"
    echo -e "    Stored:   $STORED_ENV_CHECKSUM"
    ANYTHING_CHANGED=true
else
    echo -e "  ${GREEN}✓ Unchanged (would skip sync)${NC}"
fi
echo

# Check kubeconfigs
echo -e "${GREEN}Kubeconfigs:${NC}"
CURRENT_KUBE_CHECKSUM=$(calculate_kube_checksum)
STORED_KUBE_CHECKSUM=$(get_stored_checksum "kubeconfigs")

if [ ! -d "$DOTFILES_DIR/kube/clusters" ]; then
    echo -e "  ${YELLOW}⚠ Directory not found${NC}"
elif [ -z "$STORED_KUBE_CHECKSUM" ]; then
    echo -e "  ${YELLOW}⚠ No stored checksum (would sync on commit)${NC}"
    ANYTHING_CHANGED=true
elif [ "$CURRENT_KUBE_CHECKSUM" != "$STORED_KUBE_CHECKSUM" ]; then
    echo -e "  ${YELLOW}✗ Changed (would sync to Bitwarden)${NC}"
    echo -e "    Current:  $CURRENT_KUBE_CHECKSUM"
    echo -e "    Stored:   $STORED_KUBE_CHECKSUM"
    ANYTHING_CHANGED=true
else
    echo -e "  ${GREEN}✓ Unchanged (would skip sync)${NC}"
fi
echo

# Check SSH keys
echo -e "${GREEN}SSH keys:${NC}"
CURRENT_SSH_CHECKSUM=$(calculate_ssh_checksum)
STORED_SSH_CHECKSUM=$(get_stored_checksum "ssh_keys")

if [ ! -d "$DOTFILES_DIR/ssh" ]; then
    echo -e "  ${YELLOW}⚠ Directory not found${NC}"
elif [ -z "$STORED_SSH_CHECKSUM" ]; then
    echo -e "  ${YELLOW}⚠ No stored checksum (would sync on commit)${NC}"
    ANYTHING_CHANGED=true
elif [ "$CURRENT_SSH_CHECKSUM" != "$STORED_SSH_CHECKSUM" ]; then
    echo -e "  ${YELLOW}✗ Changed (would sync to Bitwarden)${NC}"
    echo -e "    Current:  $CURRENT_SSH_CHECKSUM"
    echo -e "    Stored:   $STORED_SSH_CHECKSUM"
    ANYTHING_CHANGED=true
else
    echo -e "  ${GREEN}✓ Unchanged (would skip sync)${NC}"
fi
echo

# Summary
echo -e "${BLUE}=== Summary ===${NC}"
if [ "$ANYTHING_CHANGED" = true ]; then
    echo -e "${YELLOW}Changes detected - next commit will sync to Bitwarden${NC}"
    exit 1
else
    echo -e "${GREEN}No changes detected - next commit will be fast (<1s)${NC}"
    exit 0
fi
