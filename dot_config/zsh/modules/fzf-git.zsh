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

zle -N ghq-fzf-cd

# Use CTRL+G for ghq repository selection
# fzf-git.sh provides CTRL+G+F for git file selection automatically
bindkey '^g' ghq-fzf-cd
