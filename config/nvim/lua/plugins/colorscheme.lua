return {
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000, -- Load before other plugins
    config = function()
      require("onedarkpro").setup({
        -- options = {
        --   transparency = false,
        --   terminal_colors = true,
        -- },
        -- highlights = {
        --   DiagnosticUnderlineError = {
        --     underline = true,
        --     bold = true,
        --     standout = true,
        --     sp = "#ff5555", -- Bright red underline
        --   },
        -- },
      })
      vim.cmd("colorscheme onedark")
    end,
  },
}
