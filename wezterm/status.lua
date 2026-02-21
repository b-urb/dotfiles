local wezterm = require("wezterm")

local M = {}
local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

local function uppercase_or_default(value, default_value)
	if value == nil or value == "" then
		return default_value
	end
	return string.upper(value)
end

local function compact(value, max_width)
	if value == nil or value == "" then
		return "-"
	end
	if #value <= max_width then
		return value
	end
	if max_width <= 2 then
		return value:sub(1, max_width)
	end
	return value:sub(1, max_width - 1) .. "~"
end

local function key_table_mode(window)
	local name = window:active_key_table()
	if name == nil or name == "" then
		return "NORMAL"
	end
	name = name:gsub("_mode$", "")
	return uppercase_or_default(name, "NORMAL")
end

local function build_right_status(window, pane)
	local workspace = compact(window:active_workspace(), 12)
	local domain = compact(pane and pane:get_domain_name() or "local", 8)
	local active_mode = key_table_mode(window)
	local clock = wezterm.strftime("%a %H:%M")

	local bg = "#0f1115"
	local c_mode = "#61afef"
	local c_ws = "#c678dd"
	local c_dom = "#e5c07b"
	local c_time = "#232834"
	local fg_dark = "#0b0d10"
	local fg_light = "#d2d8e3"

	local cells = {}

	local function push_segment(text, bg_color, fg_color, bold)
		table.insert(cells, { Foreground = { Color = bg_color } })
		table.insert(cells, { Background = { Color = bg } })
		table.insert(cells, { Text = SOLID_LEFT_ARROW })
		table.insert(cells, { Foreground = { Color = fg_color } })
		table.insert(cells, { Background = { Color = bg_color } })
		table.insert(cells, { Attribute = { Intensity = bold and "Bold" or "Normal" } })
		table.insert(cells, { Text = " " .. text })
		bg = bg_color
	end

	push_segment(clock, c_time, fg_light, false)
	push_segment("D:" .. domain, c_dom, fg_dark, false)
	push_segment("W:" .. workspace, c_ws, fg_dark, false)
	push_segment("M:" .. active_mode, c_mode, fg_dark, true)

	return wezterm.format(cells)
end

local function build_left_status()
	local cells = {
		{ Background = { Color = "#0f1115" } },
		{ Foreground = { Color = "#61afef" } },
		{ Text = " ●" },
		{ Foreground = { Color = "#9aa4b2" } },
		{ Text = " " },
	}
	return wezterm.format(cells)
end

function M.register()
	wezterm.on("update-right-status", function(window, pane)
		window:set_left_status(build_left_status())
		window:set_right_status(build_right_status(window, pane))
	end)
end

return M
