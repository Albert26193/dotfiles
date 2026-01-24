-- ~/.config/nvchad/lua/configs/lspconfig.lua

local nvlsp = require("nvchad.configs.lspconfig")
nvlsp.defaults()

-- 1) 给所有 LSP 统一注入 NvChad 的默认 on_attach / on_init / capabilities
vim.lsp.config("*", {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
})

-- 2) Server-specific 配置（替代 lspconfig.xxx.setup{...}）

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

-- lua_ls（你原来是注释状态：需要的话取消注释）
-- vim.lsp.config("lua_ls", {
--   settings = {
--     Lua = {
--       runtime = { version = "LuaJIT" },
--     },
--   },
-- })

-- clangd（迁移你的 cmd/init_options/root_dir）
-- 注意：新体系推荐用 root_markers 做 root 检测（不再用 lspconfig.util.root_pattern）
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

-- 3) 启用（只放“LSP config 名称”，不要放 mason 包名/formatter 名）
vim.lsp.enable({
  "bashls",
  "jsonls",
  "clangd",
  "lua_ls", -- 如果你不需要 lua 的 LSP，就删掉这行
})

-- 4) ccls 你原来是整段注释：如果要启用，按新方式写成下面这样再把 "ccls" 加进 vim.lsp.enable
-- vim.lsp.config("ccls", {
--   init_options = {
--     cache = { directory = "/tmp/ccls-cache" },
--   },
-- })
