-----------------------------------------------------------
-- UI configuration
-----------------------------------------------------------

-- Set colorscheme
-- vim.cmd.colorscheme "ayu-mirage"
vim.cmd.colorscheme "ayu"

-- Lualine
local status_lualine, lualine = pcall(require, 'lualine')
if status_lualine then
  lualine.setup({
    options = {
      icons_enabled = true,
      theme = 'auto',
      component_separators = { left = '', right = '' },
      section_separators = { left = '', right = '' },
      disabled_filetypes = {
        statusline = {},
        winbar = {},
      },
      always_divide_middle = true,
      globalstatus = true,
    },
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch', 'diff', 'diagnostics' },
      lualine_c = { 'filename' },
      lualine_x = { 'encoding', 'fileformat', 'filetype' },
      lualine_y = { 'progress' },
      lualine_z = { 'location' }
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { 'filename' },
      lualine_x = { 'location' },
      lualine_y = {},
      lualine_z = {}
    },
    tabline = {},
    extensions = {}
  })
end

-- Gitsigns
local status_gitsigns, gitsigns = pcall(require, 'gitsigns')
if status_gitsigns then
  gitsigns.setup({
    signs = {
      add          = { text = '│' },
      change       = { text = '│' },
      delete       = { text = '_' },
      topdelete    = { text = '‾' },
      changedelete = { text = '~' },
      untracked    = { text = '┆' },
    },
    signcolumn = true,
    current_line_blame = false,
    preview_config = {
      border = 'rounded',
      style = 'minimal',
      relative = 'cursor',
      row = 0,
      col = 1
    },
  })
end

-- Autopairs
local status_autopairs, autopairs = pcall(require, 'nvim-autopairs')
if status_autopairs then
  autopairs.setup({
    check_ts = true,
    ts_config = {
      lua = { 'string' },
      javascript = { 'template_string' },
    },
  })
end
