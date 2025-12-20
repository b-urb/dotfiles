# Troubleshooting Guide

Common issues and their solutions when installing or using these dotfiles.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Bitwarden Issues](#bitwarden-issues)
- [Symlink Issues](#symlink-issues)
- [Shell Issues](#shell-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Debugging Tips](#debugging-tips)

## Installation Issues

### Error: "Nonexistent target"

**Symptom**:
```
Nonexistent target ~/.ssh/config -> macos/ssh/config
```

**Cause**: The source file doesn't exist in the dotfiles repository.

**Solutions**:
1. Check if the file exists at the specified path:
   ```bash
   ls -la ~/.dotfiles/macos/ssh/config
   ```

2. If the file is missing, it may be:
   - Platform-specific and you're on the wrong OS
   - A generated file that hasn't been created yet (run `./install` fully)
   - A path error in `install.conf.yaml`

3. For platform-conditional symlinks, verify the `if` condition:
   ```yaml
   ~/.ssh/config:
     if: '[ "$(uname)" = Darwin ]'  # macOS only
   ```

### Error: "Incorrect link"

**Symptom**:
```
Incorrect link ~/.config/yabai -> /Users/username/.dotfiles/config/yabai/
```

**Cause**: An existing symlink points to a different location (often with/without trailing slash).

**Solutions**:
1. Check current symlink:
   ```bash
   ls -la ~/.config/yabai
   ```

2. Remove the existing symlink:
   ```bash
   rm ~/.config/yabai
   ```

3. Re-run installation:
   ```bash
   ./install
   ```

4. If error persists, add `relink: true` to the entry in `install.conf.yaml`:
   ```yaml
   ~/.config/yabai:
     path: config/yabai
     create: true
     relink: true
   ```

### Error: "BW_SESSION not set"

**Symptom**:
```
ERROR: BW_SESSION not set
Run: export BW_SESSION=$(bw unlock --raw)
```

**Cause**: Bitwarden CLI session not initialized.

**Solution**:
```bash
export BW_SESSION=$(bw unlock --raw)
```

Enter your master password when prompted. Then re-run the failing command.

**Session Timeout**: Bitwarden sessions expire after inactivity. If you get this error mid-session, re-run the unlock command.

### Error: "Folder not found in Bitwarden"

**Symptom**:
```
ERROR: Folder 'dotfiles/env-vars' not found in Bitwarden
Run: ./scripts/setup-bitwarden.sh to create folders
```

**Cause**: Required Bitwarden folder structure doesn't exist.

**Solution**:
```bash
export BW_SESSION=$(bw unlock --raw)
./scripts/setup-bitwarden.sh
```

This creates:
- `dotfiles/env-vars/`
- `dotfiles/kubeconfig/`

### Error: "Could not retrieve secret from folder"

**Symptom**:
```
Error: Could not retrieve 'github-pat' from folder
Make sure the item exists in the correct Bitwarden folder
```

**Cause**: Secret item doesn't exist in Bitwarden or has wrong name.

**Solutions**:
1. List items in the folder:
   ```bash
   ENV_VARS_FOLDER_ID=$(bw list folders | jq -r '.[] | select(.name=="dotfiles/env-vars") | .id')
   bw list items --folderid "$ENV_VARS_FOLDER_ID" | jq -r '.[].name'
   ```

2. Check item naming:
   - Item names must match exactly: `github-pat`, `git-email`, etc.
   - Use lowercase with dashes (not underscores)
   - No spaces

3. Create missing item:
   ```bash
   bw get template item | \
     jq ".folderId=\"$ENV_VARS_FOLDER_ID\" | .type=1 | .name=\"github-pat\" | .login.password=\"your_token_here\"" | \
     bw encode | \
     bw create item
   ```

4. Sync Bitwarden:
   ```bash
   bw sync --session "$BW_SESSION"
   ```

### Error: "Permission denied"

**Symptom**:
```
ln: ~/.zshrc: Permission denied
```

**Cause**: Existing file is owned by root or has restricted permissions.

**Solutions**:
1. Check file ownership:
   ```bash
   ls -la ~/.zshrc
   ```

2. If owned by root:
   ```bash
   sudo rm ~/.zshrc
   ./install
   ```

3. If you need to preserve the file:
   ```bash
   mv ~/.zshrc ~/.zshrc.backup
   ./install
   ```

## Bitwarden Issues

### Error: "You are not logged in"

**Symptom**:
```
You are not logged in.
```

**Solution**:
```bash
bw login your-email@example.com
export BW_SESSION=$(bw unlock --raw)
```

### Error: "Invalid master password"

**Symptom**:
```
Invalid master password.
```

**Solutions**:
1. Ensure you're typing the correct password
2. Check Caps Lock is off
3. If using self-hosted: verify server URL is correct
   ```bash
   bw config server https://warden.burbn.de
   ```

### Error: "Cannot decrypt"

**Symptom**:
```
Cannot decrypt. Invalid or missing key.
```

**Cause**: Session token expired or corrupted.

**Solution**:
```bash
unset BW_SESSION
export BW_SESSION=$(bw unlock --raw)
```

### Bitwarden Server Connection Issues

**Symptom**:
```
getaddrinfo ENOTFOUND warden.burbn.de
```

**Solutions**:
1. Check internet connection
2. Verify server URL:
   ```bash
   bw config server
   ```
3. Test server accessibility:
   ```bash
   curl https://warden.burbn.de
   ```
4. If server is down, contact administrator

### Session Keeps Expiring

**Symptom**: `BW_SESSION not set` errors frequently appear.

**Cause**: Default session timeout (15 minutes inactivity).

**Workarounds**:
1. Add to your shell profile to persist session:
   ```bash
   # NOT RECOMMENDED for security reasons
   export BW_SESSION="your_session_token"
   ```

2. Create an alias for quick unlock:
   ```bash
   alias bwu='export BW_SESSION=$(bw unlock --raw)'
   ```

3. Use `bw unlock --session` flag with commands:
   ```bash
   bw list items --session "$BW_SESSION"
   ```

## Symlink Issues

### Symlinks Not Created

**Symptom**: Files in `~/.config/` don't point to dotfiles.

**Solutions**:
1. Check Dotbot ran successfully:
   ```bash
   ./install
   ```
   Look for error messages in output.

2. Verify source files exist:
   ```bash
   ls -la ~/.dotfiles/config/nvim
   ```

3. Check `install.conf.yaml` syntax (YAML indentation matters)

### Broken Symlinks

**Symptom**:
```bash
$ ls -la ~/.config/nvim
lrwxr-xr-x  1 user  staff  30 Dec 19 10:00 nvim -> /wrong/path/nvim
```

**Solutions**:
1. Remove broken symlink:
   ```bash
   rm ~/.config/nvim
   ```

2. Re-run installation:
   ```bash
   ./install
   ```

3. If error persists, use `force: true`:
   ```yaml
   ~/.config/nvim:
     path: config/nvim
     create: true
     relink: true
     force: true
   ```

### Symlink Conflicts

**Symptom**:
```
Conflicting destination ~/.gitconfig already exists
```

**Solutions**:
1. Backup existing file:
   ```bash
   mv ~/.gitconfig ~/.gitconfig.backup
   ```

2. Re-run installation:
   ```bash
   ./install
   ```

3. Merge important settings from backup into dotfiles

## Shell Issues

### Zsh Not Loading

**Symptom**: Opening a terminal doesn't load custom config.

**Solutions**:
1. Check if Zsh is the default shell:
   ```bash
   echo $SHELL
   ```
   Should output: `/bin/zsh` or `/usr/bin/zsh`

2. If not, set Zsh as default:
   ```bash
   chsh -s $(which zsh)
   ```
   Log out and log back in.

3. Verify `~/.zshrc` symlink:
   ```bash
   ls -la ~/.zshrc
   ```
   Should point to `~/.dotfiles/zshrc`

4. If symlink is broken, re-run:
   ```bash
   ./install
   ```

### Plugins Not Loading

**Symptom**: Zsh loads but plugins (syntax highlighting, autosuggestions) don't work.

**Solutions**:
1. Check Zinit installation:
   ```bash
   ls -la ~/.local/share/zinit
   ```

2. If missing, Zinit will auto-install on first Zsh launch. Wait 30-60 seconds.

3. Manually install Zinit:
   ```bash
   bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
   ```

4. Reload shell:
   ```bash
   exec zsh
   ```

### Slow Shell Startup

**Symptom**: Opening a terminal takes 5+ seconds.

**Solutions**:
1. Profile startup time:
   ```bash
   time zsh -i -c exit
   ```

2. Enable profiling in `~/.zshrc`:
   ```bash
   # Add to top of zshrc
   zmodload zsh/zprof

   # Add to bottom of zshrc
   zprof
   ```

3. Reload and check output:
   ```bash
   exec zsh
   ```

4. Common culprits:
   - Too many Zinit plugins → Remove unused plugins from `zsh/40-plugins.zsh`
   - Compinit running multiple times → Check `zsh/20-completion.zsh`
   - NVM/RVM/other version managers → Lazy-load them

5. Reduce plugin count in `zsh/40-plugins.zsh`

### Command Not Found

**Symptom**:
```
zsh: command not found: kubectl
```

**Solutions**:
1. Check PATH:
   ```bash
   echo $PATH
   ```

2. Reload shell:
   ```bash
   exec zsh
   ```

3. If installed via Homebrew (macOS):
   ```bash
   brew list | grep kubectl
   ```
   If missing: `brew install kubectl`

4. Check `zsh/60-exports.zsh` for PATH modifications

### History Not Working

**Symptom**: Up arrow doesn't show previous commands.

**Solutions**:
1. Check history file:
   ```bash
   echo $HISTFILE
   ls -la $HISTFILE
   ```

2. Verify permissions:
   ```bash
   chmod 600 ~/.zsh_history
   ```

3. Check `zsh/30-history.zsh` settings

## Platform-Specific Issues

### macOS: Yabai Not Working

**Symptom**: Windows don't tile, Yabai not responding.

**Solutions**:
1. Check if Yabai is running:
   ```bash
   brew services list | grep yabai
   ```

2. Start Yabai:
   ```bash
   brew services start yabai
   ```

3. Check logs:
   ```bash
   tail -f /tmp/yabai_$USER.out.log
   tail -f /tmp/yabai_$USER.err.log
   ```

4. For full functionality, disable System Integrity Protection (SIP):
   - Restart in Recovery Mode (hold Cmd+R during boot)
   - Open Terminal from Utilities menu
   - Run: `csrutil disable`
   - Restart normally
   - See: https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection

### macOS: SKHD Not Responding

**Symptom**: Hotkeys not triggering Yabai commands.

**Solutions**:
1. Check if SKHD is running:
   ```bash
   brew services list | grep skhd
   ```

2. Start SKHD:
   ```bash
   brew services start skhd
   ```

3. Grant Accessibility permissions:
   - System Preferences → Security & Privacy → Accessibility
   - Add SKHD to the list
   - Enable checkbox

4. Reload SKHD config:
   ```bash
   brew services restart skhd
   ```

### macOS: Homebrew Packages Not Found

**Symptom**:
```
zsh: command not found: brew
```

**Solutions**:
1. Check if Homebrew is installed:
   ```bash
   ls -la /opt/homebrew  # Apple Silicon
   ls -la /usr/local/Homebrew  # Intel
   ```

2. Add to PATH (add to `zsh/os/darwin.zsh`):
   ```bash
   # Apple Silicon
   eval "$(/opt/homebrew/bin/brew shellenv)"

   # Intel
   eval "$(/usr/local/bin/brew shellenv)"
   ```

3. Reload shell:
   ```bash
   exec zsh
   ```

### Linux: i3 Not Loading

**Symptom**: i3 not available in display manager login.

**Solutions**:
1. Verify i3 is installed:
   ```bash
   which i3
   ```

2. Check desktop entry:
   ```bash
   ls -la /usr/share/xsessions/i3.desktop
   ```

3. Check i3 config syntax:
   ```bash
   i3 -C -c ~/.config/i3/config
   ```

4. View i3 logs:
   ```bash
   cat ~/.local/share/i3/log
   ```

### Linux: Display Manager Issues

**Symptom**: Can't select i3/Sway from login screen.

**Solutions**:
1. Check which display manager is running:
   ```bash
   systemctl status display-manager
   ```

2. Common display managers:
   - GDM (GNOME): `/usr/share/xsessions/`
   - LightDM: `/usr/share/xsessions/`
   - SDDM (KDE): `/usr/share/xsessions/`

3. Ensure i3/Sway desktop files exist in the correct location

## Debugging Tips

### Enable Verbose Mode

Add to scripts for detailed output:
```bash
set -x  # Print commands as they execute
```

### Check Dotbot Output

Re-run installation and watch for errors:
```bash
./install 2>&1 | tee install.log
```

Review `install.log` for issues.

### Verify install.conf.yaml Syntax

Check YAML is valid:
```bash
python3 -c "import yaml; yaml.safe_load(open('install.conf.yaml'))"
```

### List Bitwarden Items

See what secrets exist:
```bash
bw list items --folderid $(bw list folders | jq -r '.[] | select(.name=="dotfiles/env-vars") | .id') | jq -r '.[].name'
```

### Check Generated Files

Verify secrets were populated:
```bash
cat ~/.dotfiles/.env
cat ~/.dotfiles/gitconfig
```

**Warning**: These contain secrets. Don't share output.

### Test Individual Scripts

Run scripts manually:
```bash
export BW_SESSION=$(bw unlock --raw)
./scripts/populate-secrets.sh
```

### Check Symlinks

List all symlinks in home directory:
```bash
find ~ -maxdepth 3 -type l -ls | grep dotfiles
```

### Fresh Start

If all else fails, start fresh:
```bash
# Backup current dotfiles
mv ~/.dotfiles ~/.dotfiles.backup

# Remove symlinks
rm ~/.zshrc ~/.gitconfig ~/.config/nvim ~/.config/wezterm

# Re-clone
git clone --recursive git@github.com:B-urb/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Authenticate Bitwarden
export BW_SESSION=$(bw unlock --raw)

# Install
./install
```

## Getting Help

If you're still stuck:

1. **Check logs**: Most tools log to `/tmp/` or `~/.local/share/`
2. **Search issues**: Search this repository's GitHub issues
3. **Create issue**: Open a new issue with:
   - Your OS and version
   - Command you ran
   - Full error message
   - Contents of relevant log files

## Related Documentation

- [SETUP.md](SETUP.md) - Installation guide
- [STRUCTURE.md](STRUCTURE.md) - Architecture documentation
- [CONTRIBUTING.md](CONTRIBUTING.md) - Customization guide
