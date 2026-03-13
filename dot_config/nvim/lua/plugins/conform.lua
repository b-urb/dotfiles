return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters_by_ft = opts.formatters_by_ft or {}

      opts.formatters.tofu_fmt = {
        command = "tofu",
        args = { "fmt", "-" },
        stdin = true,
      }

      opts.formatters_by_ft.terraform = { "tofu_fmt" }
      opts.formatters_by_ft.hcl = { "tofu_fmt" }
      return opts
    end,
  },
}
