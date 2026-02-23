-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.filetype.add({
  extension = {
    gotmpl = "gotmpl",
    gohtml = "gotmpl",
  },
  pattern = {
    [".*%.html%.tmpl"] = "gotmpl",
    [".*%.gohtml%.tmpl"] = "gotmpl",
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "template",
  callback = function(ev)
    local name = vim.api.nvim_buf_get_name(ev.buf)
    if name:match("%.html%.tmpl$") or name:match("%.gohtml%.tmpl$") then
      vim.bo[ev.buf].filetype = "gotmpl"
    end
  end,
})
