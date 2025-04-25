#!/bin/bash

# キーボード関連の設定
# --------------------------------------------------

echo "Applying keyboard settings..."

# キーリピート速度の最速化
# デフォルト値: 2 (通常)
# 値が小さいほど遅く、大きいほど速い（0-15）
defaults write NSGlobalDomain KeyRepeat -int 1

# キーリピート開始までの待ち時間短縮
# デフォルト値: 15 (通常)
# 値が小さいほど短く、大きいほど長い（15-120）
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# 修飾キーのリマップを無効化（デフォルト設定を使用）
# defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "移動" "@$h"

# フルキーボードアクセスを有効化（Tabキーでのナビゲーションをすべてのコントロールに対して有効に）
# デフォルト値: 2 (テキストボックスとリストのみ)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

echo "Keyboard settings applied successfully." 
