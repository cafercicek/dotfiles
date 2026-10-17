vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("inoremap jj <esc>")
--vim.cmd("tnoremap <Esc> <C-\><C-n>")
vim.cmd("set clipboard=unnamedplus")
--vim.cmd("set mouse=a")
vim.cmd("set number")
vim.cmd("set autoread")
vim.opt.autoread = true
vim.g.mapleader = " "
--vim.cmd("tnoremap <Esc> <C-\\><C-n>")

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "BufEnter" }, {
  command = "checktime",
})
-- TermOpen handled below (after terminal keymaps)
--vim.keymap.set('n', '<leader>tt', ':belowright 10split | terminal<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>tt', ':belowright 10split | terminal bash<CR>', { noremap = true, silent = true, desc = "Open terminal" })
vim.keymap.set('t', '<C-d>', [[<C-\><C-n>:q<CR>]], { noremap = true })
-- No global Esc in terminal: it breaks Cursor agent vimMode (Esc must reach the agent).
-- Exit terminal insert with jj, or Esc Esc in cursorcli agent buffers.
vim.keymap.set('t', 'jj', [[<C-\><C-n>]], { noremap = true })

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(event)
    vim.cmd.startinsert()
    vim.defer_fn(function()
      if not vim.api.nvim_buf_is_valid(event.buf) then
        return
      end
      local is_agent = vim.b[event.buf].cursorcli_chat_id ~= nil
      if not is_agent then
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = event.buf, noremap = true })
      end
    end, 50)
  end,
})

vim.keymap.set('n', '<C-d>', ':q<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>sh', ':split<CR>', { noremap = true, silent = true, desc = "Horizontal split" })
vim.keymap.set('n', '<leader>sv', ':vsplit<CR>', { noremap = true, silent = true, desc = "Vertical split" })

vim.keymap.set('n', '<leader>+', ':resize +4<CR>', { noremap = true, silent = true, desc = "Increase height" })
vim.keymap.set('n', '<leader>-', ':resize -4<CR>', { noremap = true, silent = true, desc = "Decrease height" })
vim.keymap.set('n', '<leader>>', ':vertical resize +5<CR>', { noremap = true, silent = true, desc = "Increase width" })
vim.keymap.set('n', '<leader><', ':vertical resize -5<CR>', { noremap = true, silent = true, desc = "Decrease width" })

vim.keymap.set('n', '<leader>j', '<C-w>j', { noremap = true, desc = "Focus down" })
vim.keymap.set('n', '<leader>k', '<C-w>k', { noremap = true, desc = "Focus up" })
vim.keymap.set('n', '<leader>h', '<C-w>h', { noremap = true, desc = "Focus left" })
vim.keymap.set('n', '<leader>l', '<C-w>l', { noremap = true, desc = "Focus right" })



vim.keymap.set('n', '<leader>cr', ':%s/\\r//g<CR>', { noremap = true, silent = true, desc = "Strip CRLF" })

vim.keymap.set("n", "<leader>cf", function()
  vim.cmd('!clang-format-19 -i -style=LLVM %')
  vim.cmd('checktime')  
end, { desc = "Clang Format current file (Linux style)" })


vim.keymap.set('n', '<leader><CR>', function()
  local curr_win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd j")
  if vim.api.nvim_get_current_win() == curr_win then
    vim.cmd("wincmd k")
  end
end, { noremap = true, silent = true, desc = "Toggle terminal pane" })

local is_zoomed = false
local zoom_state = {}

function ToggleMaximizeWindow()
  if not is_zoomed then
    zoom_state.view = vim.fn.winsaveview()
    zoom_state.cmd = vim.fn.winrestcmd()

    vim.cmd("wincmd |")
    vim.cmd("wincmd _")
    is_zoomed = true
  else
    vim.fn.winrestview(zoom_state.view)
    vim.cmd(zoom_state.cmd)
    is_zoomed = false
  end
end

vim.keymap.set("n", "<leader>f", ToggleMaximizeWindow, { noremap = true, silent = true, desc = "Toggle maximize current window" })

local shortcuts = require("shortcuts")
vim.keymap.set("n", "<leader>sk", shortcuts.open_cheat_sheet, { desc = "Shortcut cheat sheet" })
vim.keymap.set("n", "<leader>?", shortcuts.open_cheat_sheet, { desc = "Shortcut cheat sheet" })
vim.api.nvim_create_user_command("NeovimShortcuts", shortcuts.open_cheat_sheet, {})

--local is_vert_zoomed = false
--local vert_zoom_state = {}
--
--function ToggleVerticalZoom()
--  if not is_vert_zoomed then
--    vert_zoom_state.view = vim.fn.winsaveview()
--    vert_zoom_state.height = vim.api.nvim_win_get_height(0)
--
--    vim.cmd("wincmd _") 
--    is_vert_zoomed = true
--  else
--    vim.fn.winrestview(vert_zoom_state.view)
--    vim.api.nvim_win_set_height(0, vert_zoom_state.height)
--    is_vert_zoomed = false
--  end
--end
--
--vim.keymap.set("n", "<leader>f", ToggleVerticalZoom, { noremap = true, silent = true, desc = "Toggle vertical zoom of current window" })

---- Global variable to store the first selected file for diff
--_G.diff_marked_file = nil
--
---- Mark the currently selected file in Neo-tree
--vim.keymap.set('n', '<leader>dm', function()
--  _G.diff_marked_file = vim.fn.expand('%')
--  print("Marked for diff: " .. _G.diff_marked_file)
--end, { desc = "Mark current file for diff" })
--
---- Diff current file with previously marked file
--vim.keymap.set('n', '<leader>dd', function()
--  local file2 = vim.fn.expand('%')
--  local file1 = _G.diff_marked_file
--
--  if not file1 then
--    print("No file marked for diff. Press <leader>dm on the first file.")
--    return
--  end
--
--  -- Open file1 in new tab and diff it with file2
--  vim.cmd('tabnew ' .. file1)
--  vim.cmd('vert diffsplit ' .. file2)
--
--  -- Reset marked file
--  _G.diff_marked_file = nil
--end, { desc = "Diff with marked file" })
