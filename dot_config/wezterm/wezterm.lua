local wezterm = require 'wezterm'
local config = {}

-- 設定ファイルを自動でリロードする
config.automatically_reload_config = true

-- カラースキームの設定
config.color_scheme = 'Nord (Gogh)'

config.font = wezterm.font_with_fallback({
  'UDEV Gothic 35',
  'PlemolJP Console35',
  'Menlo',
  'Monaco',
  'monospace',
}, {weight='Regular'})
config.font_size = 12.0
config.use_ime = true

config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 5,
}

-- タブバーのカスタマイズ
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

-- スクロールバーの非表示
config.enable_scroll_bar = false

-- ウィンドウの背景透明度
config.window_background_opacity = 0.9
config.text_background_opacity = 0.5
config.macos_window_background_blur = 20

return config 
