local wezterm = require("wezterm")

local M = {}

local SESSION_PREFIX = "wt-bridge-"
local GC_INTERVAL_SECONDS = 30
local last_gc_at = 0

local function trim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function should_collect(mode)
	if mode == nil then
		return false
	end
	if mode.zellij_mode ~= "bridge" then
		return false
	end
	if not mode.has_zellij then
		return false
	end
	local now = os.time()
	if now - last_gc_at < GC_INTERVAL_SECONDS then
		return false
	end
	last_gc_at = now
	return true
end

local function active_bridge_sessions()
	local active = {}
	for _, mux_window in ipairs(wezterm.mux.all_windows()) do
		for _, mux_tab in ipairs(mux_window:tabs()) do
			for _, mux_pane in ipairs(mux_tab:panes()) do
				active[SESSION_PREFIX .. tostring(mux_pane:pane_id())] = true
			end
		end
	end
	return active
end

local function collect_sessions_to_kill(active)
	local ok, stdout = wezterm.run_child_process({
		"zellij",
		"list-sessions",
		"--short",
		"--no-formatting",
	})
	if not ok then
		return {}
	end

	local stale = {}
	for line in stdout:gmatch("[^\r\n]+") do
		local session = trim(line)
		if session:sub(1, #SESSION_PREFIX) == SESSION_PREFIX and not active[session] then
			table.insert(stale, session)
		end
	end

	return stale
end

function M.collect(mode)
	if not should_collect(mode) then
		return
	end

	local active = active_bridge_sessions()
	local stale = collect_sessions_to_kill(active)
	for _, session in ipairs(stale) do
		wezterm.run_child_process({ "zellij", "kill-session", session })
	end
end

return M
