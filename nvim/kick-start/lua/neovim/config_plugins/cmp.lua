local status, cmp = pcall(require, "cmp")
if not status then
    vim.notify("nvim-cmp not found")
  return
end

cmp.setup({
  preselect = cmp.PreselectMode.Item,
  completion = {
        completeopt = "menu,menuone,noinsert",
  },
  -- snippet engine
  snippet = {
    expand = function(args)
      -- For `vsnip` users.
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  -- completion sources
  sources = cmp.config.sources(
    { { name = "nvim_lsp" }, },
    { { name = "buffer" }, { name = "path" } }),


  -- key mappings
  mapping = {
    -- trigger completion
    ["<leader>i"] = cmp.mapping(cmp.mapping.complete(), {"i", "c"}),
    -- previous item
    ["<Up>"] = cmp.mapping.select_prev_item(),
    -- next item
    ["<Down>"] = cmp.mapping.select_next_item(),
    -- confirm
    ["<Tab>"] = cmp.mapping.confirm({
      select = true,
      behavior = cmp.ConfirmBehavior.Replace
    }),
    ["<CR>"] = cmp.mapping.confirm({
      select = true,
      behavior = cmp.ConfirmBehavior.Replace
    }),
  }

})

-- / search mode uses buffer source
cmp.setup.cmdline("/", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "buffer" },
  },
})

-- : command mode uses path and cmdline sources
cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "path" },
  }, {
      { name = "cmdline" },
    }),
})
