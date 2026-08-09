-- ~/.config/nvchad/lua/configs/lspconfig.lua

local nvlsp = require("nvchad.configs.lspconfig")
nvlsp.defaults()

-- inject NvChad defaults to all LSPs
vim.lsp.config("*", {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
})

-- 2) Server-specific config

-- bashls
vim.lsp.config("bashls", {
  filetypes = { "sh", "bash", "zsh" },
})

-- jsonls
vim.lsp.config("jsonls", {
  settings = {
    json = {
      format = { enable = true },
      validate = { enable = true },
    },
  },
})

-- lua_ls (was commented out, uncomment if needed)
-- vim.lsp.config("lua_ls", {
--   settings = {
--     Lua = {
--       runtime = { version = "LuaJIT" },
--     },
--   },
-- })

-- clangd (migrated your cmd/init_options/root_dir)
-- note: new system recommends root_markers for root detection
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--fallback-style=llvm",
  },

  init_options = {
    clangdFileStatus = true,
    usePlaceholders = true,
    completeUnimported = true,
    semanticHighlighting = true,
  },

  root_markers = {
    "compile_commands.json",
    "compile_flags.txt",
    ".git",
  },
})

-- 3) enable (only put LSP config name, not mason package/formatter name)
vim.lsp.enable({
  "bashls",
  "jsonls",
  "clangd",
  "lua_ls", -- remove this line if you don't need lua LSP
})

-- 4) ccls was fully commented: to enable, write like below and add "ccls" to vim.lsp.enable
-- vim.lsp.config("ccls", {
--   init_options = {
--     cache = { directory = "/tmp/ccls-cache" },
--   },
-- })
