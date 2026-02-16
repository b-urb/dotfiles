local base = require("config.base")
local events = require("events")
local keybinds = require("keybinds")
local mux_mode = require("mux_mode")
local workspace = require("workspace")

events.register()

local config = base.build()
local mode = mux_mode.detect()
local key_config = keybinds.build(mode.use_zellij_keybinds)

config.leader = key_config.leader
config.keys = key_config.keys
config.key_tables = key_config.key_tables
config.disable_default_key_bindings = key_config.disable_default_key_bindings
if key_config.enable_tab_bar ~= nil then
	config.enable_tab_bar = key_config.enable_tab_bar
end

workspace.apply_to_config(config, mode)

return config
