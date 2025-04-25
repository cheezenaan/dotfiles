#!/bin/bash

# アニメーション関連の設定
# --------------------------------------------------

echo "Applying animation settings..."

# ウィンドウのリサイズアニメーション高速化
# デフォルト値: 0.2
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Mission Controlのアニメーション高速化
# デフォルト値: 0.3
defaults write com.apple.dock expose-animation-duration -float 0.1

# Launchpadのアニメーション高速化
defaults write com.apple.dock springboard-show-duration -float 0.1
defaults write com.apple.dock springboard-hide-duration -float 0.1

# 保存ダイアログのアニメーション無効化
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# Finderのアニメーション無効化
# Quick Lookのズームエフェクト無効化
defaults write NSGlobalDomain QLPanelAnimationDuration -float 0

# 情報パネルのアニメーション無効化
defaults write com.apple.finder DisableAllAnimations -bool true

# スクリーンショットの影を無効化（スクリーンショットの取得を高速化）
defaults write com.apple.screencapture disable-shadow -bool true

echo "Animation settings applied successfully." 
