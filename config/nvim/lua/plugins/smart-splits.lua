local function parse_bool(value)
  if value == nil then
    return false
  end
  local normalized = string.lower(tostring(value))
  return normalized == "1" or normalized == "true" or normalized == "yes" or normalized == "on"
end

local function resolve_multiplexer_integration()
  local mode = string.lower(vim.env.DOTFILES_ZELLIJ_MODE or "")
  if mode == "full" then
    return "zellij"
  end
  if mode == "native" or mode == "bridge" then
    return "wezterm"
  end

  if parse_bool(vim.env.DOTFILES_ENABLE_ZELLIJ) then
    return "zellij"
  end
  return "wezterm"
end

return {
  {
    "mrjones2014/smart-splits.nvim",
    version = "*",
    lazy = false,
    opts = function()
      return {
        multiplexer_integration = resolve_multiplexer_integration(),
        zellij_move_focus_or_tab = false,
        float_win_behavior = "previous",
      }
    end,
    keys = {
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Move to left split" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Move to below split" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Move to upper split" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move to right split" },
      { "<A-h>", function() require("smart-splits").resize_left() end, desc = "Resize split left" },
      { "<A-j>", function() require("smart-splits").resize_down() end, desc = "Resize split down" },
      { "<A-k>", function() require("smart-splits").resize_up() end, desc = "Resize split up" },
      { "<A-l>", function() require("smart-splits").resize_right() end, desc = "Resize split right" },
      { "<C-\\>", function() require("smart-splits").move_cursor_previous() end, desc = "Move to previous split" },
    },
  },
}
