local M = {}

function M.build()
	return {
		leader = nil,
		keys = {},
		key_tables = {},
		disable_default_key_bindings = true,
		enable_tab_bar = false,
	}
end

return M
