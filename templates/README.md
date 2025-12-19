# Template System

This directory contains template files with placeholders for secrets managed via Bitwarden CLI.

## Structure

- `*.tmpl` - Template files with `{{PLACEHOLDER}}` syntax
- Placeholders are replaced by `../scripts/populate-secrets.sh`

## Bitwarden Items

The following items must exist in Bitwarden:

| Item Name | Type | Description |
|-----------|------|-------------|
| dotfiles/github-pat | Password | GitHub Personal Access Token |
| dotfiles/directus-token | Password | Directus API Bearer Token |
| dotfiles/vault-token | Password | HashiCorp Vault Token |
| dotfiles/git-email | Password | Git commit email address |
| dotfiles/kubeconfigs | Secure Note | Kubernetes cluster configurations (as attachments) |

## Usage

```bash
# Populate all templates (requires BW_SESSION)
./scripts/populate-secrets.sh

# Or unlock and populate
export BW_SESSION=$(bw unlock --raw)
./scripts/populate-secrets.sh
```

## Adding New Secrets

1. Add placeholder to template file: `{{NEW_SECRET}}`
2. Store secret in Bitwarden: `bw create item ...`
3. Update `populate-secrets.sh` to replace placeholder
4. Update this README with new item

## Security

- Template files are tracked in git (safe - contain no secrets)
- Generated files are in `.gitignore` (not tracked)
- All secrets must be stored in Bitwarden
- Never commit generated files
