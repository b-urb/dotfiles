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

# Install apm/apm.yml.in into dot_claude, dot_codex and dot_agents via APM (HOME pointed at the repo)
agents-sync:
    #!/usr/bin/env bash
    set -euo pipefail
    root="{{justfile_directory()}}"
    cd "$root"
    mkdir -p .apm agents
    ln -sfn dot_codex .codex
    ln -sfn agents .agents
    sed -e "s#@AGENT_CONFIG@#${AGENT_CONFIG:-$HOME/code/agent-config}#" -e "s#@HOMELAB@#${HOMELAB:-$HOME/code/homelab}#" -e "s#@DESIGN_SYSTEM@#${DESIGN_SYSTEM:-$HOME/code/design-system}#" apm/apm.yml.in > .apm/apm.yml
    HOME="$root" CLAUDE_CONFIG_DIR="$root/dot_claude" apm install -g --target claude,codex
    rm -rf dot_claude/skills/apm-lsp && mv .claude/skills/apm-lsp dot_claude/skills/
    mv dot_claude/skills/apm-lsp/.claude-plugin dot_claude/skills/apm-lsp/dot_claude-plugin
    find dot_claude -path '*/skills/*' -type f -name 'run_*' | while read -r f; do mv -f "$f" "$(dirname "$f")/literal_$(basename "$f")"; done
    for d in claude codex; do
        perl -pi -e "s#\Q$root\E/(?:\.|dot_)$d/#$HOME/.$d/#g" dot_$d/*.json
    done
