local wezterm = require("wezterm")
local act = wezterm.action

local M = {}
local nvim_bottom_panes = {}

local function move_pane_to_new_tab(_, pane)
	if pane ~= nil then
		pane:move_to_new_tab()
	end
end

local function is_vim(pane)
	return pane and pane:get_user_vars().IS_NVIM == "true"
end

local function tab_key(tab)
	local ok, tab_id = pcall(function()
		return tab:tab_id()
	end)
	if ok and tab_id ~= nil then
		return tostring(tab_id)
	end
	return tostring(tab)
end

local function find_pane_info_by_id(tab, pane_id)
	if pane_id == nil then
		return nil
	end
	for _, info in ipairs(tab:panes_with_info()) do
		if info.pane:pane_id() == pane_id then
			return info
		end
	end
	return nil
end

local function is_tab_zoomed(tab)
	local panes = tab:panes_with_info()
	if #panes == 0 then
		return false
	end
	return panes[1].is_zoomed == true
end

local function cleanup_nvim_bottom_state(tab)
	local key = tab_key(tab)
	local state = nvim_bottom_panes[key]
	if state == nil then
		return nil, key
	end

	if state.owner_pane_id == nil or state.terminal_pane_id == nil then
		nvim_bottom_panes[key] = nil
		return nil, key
	end

	if find_pane_info_by_id(tab, state.owner_pane_id) == nil then
		nvim_bottom_panes[key] = nil
		return nil, key
	end

	if find_pane_info_by_id(tab, state.terminal_pane_id) == nil then
		nvim_bottom_panes[key] = nil
		return nil, key
	end

	return state, key
end

local function tab_has_only_tracked_pair(tab, state)
	local panes = tab:panes_with_info()
	if #panes ~= 2 then
		return false
	end

	local owner_found = false
	local terminal_found = false
	for _, info in ipairs(panes) do
		local id = info.pane:pane_id()
		if id == state.owner_pane_id then
			owner_found = true
		elseif id == state.terminal_pane_id then
			terminal_found = true
		end
	end

	return owner_found and terminal_found
end

local function toggle_nvim_bottom_terminal(trigger_key)
	return wezterm.action_callback(function(window, pane)
		local tab = window:active_tab()
		if tab == nil then
			window:perform_action(act.SendKey({ key = trigger_key, mods = "CTRL" }), pane)
			return
		end

		local state, key = cleanup_nvim_bottom_state(tab)
		local pane_id = pane and pane:pane_id() or nil
		local from_nvim = is_vim(pane)

		if state ~= nil then
			local from_owner_pane = pane_id == state.owner_pane_id
			local from_bottom_pane = pane_id == state.terminal_pane_id

			if not from_owner_pane and not from_bottom_pane then
				if not from_nvim then
					window:perform_action(act.SendKey({ key = trigger_key, mods = "CTRL" }), pane)
				end
				return
			end

			if not tab_has_only_tracked_pair(tab, state) then
				return
			end

			local owner_info = find_pane_info_by_id(tab, state.owner_pane_id)
			local bottom_info = find_pane_info_by_id(tab, state.terminal_pane_id)
			if owner_info == nil or bottom_info == nil then
				nvim_bottom_panes[key] = nil
				return
			end

			if is_tab_zoomed(tab) then
				tab:set_zoomed(false)
				bottom_info.pane:activate()
				state.hidden = false
				return
			end

			if from_bottom_pane then
				owner_info.pane:activate()
			end

			tab:set_zoomed(true)
			state.hidden = true
			return
		end

		if not from_nvim then
			window:perform_action(act.SendKey({ key = trigger_key, mods = "CTRL" }), pane)
			return
		end

		local bottom_pane = pane:split({
			direction = "Bottom",
			size = 0.30,
		})
		bottom_pane:activate()
		nvim_bottom_panes[key] = {
			owner_pane_id = pane_id,
			terminal_pane_id = bottom_pane:pane_id(),
			hidden = false,
		}
	end)
