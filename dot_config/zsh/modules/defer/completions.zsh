# === 補完マッチング戦略 ===
# 基本マッチング: 完全一致と部分文字列マッチ
zstyle ':completion:*' matcher-list '' 'r:|[._-]=* r:|=*'

# === 視覚的改善 ===
# 補完メニューの見た目
zstyle ':completion:*' menu select=2
zstyle ':completion:*' list-separator '  →  '
zstyle ':completion:*' auto-description 'specify: %d'

# 補完の再ハッシュを有効化（新しいコマンドを即座に認識）
zstyle ':completion:*' rehash true

# === fzf-tab設定 ===
# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# Use ls-colors for file coloring
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# fzf-tab統合設定
# 2個以上の候補でfzf-tab、1個以下で通常補完
zstyle ':completion:*' menu select=2

# Preview directory contents
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -la $realpath'

