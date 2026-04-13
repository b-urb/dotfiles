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

# Run chezmoi apply
apply:
    chezmoi apply

# Run chezmoi diff to see pending changes
diff:
    chezmoi diff
