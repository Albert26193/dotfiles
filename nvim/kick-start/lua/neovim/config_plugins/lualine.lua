local status, lualine = pcall(require, "lualine")
if not status then
  vim.notify("lualine not found")
  return
end

lualine.setup({
  options = {
    -- theme
    -- https://github.com/nvim-lualine/lualine.nvim/blob/master/THEMES.md
    theme = "tokyonight",
    -- separators
    component_separators = {
      left = "|",
      right = "|",
    },
    -- https://github.com/ryanoasis/powerline-extra-symbols
    globalstatus = true,
  },
  extensions = { "nvim-tree" },
  sections = {
    lualine_c = {
      "filename",
      {
        "lsp_progress",
        spinner_symbols = { " ", " ", " ", " ", " ", " " },
      },
    },
    lualine_x = {
      "filesize",
      {
        "fileformat",
        -- symbols = {
        --   unix = '', -- e712
        --   dos = '', -- e70f
        --   mac = '', -- e711
        -- },
        symbols = {
          unix = "LF",
          dos = "CRLF",
          mac = "CR",
        },
      },
      "encoding",
      "filetype",
    },
  },
})
