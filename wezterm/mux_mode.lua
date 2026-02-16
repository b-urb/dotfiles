local wezterm = require("wezterm")
local io = require("io")
local os = require("os")

local M = {}

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

function M.detect()
	local has_zellij = M.has_zellij()
	return {
		has_zellij = has_zellij,
		use_zellij_keybinds = has_zellij,
	}
end

return M
