local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback({
  "Cascadia Mono",
  "Consolas",
  "monospace",
})
config.font_size = 13.0
config.color_scheme = "Builtin Solarized Dark"
config.colors = {
  foreground = "#c9d1d9",
  background = "#0d1117",
  cursor_bg = "#c9d1d9",
  cursor_border = "#c9d1d9",
  cursor_fg = "#0d1117",
  selection_bg = "#1e4273",
  selection_fg = "#c9d1d9",
  split = "#58a6ff",
  ansi = {
    "#484f58",
    "#ec8e2c",
    "#58a6ff",
    "#d29922",
    "#58a6ff",
    "#bc8cff",
    "#39c5cf",
    "#b1bac4",
  },
  brights = {
    "#6e7681",
    "#fdac54",
    "#79c0ff",
    "#e3b341",
    "#79c0ff",
    "#d2a8ff",
    "#56d4dd",
    "#ffffff",
  },
  tab_bar = {
    background = "#0d1117",
    active_tab = { bg_color = "#58a6ff", fg_color = "#0d1117", intensity = "Bold" },
    inactive_tab = { bg_color = "#0d1117", fg_color = "#8b949e" },
    inactive_tab_hover = { bg_color = "#21262d", fg_color = "#c9d1d9" },
    new_tab = { bg_color = "#0d1117", fg_color = "#8b949e" },
    new_tab_hover = { bg_color = "#21262d", fg_color = "#58a6ff" },
  },
}

config.enable_scroll_bar = true
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.window_padding = { left = 4, right = 4, top = 2, bottom = 2 }
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.show_new_tab_button_in_tab_bar = false
config.audible_bell = "Disabled"

local wsl_domains = wezterm.default_wsl_domains()
local fedora_domain = nil
for _, domain in ipairs(wsl_domains) do
  local distribution = string.lower(domain.distribution or "")
  if string.find(distribution, "fedora", 1, true) then
    domain.default_prog = { "zsh", "-l" }
    fedora_domain = domain.name
    break
  end
end
config.wsl_domains = wsl_domains
if fedora_domain then
  config.default_domain = fedora_domain
else
  wezterm.log_warn("No Fedora WSL distribution found; keeping WezTerm's local domain")
end

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1500 }
config.keys = {
  { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
  { key = "d", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "r", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
  { key = "f", mods = "LEADER", action = act.TogglePaneZoomState },
  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "[", mods = "ALT", action = act.ActivateTabRelative(-1) },
  { key = "]", mods = "ALT", action = act.ActivateTabRelative(1) },
  { key = "b", mods = "CTRL", action = act.ActivateCopyMode },
}

wezterm.on("update-right-status", function(window, pane)
  local workspace = window:active_workspace()
  local domain = pane:get_domain_name()
  local clock = wezterm.strftime("%a %H:%M")
  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#8b949e" } },
    { Text = string.format(" %s | %s | %s ", workspace, domain, clock) },
  }))
end)

return config
