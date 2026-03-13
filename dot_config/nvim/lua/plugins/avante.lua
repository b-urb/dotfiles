return {
  {
    "yetone/avante.nvim",
    build = vim.fn.has("win32") ~= 0
        and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make",
    event = "VeryLazy",
    version = false,
    opts = {
      instructions_file = "avante.md",
      provider = "copilot",
      behaviour = {
        auto_approve_tool_permissions = false,
        auto_apply_diff_after_generation = false,
        confirmation_ui_style = "popup",
      },
      providers = {
        copilot = {
          model = "gpt-5.1-codex-mini",
          use_response_api = function(provider_opts)
            local model = provider_opts and provider_opts.model
            return type(model) == "string" and model:match("gpt%-5[%w%.%-]*%-codex") ~= nil
          end,
        },
      },
      selector = {
        provider = "snacks",
      },
      input = {
        provider = "snacks",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-mini/mini.pick",
      "nvim-telescope/telescope.nvim",
      "hrsh7th/nvim-cmp",
      "ibhagwan/fzf-lua",
      "stevearc/dressing.nvim",
      "folke/snacks.nvim",
      "nvim-tree/nvim-web-devicons",
      "zbirenbaum/copilot.lua",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            use_absolute_path = true,
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown", "Avante" },
        opts = {
          file_types = { "markdown", "Avante" },
        },
      },
    },
  },
}
