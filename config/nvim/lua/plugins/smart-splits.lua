return {
  {
    "mrjones2014/smart-splits.nvim",
    version = "*",
    opts = {
      multiplexer_integration = "zellij",
      zellij_move_focus_or_tab = false,
    },
    keys = {
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Move to left split" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Move to below split" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Move to upper split" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move to right split" },
      { "<C-S-h>", function() require("smart-splits").resize_left() end, desc = "Resize split left" },
      { "<C-S-j>", function() require("smart-splits").resize_down() end, desc = "Resize split down" },
      { "<C-S-k>", function() require("smart-splits").resize_up() end, desc = "Resize split up" },
      { "<C-S-l>", function() require("smart-splits").resize_right() end, desc = "Resize split right" },
    },
  },
}
