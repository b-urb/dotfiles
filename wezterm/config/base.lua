local wezterm = require("wezterm")

local M = {}

function M.build()
	return {
		font_size = 15.0,
		font = wezterm.font("Monaspace Argon", { weight = "Bold", italic = false }),
		color_scheme = "One Dark (Gogh)",
		enable_scroll_bar = true,
		window_background_opacity = 0.94,
		window_close_confirmation = "NeverPrompt",
		window_decorations = "RESIZE",
		window_padding = {
			top = 2,
		},
		inactive_pane_hsb = {
			saturation = 0.9,
			brightness = 0.72,
		},
		use_fancy_tab_bar = true,
		window_frame = {
			active_titlebar_bg = "#000000",
			inactive_titlebar_bg = "#000000",
			active_titlebar_border_bottom = "#61afef",
			inactive_titlebar_border_bottom = "#1f2329",
			font_size = 19.0,
		},
		hide_tab_bar_if_only_one_tab = false,
		show_new_tab_button_in_tab_bar = false,
		show_close_tab_button_in_tabs = false,
		tab_bar_style = {},
		colors = {
			split = "#61afef",
			tab_bar = {
				background = "#000000",
				new_tab = { bg_color = "#000000", fg_color = "#FCE8C3", intensity = "Bold" },
				new_tab_hover = { bg_color = "#000000", fg_color = "#FCE8C3", intensity = "Bold" },
				active_tab = { bg_color = "#000000", fg_color = "#FCE8C3" },
				inactive_tab = { bg_color = "#000000", fg_color = "#FCE8C3" },
				inactive_tab_edge = "#000000",
				inactive_tab_hover = { bg_color = "#000000", fg_color = "#FCE8C3" },
			},
		},
		audible_bell = "Disabled",
		visual_bell = {
			fade_in_duration_ms = 75,
			fade_out_duration_ms = 75,
			target = "CursorColor",
		},
	}
end

return M
