local native = require("keybinds.native")
local zellij = require("keybinds.zellij")

local M = {}

function M.build(use_zellij_keybinds)
	if use_zellij_keybinds then
		return zellij.build()
	end
	return native.build()
end

return M
