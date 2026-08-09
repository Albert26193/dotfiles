-----------------------------------------------------------
-- LSP configuration
-----------------------------------------------------------

-- local status_ok, lspconfig = pcall(require, 'lspconfig')
-- if not status_ok then
--   return
-- end

local status_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
if not status_cmp then
  return
end

-- Add additional capabilities supported by nvim-cmp
local capabilities = cmp_nvim_lsp.default_capabilities()

-- LSP keymaps
local on_attach = function(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  -- Keybindings
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gh', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<leader>f', function()
    vim.lsp.buf.format({ async = true })
  end, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
  vim.keymap.set('n', 'gp', vim.diagnostic.open_float, opts)
end

-- Configure diagnostic display
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = 'rounded',
    source = 'always',
  },
})

-- Change diagnostic symbols in the sign column
-- local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
-- for type, icon in pairs(signs) do
--   local hl = "DiagnosticSign" .. type
--   vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
-- end

-- Configure all LSP servers with default settings
-- vim.lsp.config("*", {
--   on_attach = on_attach,
--   capabilities = capabilities,
-- })

-- Servers to setup
local servers = {
  'lua_ls',
  'pyright',
  'bashls',
  'ts_ls',
  'html',
  'cssls',
  'jsonls',
}

for _, server in ipairs(servers) do
  local opts = {
    on_attach = on_attach,
    capabilities = capabilities,
  }

  -- Lua specific settings
  if server == "lua_ls" then
    opts.settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        diagnostics = { globals = { 'vim' } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
        telemetry = { enable = false },
      },
    }
  end

  -- JSON specific settings
  if server == "jsonls" then
    opts.settings = {
      json = {
        format = { enable = true },
        validate = { enable = true },
      },
    }
  end

  -- Bash specific settings
  if server == "bashls" then
    opts.filetypes = { "sh", "bash", "zsh" }
  end

  vim.lsp.config(server, opts)
end

vim.lsp.enable(servers)
