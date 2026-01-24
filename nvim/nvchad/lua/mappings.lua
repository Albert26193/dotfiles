require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- Window navigation
map("n", "<C-w>j", "<C-w><S-j>", { desc = "Move to window below" })
map("n", "<C-w>k", "<C-w><S-k>", { desc = "Move to window above" })
map("n", "<C-w>h", "<C-w><S-h>", { desc = "Move to left window" })
map("n", "<C-w>l", "<C-w><S-l>", { desc = "Move to right window" })
-- Window resizing horizontal
map("n", "<M-=>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })
map("n", "<M-->", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-w>z", "<cmd>wincmd _ | wincmd |<CR>", { desc = "Maximize window" })


-- Copy to system clipboard
map("v", "<C-c>", '"+y', { desc = "Copy to system clipboard" })
-- map("n", "<C-c>", '"+y', { desc = "Copy to system clipboard" })
map("n", "<C-c>", 'viw"+y', { desc = "Copy word to system clipboard" })

-- Toggle wrap
vim.keymap.set('n', '<A-z>', function()
  vim.wo.wrap = not vim.wo.wrap
end)

-- jk to move
map("v", "j", "gj", { desc = "Move down by display line (v-mode)" })
map("v", "k", "gk", { desc = "Move up by display line (v-mode)" })
-- map("n", "j", "gj", { desc = "Move down by display line" })
-- map("n", "k", "gk", { desc = "Move up by display line" })
map('n', 'j', '<Plug>(accelerated_jk_gj)', {})
map('n', 'k', '<Plug>(accelerated_jk_gk)', {})


local pluginKeys = {}

-- lsp 回调函数快捷键设置
pluginKeys.mapLSP = function(mapbuf)
	-- rename
	mapbuf("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opt)
	-- code action
	mapbuf("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opt)
	-- go xx
	mapbuf("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opt)
	mapbuf("n", "gh", "<cmd>lua vim.lsp.buf.hover()<CR>", opt)
	mapbuf("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opt)
	mapbuf("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opt)
	mapbuf("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opt)
	-- diagnostic
	mapbuf("n", "gp", "<cmd>lua vim.diagnostic.open_float()<CR>", opt)
	mapbuf("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opt)
end
return pluginKeys

