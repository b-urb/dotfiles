local function run_wezterm_cli(args)
  local command = { "wezterm", "cli" }
  vim.list_extend(command, args)

  if vim.system ~= nil then
    local result = vim.system(command, { text = true }):wait()
    return result.code == 0
  end

  vim.fn.system(command)
  return vim.v.shell_error == 0
end

local function activate_tab_relative(delta)
  local args = { "activate-tab", "--tab-relative", tostring(delta) }
  local pane_id = vim.env.WEZTERM_PANE
  if pane_id ~= nil and pane_id ~= "" then
    table.insert(args, "--pane-id")
    table.insert(args, pane_id)
  end
  return run_wezterm_cli(args)
end

local function at_edge(ctx)
  if ctx.direction == "left" and activate_tab_relative(-1) then
    return
  end

  if ctx.direction == "right" and activate_tab_relative(1) then
    return
  end

  ctx.wrap()
end

return {
  {
    "mrjones2014/smart-splits.nvim",
    branch = "master",
    lazy = false,
    opts = {
      multiplexer_integration = "wezterm",
      at_edge = at_edge,
      float_win_behavior = "previous",
    },
    keys = {
      {
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
        end,
        desc = "Move to left split",
      },
      {
        "<C-j>",
        function()
          require("smart-splits").move_cursor_down()
        end,
        desc = "Move to below split",
      },
      {
        "<C-k>",
        function()
          require("smart-splits").move_cursor_up()
        end,
        desc = "Move to upper split",
      },
      {
        "<C-l>",
        function()
          require("smart-splits").move_cursor_right()
        end,
        desc = "Move to right split",
      },
      {
        "<A-h>",
        function()
          require("smart-splits").resize_left()
        end,
        desc = "Resize split left",
      },
      {
        "<A-j>",
        function()
          require("smart-splits").resize_down()
        end,
        desc = "Resize split down",
      },
      {
        "<A-k>",
        function()
          require("smart-splits").resize_up()
        end,
        desc = "Resize split up",
      },
      {
        "<A-l>",
        function()
          require("smart-splits").resize_right()
        end,
        desc = "Resize split right",
      },
      {
        "<C-\\>",
        function()
          require("smart-splits").move_cursor_previous()
        end,
        desc = "Move to previous split",
      },
    },
  },
}
