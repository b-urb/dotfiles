local wezterm = require("wezterm")

local M = {}

local function is_darwin()
	local triple = wezterm.target_triple or ""
	return triple:find("darwin", 1, true) ~= nil
end

local function is_windows()
	local triple = wezterm.target_triple or ""
	return triple:find("windows", 1, true) ~= nil
end

local function parse_bool(value)
	if value == nil then
		return nil
	end
	local normalized = string.lower(tostring(value))
	if normalized == "1" or normalized == "true" or normalized == "yes" or normalized == "on" then
		return true
	end
	if normalized == "0" or normalized == "false" or normalized == "no" or normalized == "off" then
		return false
	end
	return nil
end

local function detect_bitwarden_ssh_sock()
	local disable_bw = parse_bool(os.getenv("DOTFILES_DISABLE_BITWARDEN_SSH_AGENT"))
	if disable_bw == true then
		return nil
	end

	-- Windows: Bitwarden Desktop exposes a named pipe for SSH agent.
	-- WezTerm treats \\.\pipe\... paths as SSH agent sockets on Windows.
	if is_windows() then
		return "\\\\.\\pipe\\openssh-ssh-agent"
	end

	if is_darwin() then
		return wezterm.home_dir .. "/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
	end

	local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or ""
	local sockets = {
		wezterm.home_dir .. "/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock",
		wezterm.home_dir .. "/Library/Group Containers/LTZ2PFU5D6.com.bitwarden.desktop/ssh-agent.sock",
		wezterm.home_dir .. "/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock",
		wezterm.home_dir .. "/snap/bitwarden/current/.bitwarden-ssh-agent.sock",
		wezterm.home_dir .. "/.bitwarden-ssh-agent.sock",
	}

	if runtime_dir ~= "" then
		table.insert(sockets, 1, runtime_dir .. "/bitwarden-ssh-agent.sock")
	end

	for _, sock in ipairs(sockets) do
		if #wezterm.glob(sock) == 1 then
			return sock
		end
	end

	return nil
end

-- Resolve the WSL distribution to use as the default domain.
-- Returns nil on non-Windows, which leaves WezTerm's default intact.
local function wsl_default_domain()
	if not is_windows() then
		return nil
	end
	-- "WSL:Ubuntu" matches whatever distro is set as default in wsl --list.
	-- Change this to "WSL:Arch" or another name if your default differs.
	return "WSL:Ubuntu"
end

function M.build()
	local config = {
		font_size = 15.0,
		font = wezterm.font("Monaspace Argon", { weight = "Bold", italic = false }),
		-- color_scheme = "One Dark (Gogh)",
		color_scheme_dirs = { wezterm.config_dir .. "/colors" },
		color_scheme = "github_dark_colorblind",
		enable_scroll_bar = true,
		window_close_confirmation = "NeverPrompt",
		window_decorations = "RESIZE",
		window_padding = {
			top = 2,
			bottom = 2,
		},
		inactive_pane_hsb = {
			hue = 1.0,
			saturation = 0.85,
			brightness = 0.35,
		},
		use_fancy_tab_bar = false,
		window_frame = {
			-- active_titlebar_bg = "#282c34",
			active_titlebar_bg = "#0d1117",
			-- inactive_titlebar_bg = "#282c34",
			inactive_titlebar_bg = "#0d1117",
			-- active_titlebar_border_bottom = "#61afef",
			active_titlebar_border_bottom = "#58a6ff",
			-- inactive_titlebar_border_bottom = "#232834",
			inactive_titlebar_border_bottom = "#21262d",
			font_size = 13.0,
		},
		hide_tab_bar_if_only_one_tab = false,
		tab_bar_at_bottom = true,
		show_tabs_in_tab_bar = true,
		show_new_tab_button_in_tab_bar = false,
		show_close_tab_button_in_tabs = false,
		tab_bar_style = {},
		colors = {
			-- split = "#61afef",
			split = "#58a6ff",
			tab_bar = {
				-- background = "#282c34",
				background = "#0d1117",
				-- new_tab = { bg_color = "#282c34", fg_color = "#5c6370" },
				new_tab = { bg_color = "#0d1117", fg_color = "#8b949e" },
				-- new_tab_hover = { bg_color = "#282c34", fg_color = "#61afef" },
				new_tab_hover = { bg_color = "#0d1117", fg_color = "#58a6ff" },
				-- active_tab = { bg_color = "#282c34", fg_color = "#abb2bf" },
				active_tab = { bg_color = "#0d1117", fg_color = "#c9d1d9" },
				-- inactive_tab = { bg_color = "#282c34", fg_color = "#5c6370" },
				inactive_tab = { bg_color = "#0d1117", fg_color = "#8b949e" },
				-- inactive_tab_edge = "#282c34",
				inactive_tab_edge = "#0d1117",
				-- inactive_tab_hover = { bg_color = "#282c34", fg_color = "#abb2bf" },
				inactive_tab_hover = { bg_color = "#0d1117", fg_color = "#c9d1d9" },
			},
		},
		audible_bell = "Disabled",
		visual_bell = {
			fade_in_duration_ms = 75,
			fade_out_duration_ms = 75,
			target = "CursorColor",
		},
		status_update_interval = 500,
	}

	-- Windows: open WSL by default instead of cmd/PowerShell.
	local wsl_domain = wsl_default_domain()
	if wsl_domain ~= nil then
		config.wsl_domains = wezterm.default_wsl_domains()
		config.default_domain = wsl_domain
	end

	local bw_sock = detect_bitwarden_ssh_sock()
	if bw_sock ~= nil then
		config.default_ssh_auth_sock = bw_sock
		config.set_environment_variables = {
			SSH_AUTH_SOCK = bw_sock,
		}
	end

	return config
end

return M
