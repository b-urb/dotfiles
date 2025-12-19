local wezterm = require("wezterm")
local utils = require("utils")
local act = wezterm.action
local module = {}
local session_manager = require("wezterm-session-manager/session-manager")

function module.apply_to_config(config)
	--   wezterm.on('update-right-status', function(window, pane)
	--     window:set_right_status(window:active_workspace())
	--   end)
	--
	-- wezterm.on("save_session", function(window) session_manager.save_state(window) end)
	-- wezterm.on("load_session", function(window) session_manager.load_state(window) end)
	-- wezterm.on("restore_session", function(window) session_manager.restore_state(window) end)
	keys = {
		-- Switch to the default workspace
		{
			key = "y",
			mods = "CTRL|SHIFT",
			action = act.SwitchToWorkspace({
				name = "default",
			}),
		},
		-- Switch to a monitoring workspace, which will have `top` launched into it
		{
			key = "u",
			mods = "CTRL|SHIFT",
			action = act.SwitchToWorkspace({
				name = "monitoring",
				spawn = {
					args = { "top" },
				},
			}),
		},
		-- Create a new workspace with a random name and switch to it
		{ key = "i", mods = "CTRL|SHIFT", action = act.SwitchToWorkspace },
		-- Show the launcher in fuzzy selection mode and have it list all workspaces
		-- and allow activating one.
		{
			key = "s",
			mods = "LEADER",
			action = act.ShowLauncherArgs({
				flags = "FUZZY|WORKSPACES",
			}),
		},
		-- {key = "S", mods = "LEADER", action = wezterm.action{EmitEvent = "save_session"}},
		-- {key = "L", mods = "LEADER", action = wezterm.action{EmitEvent = "load_session"}},
		-- {key = "R", mods = "LEADER", action = wezterm.action{EmitEvent = "restore_session"}},
		{
			key = "w",
			mods = "LEADER",
			action = act.PromptInputLine({
				description = wezterm.format({
					{ Attribute = { Intensity = "Bold" } },
					{ Foreground = { AnsiColor = "Fuchsia" } },
					{ Text = "Enter name for new workspace" },
				}),
				action = wezterm.action_callback(function(window, pane, line)
					-- line will be `nil` if they hit escape without entering anything
					-- An empty string if they just hit enter
					-- Or the actual line of text they wrote
					if line then
						window:perform_action(
							act.SwitchToWorkspace({
								name = line,
							}),
							pane
						)
					end
				end),
			}),
		},
	}
	config.keys = utils.merge_lists(config.keys, keys)
	return config
end

-- return our module table
return module
