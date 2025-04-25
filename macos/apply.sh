#!/bin/bash

set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_DIR="${SCRIPT_DIR}/settings"

log_info "🚀 Starting MacOS settings application..."

# アクセス権の付与
chmod +x "${SETTINGS_DIR}"/*.sh

# 各設定スクリプトを実行
for settings_file in "${SETTINGS_DIR}"/*.sh; do
    if [ -f "${settings_file}" ]; then
        log_info "Applying: $(basename "${settings_file}")"
        "${settings_file}"
    fi
done

# 設定を反映するためのプロセスの再起動
log_info "🔄 Restarting processes to apply settings..."

# Finder の再起動
killall Finder &>/dev/null || true
log_info "✅ Finder restarted"

# Dock の再起動
killall Dock &>/dev/null || true
log_info "✅ Dock restarted"

# SystemUIServer の再起動
killall SystemUIServer &>/dev/null || true
log_info "✅ SystemUIServer restarted"

log_info "✨ MacOS settings applied successfully!"
log_info "🔍 Some settings may require a system restart to take effect." 
