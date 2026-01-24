-----------------------------------------------------------
-- General Neovim settings and configuration
-----------------------------------------------------------

local g = vim.g     -- Global variables
local o = vim.o     -- Set options
local opt = vim.opt -- Set options (lua list/map-like)

-----------------------------------------------------------
-- General
-----------------------------------------------------------
o.mouse = 'a'                               -- Enable mouse support
-- o.clipboard = 'unnamedplus'         -- Copy/paste to system clipboard
o.cursorline = true                         -- Highlight current line
-- o.cursorlineopt = "number"          -- Highlight current line number
o.swapfile = false                          -- Don't use swapfile
o.backup = false                            -- Don't create backup files
o.writebackup = false                       -- Don't create backup before overwriting
o.completeopt = 'menuone,noinsert,noselect' -- Autocomplete options

-----------------------------------------------------------
-- Neovim UI
-----------------------------------------------------------
o.number = true         -- Show line number
o.relativenumber = true -- Show relative line numbers
o.showmatch = true      -- Highlight matching parenthesis
o.foldmethod = 'marker' -- Enable folding (default 'foldmarker')
o.colorcolumn = '100'   -- Line length marker at 100 columns
o.splitright = true     -- Vertical split to the right
o.splitbelow = true     -- Horizontal split to the bottom
o.ignorecase = true     -- Ignore case letters when search
o.smartcase = true      -- Ignore lowercase for the whole pattern
o.linebreak = true      -- Wrap on word boundary
o.termguicolors = true  -- Enable 24-bit RGB colors
o.background = "dark"   -- Set background to dark
o.laststatus = 3        -- Set global statusline
o.signcolumn = "yes"    -- Always show sign column

-----------------------------------------------------------
-- Tabs, indent
-----------------------------------------------------------
o.expandtab = true   -- Use spaces instead of tabs
o.shiftwidth = 2     -- Shift 2 spaces when tab
o.tabstop = 2        -- 1 tab == 2 spaces
o.softtabstop = 2    -- Number of spaces tabs count for
o.smartindent = true -- Autoindent new lines
o.autoindent = true  -- Copy indent from current line

-----------------------------------------------------------
-- Memory, CPU
-----------------------------------------------------------
o.hidden = true     -- Enable background buffers
o.history = 100     -- Remember N lines in history
o.lazyredraw = true -- Faster scrolling
o.synmaxcol = 240   -- Max column for syntax highlight
o.updatetime = 250  -- ms to wait for trigger an event

-----------------------------------------------------------
-- Search
-----------------------------------------------------------
o.hlsearch = true  -- Highlight search results
o.incsearch = true -- Search as you type

-----------------------------------------------------------
-- Encoding
-----------------------------------------------------------
g.encoding = "UTF-8"
o.fileencoding = "utf-8"

-----------------------------------------------------------
-- Scrolling
-----------------------------------------------------------
o.scrolloff = 4     -- Keep 4 lines around cursor
o.sidescrolloff = 4 -- Keep 4 columns around cursor

-----------------------------------------------------------
-- Startup
-----------------------------------------------------------
-- Disable nvim intro
opt.shortmess:append "sI"

-- Fix for tmux true color
if vim.env.TMUX then
  vim.cmd([[let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"]])
  vim.cmd([[let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"]])
end

-------------------- auto reload ----------------------
vim.o.autoread = true
vim.opt.updatetime = 750
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = { "*" },
})

-------------------- easy motion ----------------------
vim.cmd([[
  highlight ErrorMsg guibg=#fa1010 guifg=white
  hi EasyMotionShade guibg=NONE guifg=#3c4b4c
  hi EasyMotionTarget  guibg=none guifg=#00ff66
]])

-- Disable builtin plugins
local disabled_built_ins = {
  "2html_plugin",
  "getscript",
  "getscriptPlugin",
  "gzip",
  "logipat",
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "matchit",
  "tar",
  "tarPlugin",
  "rrhelper",
  "spellfile_plugin",
  "vimball",
  "vimballPlugin",
  "zip",
  "zipPlugin",
  "tutor",
  "rplugin",
  "synmenu",
  "optwin",
  "compiler",
  "bugreport",
  "ftplugin",
}

for _, plugin in pairs(disabled_built_ins) do
  g["loaded_" .. plugin] = 1
end
