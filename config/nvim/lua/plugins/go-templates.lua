return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          filetypes = { "go", "gomod", "gowork", "gotmpl", "gohtmltmpl" },
          settings = {
            gopls = {
              templateExtensions = { "tmpl", "gotmpl", "gohtml", "tpl" },
            },
          },
        },
        html = {
          filetypes = { "html", "gotmpl", "gohtmltmpl" },
        },
        angularls = {
          single_file_support = false,
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "gotmpl") then
        table.insert(opts.ensure_installed, "gotmpl")
      end
    end,
  },
}
