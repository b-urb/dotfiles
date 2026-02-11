return {
  "folke/sidekick.nvim",
  opts = function(_, opts)
    opts.cli = opts.cli or {}
    opts.cli.mux = vim.tbl_deep_extend("force", opts.cli.mux or {}, {
      enabled = true,
      backend = "zellij", -- or "tmux"
    })
  end,
}