end

local function perform_focus_or_tab(window, pane, direction, tab_delta)
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
end

local function smart_move_action(key, direction, tab_delta)
	return wezterm.action_callback(function(window, pane)
		if is_vim(pane) then
			window:perform_action(act.SendKey({ key = key, mods = "CTRL" }), pane)
			return
		end
		if tab_delta ~= nil then
			perform_focus_or_tab(window, pane, direction, tab_delta)
		else
			window:perform_action(act.ActivatePaneDirection(direction), pane)
		end
	end)
end

local function smart_resize_action(key, direction, amount)
	return wezterm.action_callback(function(window, pane)
		if is_vim(pane) then
			window:perform_action(act.SendKey({ key = key, mods = "ALT" }), pane)
			return
		end
		window:perform_action(act.AdjustPaneSize({ direction, amount }), pane)
	end)
end

function M.build()
	local keys = {
		-- clipboard
		{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
		{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

		-- zellij-like global navigation/resize
		{ key = "h", mods = "CTRL", action = smart_move_action("h", "Left", -1) },
		{ key = "j", mods = "CTRL", action = smart_move_action("j", "Down") },
		{ key = "k", mods = "CTRL", action = smart_move_action("k", "Up") },
		{ key = "l", mods = "CTRL", action = smart_move_action("l", "Right", 1) },
		{ key = "h", mods = "ALT", action = smart_resize_action("h", "Left", 3) },
		{ key = "j", mods = "ALT", action = smart_resize_action("j", "Down", 2) },
		{ key = "k", mods = "ALT", action = smart_resize_action("k", "Up", 2) },
		{ key = "l", mods = "ALT", action = smart_resize_action("l", "Right", 3) },

		-- zellij-like alt shortcuts
		{ key = "LeftArrow", mods = "ALT", action = smart_move_action("h", "Left", -1) },
		{ key = "DownArrow", mods = "ALT", action = act.ActivatePaneDirection("Down") },
		{ key = "UpArrow", mods = "ALT", action = act.ActivatePaneDirection("Up") },
		{ key = "RightArrow", mods = "ALT", action = smart_move_action("l", "Right", 1) },
		{ key = "n", mods = "ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "i", mods = "ALT", action = act.MoveTabRelative(-1) },
		{ key = "o", mods = "ALT", action = act.MoveTabRelative(1) },
		{ key = "f", mods = "ALT", action = act.TogglePaneZoomState },
		{ key = "[", mods = "ALT", action = act.ActivateTabRelative(-1) },
		{ key = "]", mods = "ALT", action = act.ActivateTabRelative(1) },

		-- modes
		{ key = "p", mods = "LEADER", action = act.ActivateKeyTable({ name = "pane_mode", one_shot = false }) },
		{ key = "t", mods = "LEADER", action = act.ActivateKeyTable({ name = "tab_mode", one_shot = false }) },
		{ key = "o", mods = "LEADER", action = act.ActivateKeyTable({ name = "session_mode", one_shot = false }) },
		{ key = "n", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_mode", one_shot = false }) },
		{ key = "/", mods = "CTRL", action = toggle_nvim_bottom_terminal("/") },
		{ key = "_", mods = "CTRL", action = toggle_nvim_bottom_terminal("_") },
		{ key = "b", mods = "CTRL", action = act.ActivateCopyMode },

		-- app/session actions
		-- { key = "q", mods = "CTRL", action = act.QuitApplication },
	}

	local key_tables = {
		pane_mode = {
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "q", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },
			{ key = "p", mods = "LEADER", action = "PopKeyTable" },

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
			{
				key = "d",
				action = act.Multiple({
					act.PopKeyTable,
					act.SplitVertical({ domain = "CurrentPaneDomain" }),
				}),
			},
			{
				key = "r",
				action = act.Multiple({
					act.PopKeyTable,
					act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
				}),
			},
			{
				key = "n",
				action = act.Multiple({
					act.PopKeyTable,
					act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
				}),
			},
			{ key = "f", action = act.TogglePaneZoomState },
			{ key = "p", action = act.ActivatePaneDirection("Next") },

			-- close / break out
			{
				key = "x",
				action = act.Multiple({
					act.PopKeyTable,
					act.CloseCurrentPane({ confirm = false }),
				}),
			},
			{
				key = "b",
				action = wezterm.action_callback(move_pane_to_new_tab),
			},
		},

		tab_mode = {
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "q", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },
			{ key = "t", mods = "LEADER", action = "PopKeyTable" },

			-- nav
			{ key = "h", action = act.ActivateTabRelative(-1) },
			{ key = "l", action = act.ActivateTabRelative(1) },
			{ key = "p", action = act.ActivateTabRelative(-1) },
			{ key = "j", action = act.ActivateTabRelative(1) },
			{ key = "k", action = act.ActivateTabRelative(-1) },
			{ key = "Tab", action = act.ActivateLastTab },

			-- create/close/reorder
			{ key = "c", action = act.SpawnTab("CurrentPaneDomain") },
			{
				key = "n",
				action = act.Multiple({
					act.PopKeyTable,
					act.SpawnTab("CurrentPaneDomain"),
				}),
			},
			{
				key = "x",
				action = act.Multiple({
					act.PopKeyTable,
					act.CloseCurrentTab({ confirm = true }),
				}),
			},
			{ key = "H", action = act.MoveTabRelative(-1) },
			{ key = "L", action = act.MoveTabRelative(1) },
			{
				key = "b",
				action = wezterm.action_callback(move_pane_to_new_tab),
			},

			-- rename
			{
				key = "r",
				action = act.Multiple({
					act.PopKeyTable,
					act.PromptInputLine({
						description = "Rename tab",
						action = wezterm.action_callback(function(window, _, line)
							if line and line ~= "" then
								window:active_tab():set_title(line)
							end
						end),
					}),
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
			{ key = "n", mods = "LEADER", action = "PopKeyTable" },

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
			{ key = "o", mods = "LEADER", action = "PopKeyTable" },

			-- fuzzy find/switch workspaces ("sessions")
			{
				key = "f",
				action = act.Multiple({
					act.PopKeyTable,
					act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
				}),
			},
			{
				key = "w",
				action = act.Multiple({
					act.PopKeyTable,
					act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
				}),
			},
			{
				key = "l",
				action = act.Multiple({
					act.PopKeyTable,
					act.ShowLauncherArgs({ flags = "FUZZY|TABS|WORKSPACES" }),
				}),
			},
			{
				key = "c",
				action = act.Multiple({
					act.PopKeyTable,
					act.ActivateCommandPalette,
				}),
			},

			-- new workspace (prompt)
			{
				key = "n",
				action = act.Multiple({
					act.PopKeyTable,
					act.PromptInputLine({
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
				}),
			},

			-- switch workspace by name (prompt)
			{
				key = "s",
				action = act.Multiple({
					act.PopKeyTable,
					act.PromptInputLine({
						description = "Switch to workspace",
						action = wezterm.action_callback(function(window, pane, line)
							if not line or line == "" then
								return
							end
							window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
						end),
					}),
				}),
			},

			-- "rename" workspace (switch to a new name)
			{
				key = "r",
				action = act.Multiple({
					act.PopKeyTable,
					act.PromptInputLine({
						description = "Rename workspace (switch to new name)",
						action = wezterm.action_callback(function(window, pane, line)
							if not line or line == "" then
								return
							end
							window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
						end),
					}),
				}),
			},
		},
	}

	local leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1500 }
	return { leader = leader, keys = keys, key_tables = key_tables, disable_default_key_bindings = true }
end

return M
