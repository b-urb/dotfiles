local function gitlab_menu()
  local actions = {
    {
      label = "Choose Merge Request",
      run = function()
        require("gitlab").choose_merge_request()
      end,
    },
    {
      label = "Review Current Branch",
      run = function()
        require("gitlab").review()
      end,
    },
    {
      label = "Merge Request Summary",
      run = function()
        require("gitlab").summary()
      end,
    },
    {
      label = "Create Merge Request",
      run = function()
        require("gitlab").create_mr()
      end,
    },
    {
      label = "Pipeline",
      run = function()
        require("gitlab").pipeline()
      end,
    },
    {
      label = "Open Merge Request in Browser",
      run = function()
        require("gitlab").open_in_browser()
      end,
    },
  }

  vim.ui.select(vim.tbl_map(function(item)
    return item.label
  end, actions), { prompt = "GitLab" }, function(choice)
    if choice == nil then
      return
    end

    for _, item in ipairs(actions) do
      if item.label == choice then
        item.run()
        return
      end
    end
  end)
end

return {
  {
    "harrisoncramer/gitlab.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    build = function()
      require("gitlab.server").build(true)
    end,
    opts = {
      keymaps = {
        disable_all = true,
      },
    },
    config = function(_, opts)
      pcall(require, "diffview")
      require("gitlab").setup(opts)
    end,
    keys = {
      { "<leader>gO", gitlab_menu, desc = "GitLab" },
    },
  },
}
