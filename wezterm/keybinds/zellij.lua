local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.build()
	return {
		leader = nil,
		keys = {
			{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
			{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
		},
		key_tables = {},
		disable_default_key_bindings = true,
		enable_tab_bar = false,
	}
end

return M
