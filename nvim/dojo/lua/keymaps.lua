-----------------------------------------------------------
-- Keymaps configuration file
-----------------------------------------------------------

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-----------------------------------------------------------
-- Leader key
-----------------------------------------------------------
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-----------------------------------------------------------
-- General
-----------------------------------------------------------
-- Clear search highlighting and balance windows
map('n', '<Esc>', ':noh | wincmd =<CR>', opts)

-- Save file
map('n', '<C-s>', ':w<CR>', opts)

-- Quit (disabled, <C-q> now used for window picker)
-- map('n', '<C-q>', ':q<CR>', opts)

-- Telescope find files (VSCode-like)
map('n', '<M-p>', '<cmd>Telescope find_files<CR>', { desc = 'Find files (Telescope)' })

-- sidebar (VSCode-like)
-- map('n', '<M-b>', '<cmd> NvimTreeToggle <CR>', { desc = 'toggle nvim tree' })

-----------------------------------------------------------
-- Window navigation
-----------------------------------------------------------
map('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Move to window below' })
map('n', '<C-k>', '<C-w>k', { desc = 'Move to window above' })
map('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Alt+number to jump to window (tmux style)
for i = 1, 9 do
  map('n', '<C-w>' .. i, function()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    if wins[i] then
      vim.api.nvim_set_current_win(wins[i])
    end
  end, { desc = 'Go to window ' .. i })
end
-----------------------------------------------------------
-- Window resizing
-----------------------------------------------------------
map('n', '<C-Up>', ':resize +2<CR>', opts)
map('n', '<C-Down>', ':resize -2<CR>', opts)
map('n', '<C-Left>', ':vertical resize -2<CR>', opts)
map('n', '<C-Right>', ':vertical resize +2<CR>', opts)

-----------------------------------------------------------
-- Buffer navigation
-----------------------------------------------------------
map('n', '<Tab>', ':bnext<CR>', opts)
map('n', '<S-Tab>', ':bprevious<CR>', opts)

-----------------------------------------------------------
-- Copy to system clipboard
-----------------------------------------------------------
map('v', '<C-c>', '"+y', { desc = 'Copy to system clipboard' })
map('n', '<C-c>', 'viw"+y', { desc = 'Copy word to system clipboard' })

-----------------------------------------------------------
-- Toggle wrap
-----------------------------------------------------------
map('n', '<A-z>', function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = 'Toggle line wrap' })

-----------------------------------------------------------
-- Better line movement (Accelerated JK)
-----------------------------------------------------------
map('n', 'j', '<Plug>(accelerated_jk_gj)', {})
map('n', 'k', '<Plug>(accelerated_jk_gk)', {})
map('v', 'j', 'gj', opts)
map('v', 'k', 'gk', opts)

-----------------------------------------------------------
-- Window resizing (NvChad style)
-----------------------------------------------------------
map("n", "<M-=>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })
map("n", "<M-->", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
-- Toggle maximize window
map("n", "<C-w>z", function()
  if vim.g.maximized_window then
    vim.cmd('wincmd =')
    vim.g.maximized_window = false
  else
    vim.cmd('wincmd _ | wincmd |')
    vim.g.maximized_window = true
  end
end, { desc = "Toggle maximize window" })

-----------------------------------------------------------
-- Page scrolling (VSCode style: 18 lines + center)
-----------------------------------------------------------
map('n', '<C-d>', '18jzz', { desc = 'Scroll down 18 lines and center' })
map('n', '<C-b>', '18kzz', { desc = 'Scroll up 18 lines and center' })

-----------------------------------------------------------
-- Fold navigation and operations
-----------------------------------------------------------
map('n', 'zj', '<cmd>silent! normal! zj<CR>', { desc = 'Go to next fold' })
map('n', 'zk', '<cmd>silent! normal! zk<CR>', { desc = 'Go to previous fold' })
map('n', 'zp', 'zCzo', { desc = 'Close all folds and open one level' })
map('n', 'zi', '$vaBozazv', { desc = 'Select block and toggle fold' })

-----------------------------------------------------------
-- LSP keymaps (g prefix)
-----------------------------------------------------------
map('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', { desc = 'Go to definition' })
map('n', 'gD', '<cmd>vsplit | lua vim.lsp.buf.definition()<CR>', { desc = 'Go to definition in split' })
map('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', { desc = 'Find references' })
map('n', 'ge', '<cmd>lua vim.lsp.buf.references()<CR>', { desc = 'Go to references' })
map('n', 'gh', '<cmd>lua vim.lsp.buf.references()<CR>', { desc = 'Go to references' })
map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', { desc = 'Go to implementation' })
map('n', 'ga', '<cmd>lua vim.lsp.buf.incoming_calls()<CR>', { desc = 'Show call hierarchy' })
map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', { desc = 'Show hover' })

-----------------------------------------------------------
-- Global search (g prefix, VSCode style)
-----------------------------------------------------------
-- gf: copy word and open Telescope live_grep with it
map('n', 'gf', function()
  local word = vim.fn.expand('<cword>')
  require('telescope.builtin').live_grep({ default_text = word })
end, { desc = 'Search word in project (live grep)' })

-- gb: copy word and search in files
map('n', 'gb', function()
  local word = vim.fn.expand('<cword>')
  require('telescope.builtin').grep_string({ search = word })
end, { desc = 'Grep word under cursor' })

-----------------------------------------------------------
-- Buffer management (g prefix)
-----------------------------------------------------------
-- gt: close other buffers in current tab
map('n', 'gt', '<cmd>%bd|e#|bd#<CR>', { desc = 'Close other buffers' })

-- gT: close all other buffers
map('n', 'gT', function()
  local current = vim.api.nvim_get_current_buf()
  local bufs = vim.api.nvim_list_bufs()
  for _, buf in ipairs(bufs) do
    if buf ~= current and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end, { desc = 'Close all other buffers' })

-----------------------------------------------------------
-- Window movement (move buffer to other split)
-----------------------------------------------------------
map('n', '<C-w>J', '<cmd>wincmd J<CR>', { desc = 'Move window to bottom' })
map('n', '<C-w>K', '<cmd>wincmd K<CR>', { desc = 'Move window to top' })
map('n', '<C-w>H', '<cmd>wincmd H<CR>', { desc = 'Move window to left' })
map('n', '<C-w>L', '<cmd>wincmd L<CR>', { desc = 'Move window to right' })

-----------------------------------------------------------
-- Bufferline (tab bar)
-----------------------------------------------------------
map('n', '<S-h>', '<cmd>BufferLineCyclePrev<CR>', { desc = 'Prev buffer' })
map('n', '<S-l>', '<cmd>BufferLineCycleNext<CR>', { desc = 'Next buffer' })
map('n', '[b', '<cmd>BufferLineCyclePrev<CR>', { desc = 'Prev buffer' })
map('n', ']b', '<cmd>BufferLineCycleNext<CR>', { desc = 'Next buffer' })
map('n', '<leader>bp', '<cmd>BufferLineTogglePin<CR>', { desc = 'Toggle pin' })
map('n', '<leader>bP', '<cmd>BufferLineGroupClose ungrouped<CR>', { desc = 'Delete non-pinned buffers' })
