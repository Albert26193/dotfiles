-----------------------------------------------------------
-- UI configuration
-----------------------------------------------------------

-- Set colorscheme
vim.o.termguicolors = true
vim.o.background = 'dark'

-- vim.cmd.colorscheme "ayu-mirage"
-- vim.cmd.colorscheme "ayu"
-- require('solarized').setup(opts)
-- vim.cmd.colorscheme 'solarized'
require("one_monokai").setup({
  transparent = false,
  colors = {
    -- pink  = "#ec6075",
    -- lmao  = "#ffffff",
    -- human = 0xFFABCD,
    -- alien = 16755661,
    water = "#5a96ac",
  },
  highlights = function(colors)
    return {
      Normal                                = { bg = colors.bg:darken(0.85) },
      DiffChange                            = { fg = colors.white:darken(0.3) },
      -- render-markdown 的 H3Bg 默认 link 到 DiffChange；此处显式定义，
      -- 把 H3 标题行从 DiffChange 的 fg 覆盖中解耦，避免标题文字被染成暗灰不可读
      RenderMarkdownH3Bg                    = { bg = colors.dark_gray },
      ErrorMsg                              = { fg = colors.pink, standout = true },
      EasyMotionShade                       = { fg = "#3c4b4c" },
      EasyMotionTarget                      = { fg = "#00ff00" },
      EasyMotionTarget2First                = { fg = "#00ff66", bg = "#000000" },
      EasyMotionTarget2Second               = { fg = "#ffff66", bg = "#0000ff" },

      ["@lsp.type.keyword"]                 = { link = "@keyword" },

      -- 依据 One Monokai 未注释的 C++ 规则对齐
      ["@lsp.type.class"]                   = { fg = "#61afef" },
      ["@lsp.type.struct"]                  = { fg = "#56b6c2" },
      ["@lsp.type.enumMember"]              = { fg = "#829703" },
      ["@lsp.type.namespace"]               = { fg = "#56b6c2" },
      ["@lsp.type.typeAlias"]               = { fg = "#61afef" },
      ["@lsp.type.variable"]                = { fg = "#c9c9c9" },
      ["@lsp.type.property"]                = { fg = "#678abf" },
      ["@lsp.type.function"]                = { fg = "#54c073" },
      ["@lsp.type.macro"]                   = { fg = "#9ea4de" },

      -- 原 method、enum 等保持不变
      ["@lsp.type.method"]                  = { fg = colors.cyan },
      ["@lsp.type.enum"]                    = { fg = colors.green },

      -- 模拟 *.static:cpp
      ["@lsp.typemod.variable.static"]      = { fg = "#ffbe73", italic = true },
      ["@lsp.typemod.function.static"]      = { fg = "#ffbe73", italic = true },
      ["@lsp.typemod.method.static"]        = { fg = "#ffbe73", italic = true },
      ["@lsp.typemod.property.static"]      = { fg = "#ffbe73", italic = true },

      -- 保留原有的作用域修饰符
      ["@lsp.typemod.variable.globalScope"] = { fg = colors.red },
      ["@lsp.typemod.variable.classScope"]  = { fg = colors.orange },
      ["@lsp.typemod.variable.fileScope"]   = { fg = colors.fg },
    }
  end,
  italics = false,
})
vim.cmd.colorscheme("one_monokai")



-- Lualine
local status_lualine, lualine = pcall(require, 'lualine')
if status_lualine then
  lualine.setup({
    theme = "one_monokai",
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
