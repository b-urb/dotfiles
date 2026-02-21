local base = require("config.base")
local events = require("events")
local keybinds = require("keybinds")
local mux_mode = require("mux_mode")
local status = require("status")
local workspace = require("workspace")

local function trim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function strip_quotes(value)
	local v = trim(value)
	local first = v:sub(1, 1)
	local last = v:sub(-1)
	if (first == '"' and last == '"') or (first == "'" and last == "'") then
		return v:sub(2, -2)
	end
	return v
end

local function parse_bool(value)
	if value == nil then
		return nil
	end
	local normalized = string.lower(trim(tostring(value)))
	if normalized == "1" or normalized == "true" or normalized == "yes" or normalized == "on" then
		return true
	end
	if normalized == "0" or normalized == "false" or normalized == "no" or normalized == "off" then
		return false
	end
	return nil
end

local function read_bool_option_from_file(path, key_name)
	local file = io.open(path, "r")
	if file == nil then
		return nil
	end

	for line in file:lines() do
		local sanitized = line:gsub("#.*$", "")
		local key, raw = sanitized:match("^%s*export%s+([%a_][%w_]*)%s*=%s*(.-)%s*$")
		if key == nil then
			key, raw = sanitized:match("^%s*([%a_][%w_]*)%s*=%s*(.-)%s*$")
		end
		if key == key_name and raw ~= nil and raw ~= "" then
			local parsed = parse_bool(strip_quotes(raw))
			if parsed ~= nil then
				file:close()
				return parsed
			end
		end
	end

	file:close()
	return nil
end

local function is_wezterm_events_disabled()
	local home = os.getenv("HOME") or ""
	if home ~= "" then
		local paths = {
			home .. "/.dotfiles/options/dotfiles.options.local.sh",
			home .. "/.dotfiles/options/dotfiles.options.sh",
		}
		for _, path in ipairs(paths) do
			local value = read_bool_option_from_file(path, "DOTFILES_WEZTERM_DISABLE_EVENTS")
			if value ~= nil then
				return value
			end
		end
	end

	local env_value = parse_bool(os.getenv("DOTFILES_WEZTERM_DISABLE_EVENTS"))
	if env_value ~= nil then
		return env_value
	end

	return false
end

local config = base.build()
local mode = mux_mode.detect()
local key_config = keybinds.build(mode.use_zellij_keybinds)

if not is_wezterm_events_disabled() then
	events.register()
end
status.register(mode)

config.leader = key_config.leader
config.keys = key_config.keys
config.key_tables = key_config.key_tables
config.disable_default_key_bindings = key_config.disable_default_key_bindings
if key_config.enable_tab_bar ~= nil then
	config.enable_tab_bar = key_config.enable_tab_bar
end

workspace.apply_to_config(config, mode)

return config
