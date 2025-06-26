# === 補完マッチング戦略 ===
# 基本マッチング: 完全一致と部分文字列マッチ
zstyle ':completion:*' matcher-list '' 'r:|[._-]=* r:|=*'

# === 視覚的改善 ===
# 補完メニューの基本設定（fzf-tabとの統合）
zstyle ':completion:*' list-separator '  →  '
zstyle ':completion:*' auto-description 'specify: %d'

# 補完の再ハッシュを有効化（新しいコマンドを即座に認識）
zstyle ':completion:*' rehash true

# === カテゴリ別の色分けとフォーマット（数字コード使用） ===
# 数字ベースのANSI色コードで確実に色分け
zstyle ':completion:*:descriptions' format $'\033[1;32m[%d]\033[0m'     # 太字緑色
zstyle ':completion:*:corrections' format $'\033[1;33m%d (errors: %e)\033[0m'  # 太字黄色  
zstyle ':completion:*:messages' format $'\033[1;35m%d\033[0m'          # 太字マゼンタ
zstyle ':completion:*:warnings' format $'\033[1;31mno matches found\033[0m'    # 太字赤色

# プロセス表示の改善
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm,cmd -w -w"

# ファイル補完の改善（最近変更されたファイルを優先）
zstyle ':completion:*:*:*:*:files' sort 'modification'
zstyle ':completion:*:*:*:*:globbed-files' sort 'modification'

# === fzf-tab設定 ===
# Use ls-colors for file coloring
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# fzf-tabの動作調整（候補数に関係なくfzf-tabを使用）
zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' single-group ''

# Preview directory contents
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -la $realpath'

# Git補完のプレビュー設定
zstyle ':fzf-tab:complete:git-switch:*' fzf-preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%h %d %s %C(green)(%cr)" ${(Q)word}'

# === パフォーマンス最適化（キャッシュ設定） ===
# 基本キャッシュ設定
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# 重いコマンドのキャッシュポリシー設定
zstyle ':completion:*:*:docker:*' cache-policy _docker_cache_policy
zstyle ':completion:*:*:docker-compose:*' cache-policy _docker_cache_policy
zstyle ':completion:*:*:aws:*' cache-policy _aws_cache_policy

# キャッシュポリシー関数の実装
function _docker_cache_policy() {
  local -a oldp
  oldp=( "$1"(Nmh+1) )  # 1時間でキャッシュ無効化
  (( $#oldp ))
}

function _aws_cache_policy() {
  local -a oldp
  oldp=( "$1"(Nmh+24) )  # 24時間でキャッシュ無効化
  (( $#oldp ))
}

# キャッシュディレクトリの作成
() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
  [[ -d $cache_dir ]] || mkdir -p $cache_dir
}

