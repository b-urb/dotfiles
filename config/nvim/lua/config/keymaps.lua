-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

local function toggle_zellij_floating_terminal()
  local zellij_mode = (vim.env.DOTFILES_ZELLIJ_MODE or "native"):lower()
  local prefer_zellij = zellij_mode == "bridge" or zellij_mode == "full"

  if prefer_zellij and vim.fn.executable("zellij") == 1 then
    local cmd = { "zellij" }
    if vim.env.ZELLIJ_SESSION_NAME and vim.env.ZELLIJ_SESSION_NAME ~= "" then
      table.insert(cmd, "--session")
      table.insert(cmd, vim.env.ZELLIJ_SESSION_NAME)
    end
    table.insert(cmd, "action")
    table.insert(cmd, "toggle-floating-panes")
    vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("Failed to toggle zellij floating panes", vim.log.levels.WARN)
    end
    return
  end

  Snacks.terminal(nil, { cwd = LazyVim.root() })
end

map({ "n", "t" }, "<C-/>", toggle_zellij_floating_terminal, { desc = "Toggle Zellij Floating Terminal" })
map({ "n", "t" }, "<C-_>", toggle_zellij_floating_terminal, { desc = "which_key_ignore" })
