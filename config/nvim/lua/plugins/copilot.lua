return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      panel = {
        enabled = false,
      },
      suggestion = {
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 75,
        keymap = {
          accept = "<C-;>",
          accept_word = false,
          accept_line = false,
          next = false,
          prev = false,
          dismiss = false,
          toggle_auto_trigger = false,
        },
      },
      filetypes = {
        sh = function()
          local basename = vim.fs.basename(vim.api.nvim_buf_get_name(0))
          return not basename:match("^%.env")
        end,
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        copilot = { enabled = false },
      },
    },
  },
  {
    "zbirenbaum/copilot.lua",
    opts = function()
      LazyVim.cmp.actions.ai_accept = function()
        if require("copilot.suggestion").is_visible() then
          LazyVim.create_undo()
          require("copilot.suggestion").accept()
          return true
        end
      end
    end,
  },
}
