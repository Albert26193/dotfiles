vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.timeout = true
vim.opt.timeoutlen = 300
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 4
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.updatetime = 250
vim.opt.termguicolors = true

if vim.g.vscode_clipboard then
  vim.g.clipboard = vim.g.vscode_clipboard
end

local ok, vscode = pcall(require, 'vscode')
if ok then
  vim.notify = vscode.notify
end
