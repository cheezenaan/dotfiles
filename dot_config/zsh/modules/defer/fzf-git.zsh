# ghq + fzf integration
# CTRL+G でghqで管理しているリポジトリ一覧を表示し、選択したリポジトリにジャンプする
function ghq-fzf-cd() {
  local selected_dir=$(ghq list | fzf --query="$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd $(ghq root)/$selected_dir"
    zle accept-line
  fi
  zle reset-prompt
}

# Smart context-aware fzf function
function smart-fzf() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    # Inside git repository - show git file selector
    _fzf_git_files
  else
    # Outside git repository - show ghq repository selector
    ghq-fzf-cd
  fi
  zle reset-prompt
}

zle -N ghq-fzf-cd
zle -N smart-fzf
bindkey '^g' smart-fzf 
