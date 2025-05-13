#!/bin/bash

# Dock関連の設定
# --------------------------------------------------

echo "Applying Dock settings..."

# Dockの表示・非表示を高速化
# デフォルト値: 0.5（表示）、0.5（非表示）
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.2

# Dockを自動的に隠す
# デフォルト値: false
defaults write com.apple.dock autohide -bool true

# Dockのアニメーションを無効化
# デフォルト値: genie（ジーニーエフェクト）
defaults write com.apple.dock mineffect -string "scale"

# Dockのアイコンサイズを設定
# デフォルト値: 48
defaults write com.apple.dock tilesize -int 60

# Dockの拡大機能を有効にする
# デフォルト値: false
defaults write com.apple.dock magnification -bool true

# Dockの拡大時のアイコンサイズを設定
# デフォルト値: 64 (タイルサイズの1.5倍程度)
defaults write com.apple.dock largesize -int 120

# Dockの位置を左に設定
# デフォルト値: bottom
defaults write com.apple.dock orientation -string "left"

# 最近使ったアプリケーションをDockに表示しない
# デフォルト値: true
defaults write com.apple.dock show-recents -bool false

# 起動中のアプリケーションにバウンスアニメーションを表示しない
# デフォルト値: true
defaults write com.apple.dock no-bouncing -bool true

# 起動中のアプリケーションのみをDockに表示する
# 注意: この設定を有効にすると、Dockに手動で追加したアプリが表示されなくなります。
# デフォルト値: false
defaults write com.apple.dock static-only -bool true

# ホットコーナーの設定（左下をスクリーンセーバー）
# デフォルト値: 0（無効）
# 値: 2（Mission Control）、5（スクリーンセーバー）、6（ディスプレイをスリープ）、10（すべてのウインドウを表示）
# defaults write com.apple.dock wvous-bl-corner -int 5
# defaults write com.apple.dock wvous-bl-modifier -int 0

echo "Dock settings applied successfully."
