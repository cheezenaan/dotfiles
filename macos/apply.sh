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
BACKUP_DIR="${SCRIPT_DIR}/backup"

# バックアップディレクトリの作成
mkdir -p "${BACKUP_DIR}"

# タイムスタンプの設定
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/defaults_backup_${TIMESTAMP}.txt"

log_info "🔄 Creating backup..."

# バックアップする主要なdefaultsドメイン
DOMAINS=(
  "NSGlobalDomain"
  "com.apple.dock"
  "com.apple.finder"
  "com.apple.driver.AppleBluetoothMultitouch.trackpad"
  "com.apple.AppleMultitouchTrackpad"
  "com.apple.screencapture"
)

# ファイルの開始部分に時間情報を追加
echo "# MacOS defaults backup - $(date)" > "${BACKUP_FILE}"
echo "# ----------------------------------------" >> "${BACKUP_FILE}"
echo "" >> "${BACKUP_FILE}"

# 各ドメインの設定をバックアップ
for domain in "${DOMAINS[@]}"; do
  echo "# Domain: ${domain}" >> "${BACKUP_FILE}"
  echo "# ----------------------------------------" >> "${BACKUP_FILE}"
  defaults read "${domain}" 2>/dev/null | sed 's/^/    /' >> "${BACKUP_FILE}" || echo "    # No settings found" >> "${BACKUP_FILE}"
  echo "" >> "${BACKUP_FILE}"
done

# 追加のキー設定をバックアップ
echo "# Current keyboard settings" >> "${BACKUP_FILE}"
echo "# ----------------------------------------" >> "${BACKUP_FILE}"
echo "KeyRepeat: $(defaults read NSGlobalDomain KeyRepeat 2>/dev/null || echo "Not set")" >> "${BACKUP_FILE}"
echo "InitialKeyRepeat: $(defaults read NSGlobalDomain InitialKeyRepeat 2>/dev/null || echo "Not set")" >> "${BACKUP_FILE}"
echo "AppleKeyboardUIMode: $(defaults read NSGlobalDomain AppleKeyboardUIMode 2>/dev/null || echo "Not set")" >> "${BACKUP_FILE}"
echo "" >> "${BACKUP_FILE}"

# トラックパッド固有の設定をバックアップ
echo "# Current trackpad settings" >> "${BACKUP_FILE}"
echo "# ----------------------------------------" >> "${BACKUP_FILE}"
echo "Clicking: $(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking 2>/dev/null || echo "Not set")" >> "${BACKUP_FILE}"
echo "com.apple.trackpad.scaling: $(defaults read NSGlobalDomain com.apple.trackpad.scaling 2>/dev/null || echo "Not set")" >> "${BACKUP_FILE}"
echo "com.apple.mouse.scaling: $(defaults read NSGlobalDomain com.apple.mouse.scaling 2>/dev/null || echo "Not set")" >> "${BACKUP_FILE}"
echo "" >> "${BACKUP_FILE}"

log_info "✅ Backup created: ${BACKUP_FILE}"

# 各設定を適用
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
