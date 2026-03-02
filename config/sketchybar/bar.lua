local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
  topmost = "window",
  position = "top",
  height = 40,
  y_offset = 8,
  margin = 8,
  corner_radius = 14,
  color = colors.bar.bg,
  border_color = colors.bar.border,
  border_width = 1,
  padding_right = 6,
  padding_left = 6,
})
