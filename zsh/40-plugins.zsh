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

# Autojump - OS-specific sourcing
if is_macos; then
    [ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh
elif is_linux; then
    [[ -s /etc/profile.d/autojump.zsh ]] && source /etc/profile.d/autojump.zsh
fi
