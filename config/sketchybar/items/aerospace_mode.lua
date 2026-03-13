local colors = require("colors")
local settings = require("settings")

sbar.add("event", "aerospace_mode_change")

local mode_item = sbar.add("item", "aerospace.mode", {
  position = "left",
  icon = {
    drawing = false,
  },
  label = {
    string = "DEF",
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Black"],
      size = 10.0,
    },
    padding_left = 8,
    padding_right = 8,
  },
  background = {
    drawing = true,
    color = colors.with_alpha(colors.bg1, 0.45),
    border_color = colors.with_alpha(colors.grey, 0.35),
    border_width = 1,
    corner_radius = 8,
    height = 24,
  },
  padding_left = 6,
  padding_right = 6,
})

local MODE_STYLE = {
  DEFAULT = {
    label = "DEF",
    label_color = colors.grey,
    border_color = colors.with_alpha(colors.grey, 0.35),
    background_color = colors.with_alpha(colors.bg1, 0.45),
  },
  RESIZE = {
    label = "RSZ",
    label_color = colors.yellow,
    border_color = colors.yellow,
    background_color = colors.with_alpha(colors.yellow, 0.2),
  },
  SERVICE = {
    label = "SRV",
    label_color = colors.red,
    border_color = colors.red,
    background_color = colors.with_alpha(colors.red, 0.2),
  },
}

local function set_mode(raw_mode)
  local mode = (raw_mode or "DEFAULT"):upper()
  local style = MODE_STYLE[mode] or MODE_STYLE.DEFAULT

  mode_item:set({
    label = {
      string = style.label,
      color = style.label_color,
    },
    background = {
      border_color = style.border_color,
      color = style.background_color,
    },
  })
end

mode_item:subscribe("aerospace_mode_change", function(env)
  set_mode(env.INFO)
end)

set_mode("DEFAULT")
