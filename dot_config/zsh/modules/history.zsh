# History settings for session sharing
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

# Enable history sharing between sessions
setopt share_history

# History behavior options
setopt hist_ignore_dups     # Don't record duplicate commands
setopt hist_ignore_space    # Don't record commands starting with space
setopt hist_verify          # Show expanded history before execution
setopt hist_expand          # Expand history on space
setopt hist_reduce_blanks   # Remove extra blanks from commands
