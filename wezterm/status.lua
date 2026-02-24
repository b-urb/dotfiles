local wezterm = require("wezterm")
local bridge_gc = require("bridge_gc")

local M = {}
local CORNER_LEFT = utf8.char(0xe0b6)
local CORNER_RIGHT = utf8.char(0xe0b4)
local TAB_LEFT = utf8.char(0xe0b6)
local TAB_RIGHT = utf8.char(0xe0b4)

local TAB_BAR_BG = "#282c34"
local TAB_ACTIVE_EDGE = "#61afef"
local TAB_ACTIVE_BG = "#61afef"
local TAB_ACTIVE_FG = "#1e222a"
local TAB_INACTIVE_FG = "#5c6370"
local TAB_HOVER_FG = "#abb2bf"

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

local function mode_colors(mode)
	local palette = {
		NORMAL = { edge = "#7da55a", bg = "#98c379", fg = "#1e222a" },
		PANE = { edge = "#4b9bd6", bg = "#61afef", fg = "#1e222a" },
		TAB = { edge = "#a464bf", bg = "#c678dd", fg = "#1e222a" },
		RESIZE = { edge = "#c79f5d", bg = "#e5c07b", fg = "#1e222a" },
		SESSION = { edge = "#4aa4b0", bg = "#56b6c2", fg = "#1e222a" },
	}
	return palette[mode] or { edge = "#535965", bg = "#7f8795", fg = "#1e222a" }
end

local function push_badge(cells, icon, text, edge_color, badge_bg, badge_fg, bold)
	table.insert(cells, "ResetAttributes")
	table.insert(cells, { Foreground = { Color = edge_color } })
	table.insert(cells, { Text = CORNER_LEFT })
	table.insert(cells, "ResetAttributes")
	table.insert(cells, { Foreground = { Color = badge_fg } })
	table.insert(cells, { Background = { Color = badge_bg } })
	table.insert(cells, { Attribute = { Intensity = bold and "Bold" or "Normal" } })
	table.insert(cells, { Text = " " .. icon .. " " .. text .. " " })
	table.insert(cells, "ResetAttributes")
	table.insert(cells, { Foreground = { Color = edge_color } })
	table.insert(cells, { Text = CORNER_RIGHT .. " " })
end

local function build_right_status(window, pane)
	local workspace = compact(window:active_workspace(), 12)
	local domain = compact(pane and pane:get_domain_name() or "local", 12)
	local active_mode = key_table_mode(window)
	local clock = wezterm.strftime("%a %H:%M")

	local mode_style = mode_colors(active_mode)
	local cells = {}
	push_badge(cells, "󰘳", active_mode, mode_style.edge, mode_style.bg, mode_style.fg, true)
	push_badge(cells, "󱂬", workspace, "#a464bf", "#c678dd", "#1e222a", false)
	if domain ~= "local" then
		push_badge(cells, "󰆍", domain, "#c79f5d", "#e5c07b", "#1e222a", false)
	end
	push_badge(cells, "", clock, "#4b9bd6", "#61afef", "#1e222a", false)

	return wezterm.format(cells)
end

local function tab_title(tab)
	local manual_title = tab.tab_title
	if manual_title ~= nil and manual_title ~= "" then
		return manual_title
	end

	return "Tab " .. tostring(tab.tab_index + 1)
end

local function build_tab_title(tab, hover, max_width)
	local index = tostring(tab.tab_index + 1)
	local label = compact(tab_title(tab), 18)
	local title = wezterm.truncate_right(index .. ": " .. label, math.max(6, max_width - 6))

	if tab.is_active then
		local left = TAB_LEFT
		if tab.tab_index == 0 then
			left = " " .. left
		end
		return {
			"ResetAttributes",
			{ Background = { Color = TAB_BAR_BG } },
			{ Foreground = { Color = TAB_ACTIVE_EDGE } },
			{ Text = left },
			"ResetAttributes",
			{ Foreground = { Color = TAB_ACTIVE_FG } },
			{ Background = { Color = TAB_ACTIVE_BG } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = " " .. title .. " " },
			"ResetAttributes",
			{ Background = { Color = TAB_BAR_BG } },
			{ Foreground = { Color = TAB_ACTIVE_EDGE } },
			{ Text = TAB_RIGHT },
		}
	end

	return {
		"ResetAttributes",
		{ Background = { Color = TAB_BAR_BG } },
		{ Foreground = { Color = hover and TAB_HOVER_FG or TAB_INACTIVE_FG } },
		{ Text = " " .. title .. " " },
	}
end

function M.register(mode)
	wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
		return build_tab_title(tab, hover, max_width)
	end)

	wezterm.on("update-right-status", function(window, pane)
		bridge_gc.collect(mode)
		window:set_left_status("")
		window:set_right_status(build_right_status(window, pane))
	end)
end

return M
