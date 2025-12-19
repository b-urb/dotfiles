# Template System

This directory contains template files with placeholders for secrets managed via Bitwarden CLI.

## Structure

- `*.tmpl` - Template files with `{{PLACEHOLDER}}` syntax
- Placeholders are replaced by `../scripts/populate-secrets.sh`

## Bitwarden Items

The following items must exist in Bitwarden using a nested folder structure:

### Folder Structure
```
dotfiles/
├── dotfiles/env-vars/     - Environment variable secrets
└── dotfiles/kubeconfig/   - Kubernetes configurations
```

### Items in `dotfiles/env-vars/` folder:

| Item Name | Type | Description |
|-----------|------|-------------|
| github-pat | Password | GitHub Personal Access Token |
| directus-token | Password | Directus API Bearer Token |
| vault-token | Password | HashiCorp Vault Token |
| git-email | Password | Git commit email address |
| openai-api-key | Password | OpenAI API Key |
| azure-tenant-id | Password | Azure Tenant ID |
| azure-username | Password | Azure Default Username |

### Items in `dotfiles/kubeconfig/` folder:

| Item Name | Type | Description |
|-----------|------|-------------|
| kubeconfigs | Secure Note | Kubernetes cluster configurations (as attachments) |

**Note**: Bitwarden supports nested folders using slash notation. Create folders with names like `"dotfiles/env-vars"` to nest them under the parent `"dotfiles"` folder.

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
2. Store secret in Bitwarden `dotfiles/env-vars/` folder using template API:
   ```bash
   ENV_VARS_FOLDER_ID=$(bw list folders | jq -r '.[] | select(.name=="dotfiles/env-vars") | .id')
   bw get template item | jq ".folderId=\"$ENV_VARS_FOLDER_ID\" | .type=1 | .name=\"new-secret\" | .login.password=\"secret-value\"" | bw encode | bw create item
   ```
3. Update `populate-secrets.sh` to replace placeholder in the `populate_template()` function
4. Update this README with new item in the appropriate folder table

## Security

- Template files are tracked in git (safe - contain no secrets)
- Generated files are in `.gitignore` (not tracked)
- All secrets must be stored in Bitwarden
- Never commit generated files
