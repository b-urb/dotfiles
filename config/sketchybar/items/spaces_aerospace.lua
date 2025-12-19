local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local max_workspaces = 9

-- Add padding to the left
sbar.add("item", {
	icon = { drawing = false },
	label = { drawing = false },
	background = { drawing = false },
	padding_left = 6,
	padding_right = 0,
})

local workspaces = {}

local function updateWindows(workspace_index)
	local get_windows =
		string.format("aerospace list-windows --workspace %s --format '%%{app-name}' --json", workspace_index)
	sbar.exec(get_windows, function(open_windows)
		local icon_line = ""
		local no_app = true
		for i, open_window in ipairs(open_windows) do
			no_app = false
			local app = open_window["app-name"]
			local lookup = app_icons[app]
			local icon = ((lookup == nil) and app_icons["default"] or lookup)
			icon_line = icon_line .. " " .. icon
		end
		sbar.animate("tanh", 10, function()
			if no_app then
				workspaces[workspace_index]:set({
					icon = { drawing = false },
					label = { drawing = false },
					background = { drawing = false },
					padding_right = 0,
					padding_left = 0,
				})
				return
			end

			workspaces[workspace_index]:set({
				icon = { drawing = true },
				label = { drawing = true, string = icon_line },
				background = { drawing = true },
				padding_right = 1,
				padding_left = 4,
			})
		end)
	end)
end

for workspace_index = 1, max_workspaces do
	local workspace = sbar.add("item", {
		icon = {
			font = { family = settings.font.numbers },
			string = workspace_index,
			color = colors.grey,
			highlight_color = colors.spaces.highlight,
			padding_left = 15,
			padding_right = 8,
		},
		label = {
			padding_right = 20,
			color = colors.grey,
			highlight_color = colors.spaces.highlight,
			font = "sketchybar-app-font:Regular:18.0",
			y_offset = -1,
		},
		padding_right = 1,
		padding_left = 4,
		background = {
			border_color = colors.spaces.highlight,
		},
	})

	workspaces[workspace_index] = workspace

	workspace:subscribe("aerospace_workspace_change", function(env)
		local focused_workspace = tonumber(env.FOCUSED_WORKSPACE)
		local is_focused = focused_workspace == workspace_index

		sbar.animate("tanh", 10, function()
			workspace:set({
				icon = { highlight = is_focused },
				label = { highlight = is_focused },
				background = {
					border_width = is_focused and 2 or 0,
				},
			})
		end)
	end)

	workspace:subscribe("aerospace_focus_change", function()
		updateWindows(workspace_index)
	end)

	--   space:subscribe("mouse.clicked", function(env)
	--     if env.BUTTON == "other" then
	--       space_popup:set({ background = { image = "space." .. env.SID } })
	--       space:set({ popup = { drawing = "toggle" } })
	--     else
	--       local op = "--focus"
	--       sbar.exec("yabai -m space " .. op .. " " .. env.SID)
	--     end
	--   end)
	--
	--   space:subscribe("mouse.exited", function(_)
	--     space:set({ popup = { drawing = false } })
	--   end)
	-- end

	-- initial setup
	updateWindows(workspace_index)
	sbar.exec("aerospace list-workspaces --focused", function(focused_workspace)
		workspaces[tonumber(focused_workspace)]:set({
			icon = { highlight = true },
			label = { highlight = true },
			background = { border_width = 2 },
			color = colors.orange,
		})
	end)
end
