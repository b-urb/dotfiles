# Plugin Loading

zinit light junegunn/fzf
zinit light Aloxaf/fzf-tab
zinit for \
    zdharma-continuum/fast-syntax-highlighting

zinit load atuinsh/atuin

zinit from'gh-r' as'program' for \
    id-as'kubectx' bpick'kubectx*' ahmetb/kubectx \
    id-as'kubens' bpick'kubens*' ahmetb/kubectx

zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

eval "$(zoxide init zsh)"

# Zellij control:
#   DOTFILES_ZELLIJ_MODE=native|full|bridge
# Legacy fallback: DOTFILES_ENABLE_ZELLIJ=0|1 (used only when mode is unset)
_dotfiles_zellij_mode="${DOTFILES_ZELLIJ_MODE:l}"
if [[ -z "${_dotfiles_zellij_mode}" ]]; then
    case "${DOTFILES_ENABLE_ZELLIJ:l}" in
        1|true|yes|on)
            _dotfiles_zellij_mode="full"
            ;;
        *)
            _dotfiles_zellij_mode="native"
            ;;
    esac
fi

if command -v zellij >/dev/null 2>&1; then
    case "${_dotfiles_zellij_mode}" in
        full)
            eval "$(zellij setup --generate-auto-start zsh)"
            ;;
        bridge)
            # Bridge mode only applies in WezTerm and only when not already inside zellij.
            if [[ -n "${WEZTERM_PANE}" ]] && [[ -z "${ZELLIJ}" ]]; then
                _dotfiles_bridge_session="wt-bridge-${WEZTERM_PANE}"
                _dotfiles_bridge_config="${HOME}/.config/zellij/config.bridge.kdl"
                _dotfiles_bridge_layout="${HOME}/.config/zellij/layouts/bridge_plain.kdl"
                if [[ -f "${_dotfiles_bridge_config}" ]] && [[ -f "${_dotfiles_bridge_layout}" ]]; then
                    # Bridge sessions are ephemeral; recreate to ensure fresh config/keybinds.
                    zellij kill-session "${_dotfiles_bridge_session}" >/dev/null 2>&1
                    zellij --config "${_dotfiles_bridge_config}" --layout "${_dotfiles_bridge_layout}" attach -c "${_dotfiles_bridge_session}"
                fi
                unset _dotfiles_bridge_session _dotfiles_bridge_config _dotfiles_bridge_layout
            fi
            ;;
    esac
fi

unset _dotfiles_zellij_mode
