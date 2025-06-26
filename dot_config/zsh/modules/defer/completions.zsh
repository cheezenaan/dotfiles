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
# プロセスリスト色分け: PID(青)、プロセス名(デフォルト)、引数(太字)
typeset -g PROCESS_LIST_COLORS='=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:kill:*:processes' list-colors $PROCESS_LIST_COLORS
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,comm,cmd -w"

# ファイル補完の改善（最近変更されたファイルを優先）
zstyle ':completion:*:*:*:*:files' sort 'modification'
zstyle ':completion:*:*:*:*:globbed-files' sort 'modification'

# === fzf-tab設定 ===
# ファイル色分け用のLS_COLORS使用
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# fzf-tabの基本設定
zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' single-group ''
zstyle ':fzf-tab:*' fzf-flags --height=50% --preview-window=right:50%:wrap

# プレビュー設定
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -la $realpath'
zstyle ':fzf-tab:complete:kill:*' fzf-preview 'ps -f -p $word 2>/dev/null || echo "プロセス情報が取得できません"'

# Git補完のプレビュー設定
zstyle ':fzf-tab:complete:git-switch:*' fzf-preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%h %d %s %C(green)(%cr)" ${(Q)word} 2>/dev/null || echo "ブランチ情報を取得できません"'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%h %d %s %C(green)(%cr) %C(bold blue)<%an>%C(reset)" ${(Q)word} 2>/dev/null || echo "ブランチ情報を取得できません"'

# === パフォーマンス最適化（キャッシュ設定） ===
# キャッシュディレクトリパスの一元化
typeset -gr ZSH_COMPLETION_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# 基本キャッシュ設定
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$ZSH_COMPLETION_CACHE_DIR"

# キャッシュ容量制御（デフォルト100M、環境変数で調整可能）
typeset -g ZSH_CACHE_MAX_SIZE=${ZSH_CACHE_MAX_SIZE:-100M}

# 重いコマンドのキャッシュポリシー設定
zstyle ':completion:*:*:docker:*' cache-policy _docker_cache_policy
zstyle ':completion:*:*:docker-compose:*' cache-policy _docker_cache_policy
zstyle ':completion:*:*:aws:*' cache-policy _aws_cache_policy

# キャッシュポリシー関数の実装
# キャッシュ有効期限の定数
typeset -gr DOCKER_CACHE_HOURS=1
typeset -gr AWS_CACHE_HOURS=24

function _docker_cache_policy() {
  local -a oldp
  oldp=( "$1"(Nmh+$DOCKER_CACHE_HOURS) )  # 1時間でキャッシュ無効化
  return $#oldp  # 0=キャッシュ有効(新しい), 1=キャッシュ無効(古い)
}

function _aws_cache_policy() {
  local -a oldp
  oldp=( "$1"(Nmh+$AWS_CACHE_HOURS) )  # 24時間でキャッシュ無効化
  return $#oldp  # 0=キャッシュ有効(新しい), 1=キャッシュ無効(古い)
}

# キャッシュサイズ管理（定期的なクリーンアップ）
function _cleanup_completion_cache() {
  if [[ -d $ZSH_COMPLETION_CACHE_DIR ]]; then
    find "$ZSH_COMPLETION_CACHE_DIR" -type f -atime +7 -delete 2>/dev/null
  fi
}

# キャッシュディレクトリの作成
if [[ ! -d $ZSH_COMPLETION_CACHE_DIR ]]; then
  mkdir -p $ZSH_COMPLETION_CACHE_DIR
fi

# セッション開始時に実行（低頻度・10%の確率）
if (( RANDOM % 10 == 0 )); then
  _cleanup_completion_cache
fi

# === 個別ツール補完設定 ===
# Homebrew site-functionsで対応されていないツールの補完

# Docker補完の設定
if command -v docker &>/dev/null && command -v brew &>/dev/null; then
  typeset comp_dir="$(brew --prefix)/share/zsh/site-functions"
  typeset docker_comp="$comp_dir/_docker"
  
  if [[ ! -f $docker_comp ]] || [[ $docker_comp -ot $(command -v docker) ]]; then
    typeset tmp_comp=$(mktemp "${TMPDIR:-/tmp}/docker_comp.$$")
    if docker completion zsh > "$tmp_comp" 2>/dev/null; then
      mv "$tmp_comp" "$docker_comp"
    else
      rm -f "$tmp_comp"
    fi
  fi
fi


