# Dotfiles management tasks
# Usage: just <recipe>

# Default: show available recipes
default:
    @just --list

# Show what sync-back would change (dry-run)
sync-back *ARGS:
    python3 scripts/sync-back.py {{ARGS}}

# Fail if sync-back drift exists
sync-back-check *ARGS:
    python3 scripts/sync-back.py --check {{ARGS}}

# Apply sync-back changes to manifest files
sync-back-apply *ARGS:
    python3 scripts/sync-back.py --apply {{ARGS}}

# Sync a specific section (e.g. brew, vscode, cargo, scoop, winget)
sync-section SECTION:
    python3 scripts/sync-back.py --section {{SECTION}}

# Apply sync for a specific section
sync-section-apply SECTION:
    python3 scripts/sync-back.py --apply --section {{SECTION}}

# Run chezmoi apply (includes Ansible)
apply: merge-kubeconfigs
    chezmoi apply

# Apply dotfiles skipping Ansible — toggles skipAnsible, applies, restores
apply-fast:
    #!/usr/bin/env bash
    CONFIG="${HOME}/.config/chezmoi/chezmoi.toml"
    grep -q skipAnsible "$CONFIG" 2>/dev/null || printf '\n[data.features]\nskipAnsible = false\n' >> "$CONFIG"
    sed -i.bak 's/skipAnsible = false/skipAnsible = true/' "$CONFIG" && rm -f "$CONFIG.bak"
    trap 'sed -i.bak "s/skipAnsible = true/skipAnsible = false/" "$CONFIG" && rm -f "$CONFIG.bak"' EXIT
    chezmoi apply

# Run chezmoi diff to see pending changes
diff:
    chezmoi diff

# Merge local kubeconfig YAMLs from kube/clusters/ into ~/.kube/config
merge-kubeconfigs:
    bash kube/clusters/merge_clusters.sh
