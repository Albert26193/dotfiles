-----------------------------------------------------------
-- Which-Key Configuration
-- Based on VSCode which-key bindings
-----------------------------------------------------------

-- Helper function to safely call Telescope
local function telescope_cmd(cmd)
  return function()
    local ok, _ = pcall(require, "telescope")
    if ok then
      vim.cmd(cmd)
    else
      vim.notify("telescope.nvim not installed", vim.log.levels.WARN)
    end
  end
end

local function nvim_tree_cmd(cmd)
  return function()
    local ok, _ = pcall(require, "nvim-tree")
    if ok then
      vim.cmd(cmd)
    else
      vim.notify("nvim-tree not installed", vim.log.levels.WARN)
    end
  end
end

local function setup()
  local status_ok, wk = pcall(require, "which-key")
  if not status_ok then
    vim.notify("which-key not found", vim.log.levels.WARN)
    return
  end

  wk.setup({
    preset = "modern",
    delay = 300,
    icons = {
      breadcrumb = "»",
      separator = "➜",
      group = "+",
      mappings = true,
    },
    win = {
      border = "rounded",
      padding = { 1, 2 },
    },
  })

  vim.keymap.set("n", "<C-x>", function()
    wk.show({ keys = "<leader>" })
  end, { desc = "Show WhichKey (leader)" })

  -- Leader key mappings
  wk.add({
    -- 🎯 Quick symbol search (space space)
    { "<leader><space>", telescope_cmd("Telescope lsp_document_symbols"), desc = "🎯 Search symbol" },

    -- 🎨 Command palette (VSCode Ctrl+Shift+P style)
    { "<leader>:", telescope_cmd("Telescope commands"), desc = "🎨 Command palette" },
    { "<leader>K", telescope_cmd("Telescope keymaps"), desc = "🎨 Search keymaps" },

    -- 💡 Inlay hints toggle
    { "<leader>i", function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
      vim.notify("Inlay hints " .. (enabled and "off" or "on"))
    end, desc = "💡 Toggle inlay hints" },

    -- 🦢 Yazi toggle
    { "<leader>y", function()
      -- Check if yazi.nvim is available
      local ok, yazi = pcall(require, "yazi")
      if ok then
        yazi.toggle()
      else
        vim.notify("yazi.nvim not installed", vim.log.levels.WARN)
      end
    end, desc = "🦢 Yazi toggle" },

    -- 🔄 Header/Source switch group
    -- { "<leader>o", group = "🔄 Switch" },
    -- { "<leader>oh", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "🔄 Switch to header" },
    -- { "<leader>ol", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "🔄 Switch to source" },
    -- { "<leader>oo", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "🔄 Toggle header/source" },

    -- 🔖️ Bookmarks group
    { "<leader>b", group = "🔖️ Bookmark" },
    { "<leader>bn", function()
      local ok, bookmarks = pcall(require, "bookmarks")
      if ok then bookmarks.bookmark_next() else vim.notify("bookmarks not installed", vim.log.levels.WARN) end
    end, desc = "🔖️ Next bookmark" },
    { "<leader>bp", function()
      local ok, bookmarks = pcall(require, "bookmarks")
      if ok then bookmarks.bookmark_prev() else vim.notify("bookmarks not installed", vim.log.levels.WARN) end
    end, desc = "🔖️ Previous bookmark" },
    { "<leader>bb", function()
      local ok, bookmarks = pcall(require, "bookmarks")
      if ok then bookmarks.bookmark_toggle() else vim.notify("bookmarks not installed", vim.log.levels.WARN) end
    end, desc = "🔖️ Toggle bookmark" },
    { "<leader>bs", telescope_cmd("Telescope bookmarks list"), desc = "🔖️ Show bookmarks" },
    { "<leader>bl", function()
      local ok, bookmarks = pcall(require, "bookmarks")
      if ok then bookmarks.bookmark_list() else vim.notify("bookmarks not installed", vim.log.levels.WARN) end
    end, desc = "🔖️ List bookmarks" },
    { "<leader>ba", function()
      local ok, bookmarks = pcall(require, "bookmarks")
      if ok then bookmarks.bookmark_list() else vim.notify("bookmarks not installed", vim.log.levels.WARN) end
    end, desc = "🔖️ List all bookmarks" },
    { "<leader>bc", function()
      local ok, bookmarks = pcall(require, "bookmarks")
      if ok then bookmarks.bookmark_clean() else vim.notify("bookmarks not installed", vim.log.levels.WARN) end
    end, desc = "🔖️ Clear bookmarks" },
    { "<leader>bC", function()
      local ok, bookmarks = pcall(require, "bookmarks")
      if ok then bookmarks.bookmark_clean() else vim.notify("bookmarks not installed", vim.log.levels.WARN) end
    end, desc = "🔖️ Clear all bookmarks" },
    { "<leader>be", function()
      local ok, bookmarks = pcall(require, "bookmarks")
      if ok then bookmarks.bookmark_ann() else vim.notify("bookmarks not installed", vim.log.levels.WARN) end
    end, desc = "🔖️ Edit bookmark label" },

    -- ✅️ Errors/Diagnostics group
    { "<leader>e", group = "✅️ Errors" },
    { "<leader>el", telescope_cmd("Telescope diagnostics"), desc = "✅ List errors" },
    { "<leader>en", vim.diagnostic.goto_next, desc = "✅️ Next error" },
    { "<leader>ep", vim.diagnostic.goto_prev, desc = "✅️ Previous error" },
    { "<leader>ec", function()
      local diag = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })[1]
      if diag then
        vim.fn.setreg("+", diag.message)
        vim.notify("Copied: " .. diag.message)
      end
    end, desc = "✅️ Copy error message" },
    { "<leader>ee", vim.diagnostic.open_float, desc = "✅️ Show current error" },

    -- ❓️ Search group
    { "<leader>s", group = "❓️ Search" },
    { "<leader>sr", telescope_cmd("Telescope resume"), desc = "❓️ Search refresh/resume" },
    { "<leader>so", telescope_cmd("Telescope live_grep"), desc = "❓️ Open search editor" },
    { "<leader>ss", telescope_cmd("Telescope grep_string"), desc = "❓️ Search current word" },
    { "<leader>sf", telescope_cmd("Telescope find_files"), desc = "❓️ Search files" },
    { "<leader>sb", telescope_cmd("Telescope buffers"), desc = "❓️ Search buffers" },
    { "<leader>sh", telescope_cmd("Telescope help_tags"), desc = "❓️ Search help" },

    -- ❔️ Search in project
    { "<leader>/", telescope_cmd("Telescope live_grep"), desc = "❔️ Search in project" },

    -- 🧲️ Search symbol in project
    { "<leader>#", telescope_cmd("Telescope lsp_workspace_symbols"), desc = "🧲️ Search symbol in project" },

    -- 🥎 Window group
    { "<leader>w", group = "🥎 Window" },
    { "<leader>wp", "<cmd>lua vim.api.nvim_buf_set_option(0, 'buflisted', false)<cr>", desc = "️🥎 Pin editor" },
    { "<leader>wu", "<cmd>lua vim.api.nvim_buf_set_option(0, 'buflisted', true)<cr>", desc = "️🥎 Unpin editor" },
    { "<leader>wC", "<cmd>%bd|e#<cr>", desc = "️🥎 Close all windows" },
    { "<leader>wz", "<cmd>only<cr>", desc = "️🥎 Toggle max editor group" },
    { "<leader>wo", "<cmd>only<cr>", desc = "️🥎 Close other editors" },
    { "<leader>wl", "<cmd>vsplit<cr>", desc = "️ Copy to right group" },
    { "<leader>wh", "<cmd>vsplit<cr><C-w>H", desc = "️ Copy to left group" },
    { "<leader>w1", "<cmd>1wincmd w<cr>", desc = "️ Go to window 1" },
    { "<leader>w2", "<cmd>2wincmd w<cr>", desc = "️ Go to window 2" },
    { "<leader>w3", "<cmd>3wincmd w<cr>", desc = "️ Go to window 3" },
    { "<leader>w4", "<cmd>4wincmd w<cr>", desc = "️ Go to window 4" },
    { "<leader>wv", "<cmd>vsplit<cr>", desc = "️ Vertical split" },
    { "<leader>ws", "<cmd>split<cr>", desc = "️ Horizontal split" },

    -- Layout shortcuts
    { "<leader>1", "<cmd>only<cr>", desc = "️1️⃣ Single layout" },
    { "<leader>2", "<cmd>only<cr><cmd>vsplit<cr>", desc = "️2️⃣ 2 cols layout" },
    { "<leader>3", "<cmd>only<cr><cmd>vsplit<cr><cmd>vsplit<cr>", desc = "️3️⃣ 3 cols layout" },
    { "<leader>4", "<cmd>only<cr><cmd>vsplit<cr><cmd>vsplit<cr><cmd>vsplit<cr>", desc = "️4️⃣ 4 cols layout" },

    -- 🔫 Move group
    { "<leader>m", group = "🔫 Move" },
    { "<leader>m1", "<cmd>wincmd H<cr>", desc = "Move buffer to 1st window" },
    { "<leader>m2", "<cmd>2wincmd w<cr>", desc = "Move buffer to 2nd window" },
    { "<leader>m3", "<cmd>3wincmd w<cr>", desc = "Move buffer to 3rd window" },
    { "<leader>m4", "<cmd>4wincmd w<cr>", desc = "Move buffer to 4th window" },
    { "<leader>ml", "<cmd>wincmd L<cr>", desc = "Move to last group" },

    -- 📝 Tasks
    { "<leader>t", function() Snacks.terminal() end, desc = "��� Terminal" },

    -- 🎯 Search symbol
    { "<leader>@", telescope_cmd("Telescope lsp_document_symbols"), desc = "🎯 Search symbol" },

    -- ⚡ Quick open
    { "<leader>p", telescope_cmd("Telescope find_files"), desc = "⚡ Quick open" },

    -- 📁 Copy path
    { "<leader>c", function()
      local path = vim.fn.expand("%:.")
      vim.fn.setreg("+", path)
      vim.notify("Copied: " .. path)
    end, desc = "📁 Copy relative path" },
    { "<leader>C", function()
      local path = vim.fn.expand("%:p")
      vim.fn.setreg("+", path)
      vim.notify("Copied: " .. path)
    end, desc = "📁 Copy absolute path" },

    -- = Equal windows
    { "<leader>=", "<C-w>=", desc = "= Equal windows" },

    -- 👀 Zoom
    { "<leader>z", function()
      if vim.g.maximized_window then
        vim.cmd('wincmd =')
        vim.g.maximized_window = false
      else
        vim.cmd('wincmd _ | wincmd |')
        vim.g.maximized_window = true
      end
    end, desc = "💪 Toggle max window" },

    -- 🔑️ Reference group
    { "<leader>R", group = "🔑️ Reference" },
    { "<leader>Rr", telescope_cmd("Telescope lsp_references"), desc = "🔑️ Show references" },
    { "<leader>Ri", telescope_cmd("Telescope lsp_incoming_calls"), desc = "🔑️ Show incoming calls" },
    { "<leader>Ro", telescope_cmd("Telescope lsp_outgoing_calls"), desc = "🔑️ Show outgoing calls" },
    { "<leader>Rf", telescope_cmd("Telescope lsp_references"), desc = "🔑️ Find references" },

    -- 🔖 All bookmarks (via Telescope)
    { "<leader>a", telescope_cmd("Telescope bookmarks list"), desc = "🔖 Bookmarks from all files" },

    -- 🐰 Jump (breadcrumbs/navigation)
    { "<leader>J", function()
      local ok, _ = pcall(require, "dropbar")
      if ok then
        require("dropbar.api").pick()
      end
    end, desc = "🐰 Jump to previous level" },
    { "<leader>j", function()
      local ok, _ = pcall(require, "dropbar")
      if ok then
        require("dropbar.api").pick()
      end
    end, desc = "🐰 Jump to variables" },

    -- 🐳 Focus on sticky top bar
    { "<leader>k", function()
      -- Focus sticky scroll if available
      vim.cmd("normal! zt")
    end, desc = "🐳 Scroll to top" },

    -- 📗 File explorer group
    { "<leader>f", group = "📗 File" },
    { "<leader>ff", telescope_cmd("Telescope find_files"), desc = "📗 Find files" },
    { "<leader>fw", telescope_cmd("Telescope live_grep"), desc = "📗 Word search" },
    { "<leader>fc", telescope_cmd("Telescope current_buffer_fuzzy_find"), desc = "📗 Search current file" },
    { "<leader>fs", telescope_cmd("Telescope find_files"), desc = "📗 Search files" },
    { "<leader>fe", nvim_tree_cmd("NvimTreeToggle"), desc = "📗 File explorer" },
    { "<leader>fr", telescope_cmd("Telescope oldfiles"), desc = "📗 Recent files" },

    -- 🌴 Git group
    { "<leader>g", group = "🌴 Git" },
    { "<leader>gc", function()
      -- Close all git diff editors
      vim.cmd("tabdo windo if &diff | q | endif")
    end, desc = "🌴 Close all git diff editors" },
    { "<leader>gs", telescope_cmd("Telescope git_status"), desc = "🌴 Git status" },
    { "<leader>gd", "<cmd>Gitsigns diffthis<cr>", desc = "🌴 Show diff" },
    { "<leader>gn", "<cmd>Gitsigns next_hunk<cr>", desc = "🌴 Next change" },
    { "<leader>gp", "<cmd>Gitsigns prev_hunk<cr>", desc = "🌴 Previous change" },
    { "<leader>go", "<cmd>Gitsigns diffthis<cr>", desc = "🌴 Open changes" },
    { "<leader>gO", "<cmd>edit %<cr>", desc = "🌴 Open file" },
    { "<leader>gb", telescope_cmd("Telescope git_branches"), desc = "🌴 Git branches" },
    { "<leader>gl", telescope_cmd("Telescope git_commits"), desc = "🌴 Git log" },
    { "<leader>gB", "<cmd>Gitsigns blame_line<cr>", desc = "🌴 Git blame line" },

    -- ✳️ Gitlens group
    { "<leader>l", group = "✳️ Gitlens" },
    { "<leader>lP", "<cmd>Gitsigns diffthis HEAD~1<cr>", desc = "✳️ Diff with previous" },
    { "<leader>lb", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "✳️ Toggle file blame" },
    { "<leader>lh", function()
      -- Toggle heatmap if available
      vim.notify("Heatmap toggle")
    end, desc = "✳️ Toggle file heatmap" },
    { "<leader>lc", "<cmd>Gitsigns diffthis<cr>", desc = "✳️ Compare working tree" },
  })
end

-- Auto setup on require
setup()
