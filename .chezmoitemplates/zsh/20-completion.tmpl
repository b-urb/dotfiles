# Completion Configuration

# Style for fzf-tab
# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# Set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# Preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# Switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'

# List of completers to use
zstyle ':completion:*::::' completer _expand _complete _ignored _approximate

# Allow one error for every three characters typed in approximate completer
zstyle -e ':completion:*:approximate:*' max-errors \
    'reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) numeric )'

# Insert all expansions for expand completer
zstyle ':completion:*:expand:*' tag-order all-expansions

# Formatting and messages
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''

# Match uppercase from lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Offer indexes before parameters in subscripts
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# Command for process lists, the local web server details and host completion
zstyle '*' hosts $hosts

# Filename suffixes to ignore during completion (except after rm command)
zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns '*?.o' '*?.c~' \
    '*?.old' '*?.pro'

# Ignore completion functions (until the _ignored completer)
zstyle ':completion:*:functions' ignored-patterns '_*'

# Load Git plugin from OMZ
zinit snippet OMZP::git

autoload -Uz compinit
compinit
