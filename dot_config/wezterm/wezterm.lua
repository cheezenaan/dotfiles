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

-- タイトルバーを削除
config.window_decorations = 'RESIZE'

-- ウィンドウの背景透明度
config.window_background_opacity = 0.85
config.text_background_opacity = 0.5
config.macos_window_background_blur = 20

-- アクティブタグに色をつける
wezterm.on("format-tab-title", function(tab, _tabs, _panes, _config, _hover, max_width)
  local background = "#5c6d74"
  local foreground = "#FFFFFF"

  if tab.is_active then
    background = "#ae8b2d"
    foreground = "#FFFFFF"
  end

  -- タイトルの文字列を切り詰めて表示する
  local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "

  return {
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
  }
end)

return config 
