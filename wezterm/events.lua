local wezterm = require("wezterm")

local M = {}

local VIM_ICON = utf8.char(0xe62b)
local SUP_IDX = {
	"¹",
	"²",
	"³",
	"⁴",
	"⁵",
	"⁶",
	"⁷",
	"⁸",
	"⁹",
	"¹⁰",
	"¹¹",
	"¹²",
	"¹³",
	"¹⁴",
	"¹⁵",
	"¹⁶",
	"¹⁷",
	"¹⁸",
	"¹⁹",
	"²⁰",
}
local SUB_IDX = {
	"₁",
	"₂",
	"₃",
	"₄",
	"₅",
	"₆",
	"₇",
	"₈",
	"₉",
	"₁₀",
	"₁₁",
	"₁₂",
	"₁₃",
	"₁₄",
	"₁₅",
	"₁₆",
	"₁₇",
	"₁₈",
	"₁₉",
	"₂₀",
}
local SOLID_LEFT_ARROW = utf8.char(0xe0ba)
local SOLID_LEFT_MOST = utf8.char(0x2588)
local SOLID_RIGHT_ARROW = utf8.char(0xe0bc)

local function basename(s)
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

function M.register()
	wezterm.on("update-right-status", function(window, _)
		local name = window:active_key_table()
		if name then
			name = "TABLE: " .. name
		end
		window:set_right_status(name or "")
	end)

	wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
		local edge_background = "#000000"
		local background = "#4E4E4E"
		local foreground = "#1C1B19"
		local dim_foreground = "#000000"

		if tab.is_active then
			background = "#90EE90"
			foreground = "#1C1B19"
		elseif hover then
			background = "#32CD32"
			foreground = "#1C1B19"
		end

		local edge_foreground = background
		local process_name = tab.active_pane.foreground_process_name
		local pane_title = tab.active_pane.title
		local exec_name = basename(process_name):gsub("%.exe$", "")
		local title_with_icon

		if exec_name == "nvim" then
			title_with_icon = VIM_ICON .. pane_title:gsub("^(%S+)%s+(%d+/%d+) %- nvim", " %2 %1")
		else
			title_with_icon = pane_title
		end

		local left_arrow = SOLID_LEFT_ARROW
		if tab.tab_index == 0 then
			left_arrow = SOLID_LEFT_MOST
		end
		local id = SUB_IDX[tab.tab_index + 1]
		local pid = SUP_IDX[tab.active_pane.pane_index + 1]
		local title = " " .. wezterm.truncate_right(title_with_icon, max_width - 5) .. " "

		return {
			{ Attribute = { Intensity = "Bold" } },
			{ Background = { Color = edge_background } },
			{ Foreground = { Color = edge_foreground } },
			{ Text = left_arrow },
			{ Background = { Color = background } },
			{ Foreground = { Color = foreground } },
			{ Text = id },
			{ Text = title },
			{ Foreground = { Color = dim_foreground } },
			{ Text = pid },
			{ Background = { Color = edge_background } },
			{ Foreground = { Color = edge_foreground } },
			{ Text = SOLID_RIGHT_ARROW },
			{ Attribute = { Intensity = "Bold" } },
		}
	end)
end

return M
