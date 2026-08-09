-- utf8
vim.g.encoding = "UTF-8"
vim.o.fileencoding = "utf-8"

print("this is the file for code")

-- keep 4 lines around cursor when moving with jkhl
vim.o.scrolloff = 4
vim.o.sidescrolloff = 4

-- use relative line numbers
-- vim.wo.number = true
-- vim.wo.relativenumber = true

-- highlight current line
-- vim.wo.cursorline = true

-- show sign column on the left
-- vim.wo.signcolumn = "yes"

-- right margin line, consider wrapping if code exceeds this
-- vim.wo.colorcolumn = "120"

-- 2 spaces = 1 tab
--vim.o.tabstop = 2
--vim.bo.tabstop = 2
--vim.o.softtabstop = 2
--vim.o.shiftround = true

-- shift width for >> <<
-- vim.o.shiftwidth = 2
-- vim.bo.shiftwidth = 2

-- use spaces instead of tabs
vim.o.expandtab = true
vim.bo.expandtab = true

-- align new lines with current line
-- vim.o.autoindent = true
-- vim.bo.autoindent = true
-- vim.o.smartindent = true

-- case insensitive search unless uppercase is used
vim.o.ignorecase = true
vim.o.smartcase = true

-- highlight search results
-- vim.o.hlsearch = true

-- search as you type
vim.o.incsearch = false

-- command line height
-- vim.o.cmdheight = 2

-- auto reload when file is modified externally
-- vim.o.autoread = true
-- vim.bo.autoread = true

-- disable line wrap
-- vim.wo.wrap = false

-- allow cursor to move to next/prev line at line start/end
-- vim.o.whichwrap = '<,>,[,]'

-- allow hiding modified buffers
-- vim.o.hidden = true

-- mouse support
-- vim.o.mouse = "a"

-- disable backup files
-- vim.o.backup = false
-- vim.o.writebackup = false
-- vim.o.swapfile = false

-- smaller updatetime
-- vim.o.updatetime = 300

-- timeoutlen for key sequence wait time
-- vim.o.timeoutlen = 300

-- split window below and right
-- vim.o.splitbelow = true
-- vim.o.splitright = true

-- auto complete options
-- vim.g.completeopt = "menu,menuone,noselect,noinsert"

-- appearance
--vim.o.background = "dark"
--vim.o.termguicolors = true
--vim.opt.termguicolors = true

-- show invisible chars, space as dot
-- vim.o.list = true
-- vim.o.listchars = "space:·"

-- enhanced wild menu
-- vim.o.wildmenu = true

-- Dont' pass messages to |ins-completin menu|
-- vim.o.shortmess = vim.o.shortmess .. 'c'

-- max 10 items in popup menu
-- vim.o.pumheight = 10

-- always show tabline
-- vim.o.showtabline = 2

-- hide mode since we use statusline plugin
--vim.o.showmode = false
