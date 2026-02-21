local wezterm = require("wezterm")

local M = {}

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

function M.build()
	local config = {
		font_size = 15.0,
		font = wezterm.font("Monaspace Argon", { weight = "Bold", italic = false }),
		color_scheme = "One Dark (Gogh)",
		enable_scroll_bar = true,
		window_background_opacity = 0.94,
		window_close_confirmation = "NeverPrompt",
		window_decorations = "RESIZE",
		window_padding = {
			top = 2,
		},
		inactive_pane_hsb = {
			hue = 1.0,
			saturation = 0.85,
			brightness = 0.35,
		},
		use_fancy_tab_bar = true,
		window_frame = {
			active_titlebar_bg = "#000000",
			inactive_titlebar_bg = "#000000",
			active_titlebar_border_bottom = "#61afef",
			inactive_titlebar_border_bottom = "#1f2329",
			font_size = 19.0,
		},
		hide_tab_bar_if_only_one_tab = false,
		show_new_tab_button_in_tab_bar = false,
		show_close_tab_button_in_tabs = false,
		tab_bar_style = {},
		colors = {
			split = "#61afef",
			tab_bar = {
				background = "#000000",
				new_tab = { bg_color = "#000000", fg_color = "#FCE8C3", intensity = "Bold" },
				new_tab_hover = { bg_color = "#000000", fg_color = "#FCE8C3", intensity = "Bold" },
				active_tab = { bg_color = "#000000", fg_color = "#FCE8C3" },
				inactive_tab = { bg_color = "#000000", fg_color = "#FCE8C3" },
				inactive_tab_edge = "#000000",
				inactive_tab_hover = { bg_color = "#000000", fg_color = "#FCE8C3" },
			},
		},
		audible_bell = "Disabled",
		visual_bell = {
			fade_in_duration_ms = 75,
			fade_out_duration_ms = 75,
			target = "CursorColor",
		},
	}

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
