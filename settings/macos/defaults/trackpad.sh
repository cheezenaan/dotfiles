#!/bin/bash

# トラックパッド関連の設定
# --------------------------------------------------

echo "Applying trackpad settings..."

# トラックパッドのタップでクリック有効化
# デフォルト値: 0 (無効)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# トラックパッドの速度設定（感度を上げる）
# デフォルト値: 1.0
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.0

# マウスの速度設定（感度を上げる）
# デフォルト値: 1.0
defaults write NSGlobalDomain com.apple.mouse.scaling -float 2.5

# スクロールの方向: ナチュラル（コンテンツの方向にスクロール）
# true: コンテンツの方向へスクロール（標準）、false: 従来の方向へスクロール
# デフォルト値: true
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

# スクロールレスポンスの向上（減衰を減らす）
# デフォルト値: 0.1
defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false

echo "Trackpad settings applied successfully." 
