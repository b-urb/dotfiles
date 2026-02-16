-- ~/.config/wezterm/keybindings.lua
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- inside zellij, these env vars are typically present
local function in_zellij()
	return (wezterm.getenv("ZELLIJ") ~= nil)
		or (wezterm.getenv("ZELLIJ_SESSION_NAME") ~= nil)
		or (wezterm.getenv("ZELLIJ_PANE_ID") ~= nil)
end

function M.build()
	if in_zellij() then
		-- Let zellij own keybindings; keep wezterm mostly default
		return { leader = nil, keys = {}, key_tables = {} }
	end

	local leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1500 }

	local keys = {
		-- modes
		{ key = "p", mods = "LEADER", action = act.ActivateKeyTable({ name = "pane_mode", one_shot = false }) },
		{ key = "t", mods = "LEADER", action = act.ActivateKeyTable({ name = "tab_mode", one_shot = false }) },
		{ key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "session_mode", one_shot = false }) },

		-- common leader actions (optional)
		{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = "n", mods = "LEADER", action = act.SpawnWindow },
		{ key = "w", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
		{ key = "q", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

		-- send literal Ctrl-Space to app if needed
		{ key = "Space", mods = "LEADER", action = act.SendKey({ key = "Space", mods = "CTRL" }) },
	}

	local key_tables = {
		pane_mode = {
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "q", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },

			-- focus
			{ key = "h", action = act.ActivatePaneDirection("Left") },
			{ key = "j", action = act.ActivatePaneDirection("Down") },
			{ key = "k", action = act.ActivatePaneDirection("Up") },
			{ key = "l", action = act.ActivatePaneDirection("Right") },

			-- resize (Shift+hjkl)
			{ key = "H", action = act.AdjustPaneSize({ "Left", 5 }) },
			{ key = "J", action = act.AdjustPaneSize({ "Down", 3 }) },
			{ key = "K", action = act.AdjustPaneSize({ "Up", 3 }) },
			{ key = "L", action = act.AdjustPaneSize({ "Right", 5 }) },

			-- splits
			{ key = "v", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
			{ key = "s", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

			-- close / zoom / rotate / break out
			{ key = "x", action = act.CloseCurrentPane({ confirm = true }) },
			{ key = "z", action = act.TogglePaneZoomState },
			{ key = "r", action = act.RotatePanes("Clockwise") },
			{ key = "R", action = act.RotatePanes("CounterClockwise") },
			{ key = "b", action = act.MovePaneToNewTab },
		},

		tab_mode = {
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "q", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },

			-- nav
			{ key = "h", action = act.ActivateTabRelative(-1) },
			{ key = "l", action = act.ActivateTabRelative(1) },
			{ key = "p", action = act.ActivateTabRelative(-1) },
			{ key = "n", action = act.ActivateTabRelative(1) },

			-- create/close/reorder
			{ key = "c", action = act.SpawnTab("CurrentPaneDomain") },
			{ key = "x", action = act.CloseCurrentTab({ confirm = true }) },
			{ key = "H", action = act.MoveTabRelative(-1) },
			{ key = "L", action = act.MoveTabRelative(1) },

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

		session_mode = {
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "q", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },

			-- fuzzy find/switch workspaces ("sessions")
			{ key = "f", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
			{ key = "l", action = act.ShowLauncherArgs({ flags = "FUZZY|TABS|WORKSPACES" }) },

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

			-- new window
			{ key = "w", action = act.SpawnWindow },

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

	return { leader = leader, keys = keys, key_tables = key_tables }
end

return M
