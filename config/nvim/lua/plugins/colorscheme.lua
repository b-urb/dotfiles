return {
  {
    -- "olimorris/onedarkpro.nvim",
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    priority = 1000, -- Load before other plugins
    config = function()
      -- require("onedarkpro").setup({
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
      -- })
      require("github-theme").setup({
        options = {
          transparent = false,
          terminal_colors = true,
        },
      })
      -- vim.cmd("colorscheme onedark")
      vim.cmd("colorscheme github_dark_colorblind")
    end,
  },
}
