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

log_info "🔄 Restoring MacOS settings to defaults..."

# キーボード関連の設定を戻す
log_info "Resetting keyboard settings..."
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2

# トラックパッド関連の設定を戻す
log_info "Resetting trackpad settings..."
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool false
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool false
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 0
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 0
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 1.0
defaults write NSGlobalDomain com.apple.mouse.scaling -float 1.0
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true
defaults write NSGlobalDomain NSScrollAnimationEnabled -bool true

# アニメーション関連の設定を戻す
log_info "Resetting animation settings..."
defaults write NSGlobalDomain NSWindowResizeTime -float 0.2
defaults write com.apple.dock expose-animation-duration -float 0.3
defaults delete com.apple.dock springboard-show-duration 2>/dev/null || true
defaults delete com.apple.dock springboard-hide-duration 2>/dev/null || true
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool true
defaults write NSGlobalDomain QLPanelAnimationDuration -float 0.2
defaults write com.apple.finder DisableAllAnimations -bool false
defaults write com.apple.screencapture disable-shadow -bool false

# Dock関連の設定を戻す
log_info "Resetting Dock settings..."
defaults delete com.apple.dock autohide-delay 2>/dev/null || true
defaults delete com.apple.dock autohide-time-modifier 2>/dev/null || true
defaults write com.apple.dock autohide -bool false
defaults write com.apple.dock mineffect -string "genie"
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock show-recents -bool true
defaults write com.apple.dock no-bouncing -bool false

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

log_info "✨ MacOS settings restored successfully!"
log_info "🔍 Some settings may require a system restart to take effect." 
