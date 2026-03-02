local explorer_conflicting_keys = {
  "<BS>",
  "<C-h>",
  "<C-j>",
  "<C-k>",
  "<C-l>",
  "<c-h>",
  "<c-j>",
  "<c-k>",
  "<c-l>",
}

local function disable_explorer_keys(keys)
  for _, key in ipairs(explorer_conflicting_keys) do
    keys[key] = false
  end
end

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.ui_select = true
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.explorer = opts.picker.sources.explorer or {}

      local explorer = opts.picker.sources.explorer
      explorer.win = explorer.win or {}

      explorer.win.list = explorer.win.list or {}
      explorer.win.list.keys = explorer.win.list.keys or {}
      disable_explorer_keys(explorer.win.list.keys)

      explorer.win.input = explorer.win.input or {}
      explorer.win.input.keys = explorer.win.input.keys or {}
      disable_explorer_keys(explorer.win.input.keys)
    end,
  },
}
