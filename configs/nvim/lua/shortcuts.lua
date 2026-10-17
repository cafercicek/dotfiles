local M = {}

function M.open_cheat_sheet()
  local path = vim.fn.stdpath("config") .. "/neovim-shortcuts.md"
  if vim.fn.filereadable(path) == 0 then
    vim.notify("Shortcuts file not found: " .. path, vim.log.levels.ERROR)
    return
  end

  local lines = vim.fn.readfile(path)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "wipe"

  local width = math.floor(vim.o.columns * 0.88)
  local height = math.floor(vim.o.lines * 0.88)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    border = "rounded",
    title = " Neovim Shortcuts ",
    title_pos = "center",
  })
end

return M
