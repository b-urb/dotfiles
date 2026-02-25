local native = require("keybinds.native")

local M = {}
-- Toggle to disable dotfiles keybindings and keep WezTerm defaults.
local use_zellij = false

function M.build()
	if use_zellij then
		return {
			leader = nil,
			keys = {},
			key_tables = {},
			disable_default_key_bindings = false,
		}
	end
	return native.build()
end

return M
