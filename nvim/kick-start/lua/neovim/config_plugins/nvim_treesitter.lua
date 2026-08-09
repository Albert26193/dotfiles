local status, treesitter = pcall(require, "nvim-treesitter.configs")
if not status then
	vim.notify("nvim-treesitter not found")
	return
end

treesitter.setup({
	-- install language parser
	-- :TSInstallInfo to see supported languages
	ensure_installed = {
		"python",
		"json",
		"c",
		"cpp",
		"go",
		"rust",
		"html",
		"css",
		"vim",
		"lua",
		"javascript",
		"typescript",
		"tsx",
		"rust",
	},
	-- ensure_installed = "maintained",

	-- enable syntax highlighting
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
	-- disable incremental selection
	incremental_selection = {
		enable = false,
		keymaps = {
			init_selection = "<CR>",
			node_incremental = "<CR>",
			node_decremental = "<BS>",
			scope_incremental = "<TAB>",
		},
	},
	-- enable indent module (=)
	indent = {
		enable = true,
	},
	-- p00f/nvim-ts-rainbow
	-- rainbow = {
	-- 	enable = true,
	-- 	-- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
	-- 	extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
	-- 	max_file_lines = nil, -- Do not enable for files with more than n lines, int
	-- 	colors = {
	-- 		"#55ca60",
	-- 		"#a6a760",
	-- 		"#7794f4",
	-- 		"#b38bf5",
	-- 		"#7cc7fe",
	-- 	}, -- table of hex strings
	-- 	termcolors = {
	-- 		"#55ca60",
	-- 		"#a6a760",
	-- 		"#7794f4",
	-- 		"#b38bf5",
	-- 		"#7cc7fe",
	-- 	}, -- table of colour name strings
	-- },
})
-- enable folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
-- default no fold
-- https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file
vim.opt.foldlevel = 99
