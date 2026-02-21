local wezterm = require("wezterm")
local io = require("io")
local os = require("os")

local M = {}

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

local function file_exists(path)
	local f = io.open(path, "r")
	if f ~= nil then
		f:close()
		return true
	end
	return false
end

function M.has_zellij()
	local home = os.getenv("HOME") or ""
	local known_locations = {
		home ~= "" and (home .. "/.cargo/bin/zellij") or nil,
		"/opt/homebrew/bin/zellij",
		"/usr/local/bin/zellij",
	}

	for _, bin in ipairs(known_locations) do
		if bin ~= nil and file_exists(bin) then
			return true
		end
	end

	local ok = os.execute("command -v zellij >/dev/null 2>&1")
	if type(ok) == "boolean" then
		return ok
	end
	if type(ok) == "number" then
		return ok == 0
	end
	return false
end

local function read_option_from_file(path, key_name)
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
			local parsed = strip_quotes(raw)
			if parsed ~= nil and parsed ~= "" then
				file:close()
				return parsed
			end
		end
	end

	file:close()
	return nil
end

local function read_option_value(key_name)
	local home = os.getenv("HOME") or ""
	if home ~= "" then
		local paths = {
			home .. "/.dotfiles/options/dotfiles.options.local.sh",
			home .. "/.dotfiles/options/dotfiles.options.sh",
		}
		for _, path in ipairs(paths) do
			local file_value = read_option_from_file(path, key_name)
			if file_value ~= nil and file_value ~= "" then
				return file_value
			end
		end
	end
	return os.getenv(key_name)
end

local function resolve_zellij_mode()
	local mode_value = read_option_value("DOTFILES_ZELLIJ_MODE")
	if mode_value ~= nil and mode_value ~= "" then
		local normalized = string.lower(trim(tostring(mode_value)))
		if normalized == "native" or normalized == "full" or normalized == "bridge" then
			return normalized
		end
	end

	local legacy_toggle = parse_bool(read_option_value("DOTFILES_ENABLE_ZELLIJ"))
	if legacy_toggle == true then
		return "full"
	end
	return "native"
end

local function is_zellij_enabled(mode)
	return mode ~= "native"
end

function M.detect()
	local zellij_mode = resolve_zellij_mode()
	local enable_zellij = is_zellij_enabled(zellij_mode)
	local has_zellij = M.has_zellij()
	local full_mode = zellij_mode == "full"
	local bridge_mode = zellij_mode == "bridge"
	return {
		zellij_mode = zellij_mode,
		enable_zellij = enable_zellij,
		has_zellij = has_zellij,
		bridge_mode = bridge_mode and has_zellij,
		use_zellij_keybinds = full_mode and has_zellij,
	}
end

return M
