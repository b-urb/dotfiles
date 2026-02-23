local function parse_bool(value)
  if value == nil then
    return false
  end
  local normalized = string.lower(tostring(value))
  return normalized == "1" or normalized == "true" or normalized == "yes" or normalized == "on"
end

local function is_snacks_explorer_window()
  if vim.bo.filetype ~= "snacks_picker_list" then
    return false
  end

  local win_config = vim.api.nvim_win_get_config(0)
  return win_config.relative ~= "" and win_config.zindex == 33
end

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

local function wezterm_activate_pane_direction(direction)
  return run_wezterm_cli({ "activate-pane-direction", direction })
end

local function move_left_via_mux()
  local ok, mux = pcall(require, "smart-splits.mux")
  if ok and mux ~= nil and mux.move_pane ~= nil then
    if mux.move_pane("left", false, "wrap") then
      return true
    end
  end

  return wezterm_activate_pane_direction("Left")
end

local function focus_snacks_host_window()
  local current = vim.api.nvim_get_current_win()
  local win_config = vim.api.nvim_win_get_config(current)
  local host = win_config.win

  if host ~= nil and host ~= 0 and host ~= current and vim.api.nvim_win_is_valid(host) then
    local host_config = vim.api.nvim_win_get_config(host)
    if host_config.relative == "" then
      vim.api.nvim_set_current_win(host)
      return true
    end
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= current then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative == "" then
        vim.api.nvim_set_current_win(win)
        return true
      end
    end
  end

  return false
end

local function move_with_snacks_workaround(wincmd_key, smart_move_fn)
  return function()
    if is_snacks_explorer_window() then
      if wincmd_key == "h" then
        if move_left_via_mux() then
          return
        end

        focus_snacks_host_window()
        require("smart-splits")[smart_move_fn]()
        return
      end

      local before = vim.api.nvim_get_current_win()
      vim.cmd("wincmd " .. wincmd_key)
      local after = vim.api.nvim_get_current_win()

      if after ~= before then
        return
      end

      if focus_snacks_host_window() then
        return
      end
    end

    require("smart-splits")[smart_move_fn]()
  end
end

local function resolve_multiplexer_integration()
  local mode = string.lower(vim.env.DOTFILES_ZELLIJ_MODE or "")
  if mode == "full" then
    return "zellij"
  end
  if mode == "native" or mode == "bridge" then
    return "wezterm"
  end

  if parse_bool(vim.env.DOTFILES_ENABLE_ZELLIJ) then
    return "zellij"
  end
  return "wezterm"
end

local function wezterm_activate_tab_relative(delta)
  return run_wezterm_cli({ "activate-tab", "--tab-relative", tostring(delta) })
end

local reverse_direction = {
  left = "right",
  right = "left",
  up = "down",
  down = "up",
}

local function move_mux_once(mux, direction)
  if mux == nil or mux.current_pane_id == nil or mux.next_pane == nil then
    return false
  end

  local current_pane_id = mux.current_pane_id()
  if current_pane_id == nil then
    return false
  end

  if not mux.next_pane(direction) then
    return false
  end

  local target_pane_id = mux.current_pane_id()
  return target_pane_id ~= nil and target_pane_id ~= current_pane_id
end

local function move_mux_with_wrap(ctx)
  local mux = ctx.mux
  if move_mux_once(mux, ctx.direction) then
    return true
  end

  local reverse = reverse_direction[ctx.direction]
  return reverse ~= nil and move_mux_once(mux, reverse)
end

local function resolve_at_edge_behavior(multiplexer_integration)
  if multiplexer_integration ~= "wezterm" then
    return "wrap"
  end

  return function(ctx)
    if ctx.direction == "left" then
      if wezterm_activate_tab_relative(-1) then
        return
      end
    elseif ctx.direction == "right" then
      if wezterm_activate_tab_relative(1) then
        return
      end
    end

    if move_mux_with_wrap(ctx) then
      return
    end

    ctx.wrap()
  end
end

return {
  {
    "mrjones2014/smart-splits.nvim",
    version = "*",
    lazy = false,
    opts = function()
      local multiplexer_integration = resolve_multiplexer_integration()

      return {
        multiplexer_integration = multiplexer_integration,
        at_edge = resolve_at_edge_behavior(multiplexer_integration),
        zellij_move_focus_or_tab = false,
        float_win_behavior = "previous",
      }
    end,
    keys = {
      { "<C-h>", move_with_snacks_workaround("h", "move_cursor_left"), desc = "Move to left split" },
      { "<C-j>", move_with_snacks_workaround("j", "move_cursor_down"), desc = "Move to below split" },
      { "<C-k>", move_with_snacks_workaround("k", "move_cursor_up"), desc = "Move to upper split" },
      { "<C-l>", move_with_snacks_workaround("l", "move_cursor_right"), desc = "Move to right split" },
      { "<A-h>", function() require("smart-splits").resize_left() end, desc = "Resize split left" },
      { "<A-j>", function() require("smart-splits").resize_down() end, desc = "Resize split down" },
      { "<A-k>", function() require("smart-splits").resize_up() end, desc = "Resize split up" },
      { "<A-l>", function() require("smart-splits").resize_right() end, desc = "Resize split right" },
      { "<C-\\>", function() require("smart-splits").move_cursor_previous() end, desc = "Move to previous split" },
    },
  },
}
