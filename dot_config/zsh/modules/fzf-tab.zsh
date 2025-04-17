# Configuarations for fzf-tab
# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# Use ls-colors for file coloring
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# Preview directory contents
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -la $realpath'

