local base = require("config.base")
local keybinds = require("keybinds")
local status = require("status")
local workspace = require("workspace")

local config = base.build()
local key_config = keybinds.build()

status.register()

config.leader = key_config.leader
config.keys = key_config.keys
config.key_tables = key_config.key_tables
config.disable_default_key_bindings = key_config.disable_default_key_bindings
if key_config.enable_tab_bar ~= nil then
	config.enable_tab_bar = key_config.enable_tab_bar
end

workspace.apply_to_config(config)

return config
