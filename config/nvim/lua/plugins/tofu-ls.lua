return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tofu_ls = {
          -- make sure it attaches to your terraform/hcl buffers too
          filetypes = { "terraform", "terraform-vars", "hcl", "opentofu", "opentofu-vars" },
        },
      },
    },
  },
}
