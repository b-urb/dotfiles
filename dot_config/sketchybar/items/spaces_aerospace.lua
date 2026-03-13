local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local AEROSPACE_BIN = "/opt/homebrew/bin/aerospace"

local WORKSPACES_CMD = AEROSPACE_BIN
  .. " list-workspaces --all --format '%{workspace}|%{monitor-appkit-nsscreen-screens-id}|%{monitor-id}|%{workspace-is-focused}'"
local MONITORS_CMD = AEROSPACE_BIN
  .. " list-monitors --format '%{monitor-appkit-nsscreen-screens-id}|%{monitor-is-main}'"

local function workspace_windows_cmd(workspace_id)
  return AEROSPACE_BIN
    .. " list-windows --workspace "
    .. workspace_id
    .. " --format '%{app-name}' --json"
end

local function trim(str)
  return (str or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function icon_for_app(app)
  return app_icons[app] or app_icons.default
end

local function read_accessible_workspaces()
  local ids = {}
  local seen = {}
  local path = (os.getenv("HOME") or "") .. "/.config/skhd/skhdrc.aerospace"
  local file = io.open(path, "r")

  if file then
    for line in file:lines() do
      local stripped = trim(line)
      if stripped ~= "" and not stripped:match("^#") then
        local workspace = stripped:match("aerospace%s+workspace%s+([%w]+)")
        if not workspace then
          workspace = stripped:match("aerospace%s+move%-node%-to%-workspace%s+([%w]+)")
        end

        if workspace then
          workspace = workspace:upper()
          if not seen[workspace] then
            seen[workspace] = true
            table.insert(ids, workspace)
          end
        end
      end
    end
    file:close()
  end

  if #ids == 0 then
    ids = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "X", "Z" }
  end

  return ids
end

local function parse_workspace_state(raw)
  local state = {}

  for line in (raw or ""):gmatch("[^\r\n]+") do
    local workspace, appkit_screen_id, monitor_id, focused = line:match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)$")
    workspace = workspace and workspace:upper() or nil
    if workspace then
      local display = tonumber(appkit_screen_id) or tonumber(monitor_id)
      state[workspace] = {
        display = display,
        focused = focused == "true",
      }
    end
  end

  return state
end

local function read_workspace_state()
  local handle = io.popen(WORKSPACES_CMD)
  if not handle then
    return {}
  end

  local raw = handle:read("*a") or ""
  handle:close()
  return parse_workspace_state(raw)
end

local function detect_secondary_display_id()
  local handle = io.popen(MONITORS_CMD)
  if not handle then
    return nil
  end

  local raw = handle:read("*a") or ""
  handle:close()

  for line in raw:gmatch("[^\r\n]+") do
    local appkit_screen_id, is_main = line:match("^([^|]+)|([^|]+)$")
    local display = tonumber(appkit_screen_id)
    if display and is_main == "false" then
      return display
    end
  end

  return nil
end

local function set_workspace_display(item_name, display)
  local target = display and tostring(display) or "all"
  sbar.exec("sketchybar --set " .. item_name .. " display=" .. target)
end

local workspace_ids = read_accessible_workspaces()
local workspaces = {}

sbar.add("item", {
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
  padding_left = 8,
  padding_right = 0,
})

sbar.remove("/aerospace\\.space\\.focused_app\\..*/")

for _, workspace_id in ipairs(workspace_ids) do
  local workspace = sbar.add("item", "aerospace.space." .. workspace_id, {
    icon = {
      font = {
        family = settings.font.numbers,
        style = settings.font.style_map["Bold"],
        size = 15.0,
      },
      string = workspace_id,
      color = colors.grey,
      highlight_color = colors.spaces.highlight,
      padding_left = 18,
      padding_right = 10,
    },
    label = {
      color = colors.grey,
      highlight_color = colors.spaces.highlight,
      padding_right = 12,
      font = "sketchybar-app-font:Regular:18.0",
      y_offset = -1,
      drawing = false,
      highlight = false,
    },
    padding_right = 3,
    padding_left = 6,
    background = {
      drawing = true,
      color = colors.with_alpha(colors.bg1, 0.35),
      border_color = colors.spaces.highlight,
      border_width = 0,
      corner_radius = 10,
      height = 30,
    },
  })

  workspace:subscribe("mouse.clicked", function()
    sbar.exec(AEROSPACE_BIN .. " workspace " .. workspace_id)
  end)

  workspaces[workspace_id] = workspace
end

local function refresh_workspaces()
  local workspace_state = read_workspace_state()
  local secondary_display_id = detect_secondary_display_id()

  for _, workspace_id in ipairs(workspace_ids) do
    local workspace = workspaces[workspace_id]
    local state = workspace_state[workspace_id] or {}

    sbar.exec(workspace_windows_cmd(workspace_id), function(rows)
      local apps = {}
      local seen_apps = {}

      if type(rows) == "table" then
        for _, row in ipairs(rows) do
          local app_name = row["app-name"]
          if app_name and not seen_apps[app_name] then
            seen_apps[app_name] = true
            table.insert(apps, app_name)
          end
        end
      end

      local app_line = ""
      for _, app_name in ipairs(apps) do
        app_line = app_line .. " " .. icon_for_app(app_name)
      end

      local has_windows = #apps > 0
      local is_focused = state.focused == true
      local display = state.display

      if not display and workspace_id:match("^[A-Z]$") then
        display = secondary_display_id
      end

      set_workspace_display(workspace.name, display)

      workspace:set({
        drawing = true,
        icon = { highlight = is_focused },
        label = {
          drawing = has_windows,
          string = app_line,
          color = colors.grey,
          highlight = is_focused,
        },
        background = {
          border_width = is_focused and 2 or 0,
          border_color = colors.spaces.highlight,
        },
      })
    end)
  end
end

local observer = sbar.add("item", {
  drawing = false,
  updates = true,
})

observer:subscribe({
  "routine",
  "system_woke",
  "aerospace_workspace_change",
  "aerospace_focus_change",
}, refresh_workspaces)

refresh_workspaces()
