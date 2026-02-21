local function is_snacks_explorer_window()
  if vim.bo.filetype ~= "snacks_picker_list" then
    return false
  end

  local win_config = vim.api.nvim_win_get_config(0)
  return win_config.relative ~= "" and win_config.zindex == 33
end

local function move_with_snacks_workaround(wincmd_key, smart_splits_fn)
  return function()
    if is_snacks_explorer_window() then
      vim.cmd("wincmd " .. wincmd_key)
      return
    end

    require("smart-splits")[smart_splits_fn]()
  end
end

return {
  {
    "mrjones2014/smart-splits.nvim",
    version = "*",
    lazy = false,
    opts = function()
      local toggle = (vim.env.DOTFILES_ENABLE_ZELLIJ or ""):lower()
      local use_zellij = toggle == "1" or toggle == "true" or toggle == "yes" or toggle == "on"
      return {
        multiplexer_integration = use_zellij and "zellij" or "wezterm",
        zellij_move_focus_or_tab = false,
        float_win_behavior = "previous",
      }
    end,
    keys = {
      { "<C-h>", move_with_snacks_workaround("h", "move_cursor_left"), desc = "Move to left split" },
      { "<C-j>", move_with_snacks_workaround("j", "move_cursor_down"), desc = "Move to below split" },
      { "<C-k>", move_with_snacks_workaround("k", "move_cursor_up"), desc = "Move to upper split" },
      { "<C-l>", move_with_snacks_workaround("l", "move_cursor_right"), desc = "Move to right split" },
      { "<A-h>", function() require("smart-splits").resize_left() end, desc = "Resize split left" },
      { "<A-j>", function() require("smart-splits").resize_down() end, desc = "Resize split down" },
      { "<A-k>", function() require("smart-splits").resize_up() end, desc = "Resize split up" },
      { "<A-l>", function() require("smart-splits").resize_right() end, desc = "Resize split right" },
      { "<C-\\>", function() require("smart-splits").move_cursor_previous() end, desc = "Move to previous split" },
    },
  },
}
