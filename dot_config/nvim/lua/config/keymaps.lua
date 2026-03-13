-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Ctrl-/ terminal toggling is handled at WezTerm level in native keybinds.

pcall(vim.keymap.del, { "n", "t" }, "<C-/>")
pcall(vim.keymap.del, { "n", "t" }, "<C-_>")
