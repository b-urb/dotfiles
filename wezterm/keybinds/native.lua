local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function move_pane_to_new_tab(_, pane)
	if pane ~= nil then
		pane:move_to_new_tab()
	end
end

local function focus_or_tab(direction, tab_delta)
	return wezterm.action_callback(function(window, pane)
		local tab = window:active_tab()
		local has_adjacent = false
		if tab ~= nil then
			local ok, target = pcall(function()
				return tab:get_pane_direction(direction)
			end)
			has_adjacent = ok and target ~= nil
		end

		if has_adjacent then
			window:perform_action(act.ActivatePaneDirection(direction), pane)
		else
			window:perform_action(act.ActivateTabRelative(tab_delta), pane)
		end
	end)
end

function M.build()
	local keys = {
		-- clipboard
		{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
		{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

		-- zellij-like global navigation/resize
		{ key = "h", mods = "CTRL", action = focus_or_tab("Left", -1) },
		{ key = "j", mods = "CTRL", action = act.ActivatePaneDirection("Down") },
		{ key = "k", mods = "CTRL", action = act.ActivatePaneDirection("Up") },
		{ key = "l", mods = "CTRL", action = focus_or_tab("Right", 1) },
		{ key = "H", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Left", 3 }) },
		{ key = "J", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Down", 2 }) },
		{ key = "K", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Up", 2 }) },
		{ key = "L", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Right", 3 }) },

		-- zellij-like alt shortcuts
		{ key = "LeftArrow", mods = "ALT", action = focus_or_tab("Left", -1) },
		{ key = "DownArrow", mods = "ALT", action = act.ActivatePaneDirection("Down") },
		{ key = "UpArrow", mods = "ALT", action = act.ActivatePaneDirection("Up") },
		{ key = "RightArrow", mods = "ALT", action = focus_or_tab("Right", 1) },
		{ key = "n", mods = "ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "i", mods = "ALT", action = act.MoveTabRelative(-1) },
		{ key = "o", mods = "ALT", action = act.MoveTabRelative(1) },
		{ key = "f", mods = "ALT", action = act.TogglePaneZoomState },
		{ key = "[", mods = "ALT", action = act.ActivateTabRelative(-1) },
		{ key = "]", mods = "ALT", action = act.ActivateTabRelative(1) },

		-- modes
		{ key = "p", mods = "CTRL", action = act.ActivateKeyTable({ name = "pane_mode", one_shot = false }) },
		{ key = "t", mods = "CTRL", action = act.ActivateKeyTable({ name = "tab_mode", one_shot = false }) },
		{ key = "o", mods = "CTRL", action = act.ActivateKeyTable({ name = "session_mode", one_shot = false }) },
		{ key = "n", mods = "CTRL", action = act.ActivateKeyTable({ name = "resize_mode", one_shot = false }) },
		{ key = "/", mods = "CTRL", action = act.ActivateCopyMode },

		-- app/session actions
		{ key = "q", mods = "CTRL", action = act.QuitApplication },
	}

	local key_tables = {
		pane_mode = {
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "q", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },
			{ key = "p", mods = "CTRL", action = "PopKeyTable" },

			-- focus
			{ key = "h", action = act.ActivatePaneDirection("Left") },
			{ key = "j", action = act.ActivatePaneDirection("Down") },
			{ key = "k", action = act.ActivatePaneDirection("Up") },
			{ key = "l", action = act.ActivatePaneDirection("Right") },
			{ key = "LeftArrow", action = act.ActivatePaneDirection("Left") },
			{ key = "DownArrow", action = act.ActivatePaneDirection("Down") },
			{ key = "UpArrow", action = act.ActivatePaneDirection("Up") },
			{ key = "RightArrow", action = act.ActivatePaneDirection("Right") },

			-- resize (Shift+hjkl)
			{ key = "H", action = act.AdjustPaneSize({ "Left", 5 }) },
			{ key = "J", action = act.AdjustPaneSize({ "Down", 3 }) },
			{ key = "K", action = act.AdjustPaneSize({ "Up", 3 }) },
			{ key = "L", action = act.AdjustPaneSize({ "Right", 5 }) },

			-- zellij-like pane actions
			{ key = "d", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
			{ key = "r", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
			{ key = "n", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
			{ key = "f", action = act.TogglePaneZoomState },
			{ key = "p", action = act.ActivatePaneDirection("Next") },

			-- close / break out
			{ key = "x", action = act.CloseCurrentPane({ confirm = true }) },
			{
				key = "b",
				action = wezterm.action_callback(move_pane_to_new_tab),
			},
		},

		tab_mode = {
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "q", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },
			{ key = "t", mods = "CTRL", action = "PopKeyTable" },

			-- nav
			{ key = "h", action = act.ActivateTabRelative(-1) },
			{ key = "l", action = act.ActivateTabRelative(1) },
			{ key = "p", action = act.ActivateTabRelative(-1) },
			{ key = "j", action = act.ActivateTabRelative(1) },
			{ key = "k", action = act.ActivateTabRelative(-1) },
			{ key = "Tab", action = act.ActivateLastTab },

			-- create/close/reorder
			{ key = "c", action = act.SpawnTab("CurrentPaneDomain") },
			{ key = "n", action = act.SpawnTab("CurrentPaneDomain") },
			{ key = "x", action = act.CloseCurrentTab({ confirm = true }) },
			{ key = "H", action = act.MoveTabRelative(-1) },
			{ key = "L", action = act.MoveTabRelative(1) },
			{
				key = "b",
				action = wezterm.action_callback(move_pane_to_new_tab),
			},

			-- rename
			{
				key = "r",
				action = act.PromptInputLine({
					description = "Rename tab",
					action = wezterm.action_callback(function(window, _, line)
						if line and line ~= "" then
							window:active_tab():set_title(line)
						end
					end),
				}),
			},

			-- jump 1..9
			{ key = "1", action = act.ActivateTab(0) },
			{ key = "2", action = act.ActivateTab(1) },
			{ key = "3", action = act.ActivateTab(2) },
			{ key = "4", action = act.ActivateTab(3) },
			{ key = "5", action = act.ActivateTab(4) },
			{ key = "6", action = act.ActivateTab(5) },
			{ key = "7", action = act.ActivateTab(6) },
			{ key = "8", action = act.ActivateTab(7) },
			{ key = "9", action = act.ActivateTab(8) },
		},

		resize_mode = {
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "q", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },
			{ key = "n", mods = "CTRL", action = "PopKeyTable" },

			{ key = "h", action = act.AdjustPaneSize({ "Left", 2 }) },
			{ key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
			{ key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
			{ key = "l", action = act.AdjustPaneSize({ "Right", 2 }) },
			{ key = "H", action = act.AdjustPaneSize({ "Right", 2 }) },
			{ key = "J", action = act.AdjustPaneSize({ "Up", 2 }) },
			{ key = "K", action = act.AdjustPaneSize({ "Down", 2 }) },
			{ key = "L", action = act.AdjustPaneSize({ "Left", 2 }) },
			{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 2 }) },
			{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 2 }) },
			{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 2 }) },
			{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 2 }) },
		},

		session_mode = {
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "q", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },
			{ key = "o", mods = "CTRL", action = "PopKeyTable" },

			-- fuzzy find/switch workspaces ("sessions")
			{ key = "f", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
			{ key = "w", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
			{ key = "l", action = act.ShowLauncherArgs({ flags = "FUZZY|TABS|WORKSPACES" }) },
			{ key = "c", action = act.ActivateCommandPalette },

			-- new workspace (prompt)
			{
				key = "n",
				action = act.PromptInputLine({
					description = "New workspace name",
					action = wezterm.action_callback(function(window, pane, line)
						if not line or line == "" then
							return
						end
						window:perform_action(
							act.SwitchToWorkspace({ name = line, spawn = { domain = "CurrentPaneDomain" } }),
							pane
						)
					end),
				}),
			},

			-- switch workspace by name (prompt)
			{
				key = "s",
				action = act.PromptInputLine({
					description = "Switch to workspace",
					action = wezterm.action_callback(function(window, pane, line)
						if not line or line == "" then
							return
						end
						window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
					end),
				}),
			},

			-- "rename" workspace (switch to a new name)
			{
				key = "r",
				action = act.PromptInputLine({
					description = "Rename workspace (switch to new name)",
					action = wezterm.action_callback(function(window, pane, line)
						if not line or line == "" then
							return
						end
						window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
					end),
				}),
			},
		},
	}

	return { leader = nil, keys = keys, key_tables = key_tables, disable_default_key_bindings = true }
end

return M
