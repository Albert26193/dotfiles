-----------------------------------------------------------
-- Plugin manager configuration
-----------------------------------------------------------

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Use a protected call
local status_ok, lazy = pcall(require, 'lazy')
if not status_ok then
  vim.notify("Failed to load lazy.nvim: " .. tostring(lazy), vim.log.levels.ERROR)
  return
end

-- Setup plugins
lazy.setup({
  defaults = {
    lazy = false,
    version = nil,
  },

  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",

  git = {
    log = { "-8" },
    timeout = 120,
    url_format = "https://github.com/%s.git",
  },

  ui = {
    size = { width = 0.8, height = 0.8 },
    wrap = true,
    border = "rounded",
    icons = {
      cmd = " ",
      config = "",
      event = " ",
      ft = " ",
      init = " ",
      keys = " ",
      plugin = " ",
      runtime = " ",
      require = "󰢱 ",
      source = " ",
      start = " ",
      task = "✔ ",
      lazy = "󰒲 ",
    },
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "2html_plugin",
        "tohtml",
        "getscript",
        "getscriptPlugin",
        "gzip",
        "logipat",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
        "matchit",
        "tar",
        "tarPlugin",
        "rrhelper",
        "spellfile_plugin",
        "vimball",
        "vimballPlugin",
        "zip",
        "zipPlugin",
        "tutor",
        "rplugin",
        "syntax",
        "synmenu",
        "optwin",
        "compiler",
        "bugreport",
        "ftplugin",
      },
    },
  },

  checker = {
    enabled = false,
  },

  change_detection = {
    enabled = true,
    notify = true,
  },

  -----------------------------------------------------------
  -- Plugin specifications
  -----------------------------------------------------------
  spec = {
    -- Which-Key: Keybinding hints
    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
      end,
      config = function()
        require("which-key").setup()
      end,
    },

    -- Colorscheme
    {
      "Shatur/neovim-ayu",
      config = function()
        require("ayu").setup({
          mirage = true,
          terminal = false,
          overrides = {
            LineNr                  = { fg = "#537071" },
            CursorLineNr            = { fg = "#39bae6", bold = true },
            ErrorMsg                = { bg = "#fa1010", fg = "#ffffff" },
            EasyMotionShade         = { fg = "#3c4b4c" },
            EasyMotionTarget        = { fg = "#00ff66" },
            EasyMotionTarget2First  = { fg = "#00ff66", bg = "NONE" },
            EasyMotionTarget2Second = { fg = "#ffff66", bg = "NONE" },
            Visual                  = { bg = "#3e4b59", fg = "NONE" },
            WinSeparator            = { fg = "#39bae6", bg = "NONE" }, -- 窗口分隔线
          },
        })
        vim.cmd.colorscheme("ayu")
      end,
    },
    -- Treesitter
    {
      'nvim-treesitter/nvim-treesitter',
      tag = 'v0.10.0',
      build = ':TSUpdate',
      event = { 'BufReadPost', 'BufNewFile' },
      opts = {
        ensure_installed = {
          'python', 'cpp', 'c', 'proto', 'dockerfile',
          'starlark', 'bash', 'javascript', 'lua', 'json'
        },
        sync_install = false,
        auto_install = true,
        ignore_install = {},
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = false },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<CR>',
            node_incremental = '<CR>',
            scope_incremental = '<TAB>',
            node_decremental = '<BS>',
          },
        },
      },
    },

    -- Autocompletion
    {
      'hrsh7th/nvim-cmp',
      event = 'InsertEnter',
      dependencies = {
        'L3MON4D3/LuaSnip',
        'saadparwaiz1/cmp_luasnip',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-cmdline',
        'onsails/lspkind-nvim',
      },
      config = function()
        local cmp = require('cmp')
        local luasnip = require('luasnip')
        local lspkind = require('lspkind')

        cmp.setup({
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ['<C-b>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<C-e>'] = cmp.mapping.abort(),
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
            ['<Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { 'i', 's' }),
            ['<S-Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { 'i', 's' }),
          }),
          sources = cmp.config.sources({
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
            { name = 'path' },
          }, {
            { name = 'buffer' },
          }),
          formatting = {
            format = lspkind.cmp_format({
              mode = 'symbol_text',
              maxwidth = 50,
              ellipsis_char = '...',
            })
          },
          window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered(),
          },
          experimental = {
            ghost_text = true,
          },
        })

        cmp.setup.cmdline({ '/', '?' }, {
          mapping = cmp.mapping.preset.cmdline(),
          sources = { { name = 'buffer' } }
        })

        cmp.setup.cmdline(':', {
          mapping = cmp.mapping.preset.cmdline(),
          sources = cmp.config.sources({
            { name = 'path' }
          }, {
            { name = 'cmdline' }
          })
        })
      end,
    },

    {
      "hrsh7th/cmp-cmdline",
      event = "CmdlineEnter",
      config = function()
        local cmp = require "cmp"
        cmp.setup.cmdline("/", {
          sources = { { name = "buffer" } },
          mapping = cmp.mapping.preset.cmdline {
            ["<Down>"] = {
              c = function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                else
                  fallback()
                end
              end,
            },
            ["<Up>"] = {
              c = function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                else
                  fallback()
                end
              end,
            },
            ["<Tab>"] = {
              c = function(fallback)
                if cmp.visible() then
                  cmp.confirm {
                    select = true,
                    behavior = cmp.ConfirmBehavior.Replace,
                  }
                else
                  fallback()
                end
              end,
            },
          },
        })
        cmp.setup.cmdline(":", {
          sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
          matching = { disallow_symbol_nonprefix_matching = false },
          mapping = cmp.mapping.preset.cmdline {
            ["<Down>"] = {
              c = function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                else
                  fallback()
                end
              end,
            },
            ["<Up>"] = {
              c = function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                else
                  fallback()
                end
              end,
            },
            ["<Tab>"] = {
              c = function(fallback)
                if cmp.visible() then
                  cmp.confirm {
                    select = true,
                    behavior = cmp.ConfirmBehavior.Replace,
                  }
                else
                  fallback()
                end
              end,
            },
          },
        })
      end,
    },


    -- Mason: LSP installer
    {
      'williamboman/mason.nvim',
      cmd = { 'Mason', 'MasonInstall', 'MasonUninstall', 'MasonUpdate' },
      opts = {
        ui = {
          border = 'rounded',
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        },
        max_concurrent_installers = 4,
      },
    },
    {
      'williamboman/mason-lspconfig.nvim',
      event = { 'BufReadPre', 'BufNewFile' },
      dependencies = {
        'williamboman/mason.nvim',
        'neovim/nvim-lspconfig',
      },
      opts = {
        ensure_installed = {
          'lua_ls', 'pyright', 'bashls', 'ts_ls',
          'html', 'cssls', 'jsonls',
        },
        automatic_installation = true,
      },
    },

    -- LSP
    {
      'neovim/nvim-lspconfig',
      lazy = false,
      dependencies = {
        'williamboman/mason-lspconfig.nvim',
      },
    },
    {
      'hrsh7th/cmp-nvim-lsp',
      lazy = false,
    },

    -- UI: Icons
    {
      'nvim-tree/nvim-web-devicons',
      lazy = true,
    },

    -- File Explorer: NvimTree
    {
      "nvim-tree/nvim-tree.lua",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus" },
      opts = {
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false,
        },
        update_focused_file = {
          enable = true,
          update_cwd = false,
        },
      },
    },
    -- UI: Indent guides
    {
      'lukas-reineke/indent-blankline.nvim',
      main = 'ibl',
      lazy = false,
      opts = function()
        local hooks = require "ibl.hooks"
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
          vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#6c3e3e" })
          vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#6b4f3a" })
          vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#6b5e32" })
          vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#4f5b34" })
          vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#3a4b6b" })
          vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#4d3a6b" })
        end)
        return {
          indent = {
            highlight = { "RainbowRed", "RainbowOrange", "RainbowYellow", "RainbowGreen", "RainbowBlue", "RainbowViolet" },
            char = "│",
          },
          scope = { highlight = "RainbowYellow" },
        }
      end,
    },

    -- UI: Statusline
    {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      lazy = false,
    },

    -- UI: Bufferline (tab bar at top)
    {
      'akinsho/bufferline.nvim',
      version = "*",
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      lazy = false,
      opts = {
        options = {
          mode = "buffers",
          themable = true,
          numbers = "none",
          close_command = "bdelete! %d",
          right_mouse_command = "bdelete! %d",
          left_mouse_command = "buffer %d",
          middle_mouse_command = nil,
          indicator = {
            icon = '▎',
            style = 'icon',
          },
          buffer_close_icon = '󰅖',
          modified_icon = '●',
          close_icon = '',
          left_trunc_marker = '',
          right_trunc_marker = '',
          max_name_length = 18,
          max_prefix_length = 15,
          truncate_names = true,
          tab_size = 18,
          diagnostics = "nvim_lsp",
          diagnostics_update_in_insert = false,
          offsets = {
            {
              filetype = "NvimTree",
              text = "File Explorer",
              text_align = "center",
              separator = true,
            },
          },
          color_icons = true,
          show_buffer_icons = true,
          show_buffer_close_icons = true,
          show_close_icon = true,
          show_tab_indicators = true,
          show_duplicate_prefix = true,
          persist_buffer_sort = true,
          separator_style = "thin",
          enforce_regular_tabs = false,
          always_show_bufferline = true,
          hover = {
            enabled = true,
            delay = 200,
            reveal = { 'close' },
          },
          sort_by = 'insert_after_current',
        },
      },
    },
    -- UI: Git signs
    {
      'lewis6991/gitsigns.nvim',
      lazy = false,
    },

    -- UI: Autopairs
    {
      'windwp/nvim-autopairs',
      lazy = false,
    },

    ------------------------------------------------------------
    -------------------------- auto-reload----------------------
    ------------------------------------------------------------
    { "djoshea/vim-autoread", lazy = false },

    -- EasyMotion
    {
      "Lokaltog/vim-easymotion",
      init = function()
        vim.g.EasyMotion_smartcase = true
        vim.g.EasyMotion_do_mapping = 0
        vim.g.EasyMotion_keys = "abcdefhjkmnoprstuvwxyz"
      end,
      keys = {
        { "r", "<plug>(easymotion-overwin-f)", desc = "Jump to location", mode = "n" },
      },
    },

    -- Accelerated JK
    {
      "rainbowhxch/accelerated-jk.nvim",
      lazy = false,
      config = function()
        require("accelerated-jk").setup {
          mode = "time_driven",
          enable_deceleration = false,
          acceleration_motions = {},
          acceleration_limit = 150,
          acceleration_table = { 2, 5, 8, 11, 12, 13, 15, 17 },
          deceleration_table = { { 150, 9999 } },
        }
      end,
    },

    -- Formatting
    {
      "stevearc/conform.nvim",
      event = "BufWritePre",
      opts = {
        formatters_by_ft = {
          lua = { "stylua" },
          sh = { "shfmt" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      },
    },

    -- Winbar
    {
      "Bekaboo/dropbar.nvim",
      dependencies = {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      lazy = false,
      config = function()
        local dropbar_api = require "dropbar.api"
        vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
        vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
        vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
      end,
    },

    -- Rainbow Delimiters
    {
      "HiPhish/rainbow-delimiters.nvim",
      lazy = false,
      init = function()
        vim.g.rainbow_delimiters = {
          strategy = {
            [""] = "rainbow-delimiters.strategy.global",
            vim = "rainbow-delimiters.strategy.local",
          },
          query = {
            [""] = "rainbow-delimiters",
            lua = "rainbow-blocks",
          },
          priority = {
            [""] = 110,
            lua = 210,
          },
          highlight = {
            "RainbowDelimiterYellow",
            "RainbowDelimiterBlue",
            "RainbowDelimiterOrange",
            "RainbowDelimiterGreen",
            "RainbowDelimiterViolet",
            "RainbowDelimiterCyan",
          },
        }
      end,
    },

    -- CSV View
    {
      "hat0uma/csvview.nvim",
      opts = {
        parser = {
          delimiter = {
            ft = {
              csv = "|",
              tsv = "\t",
            },
            fallbacks = { ",", "\t", ";" },
          },
        },
        view = {
          display_mode = "border",
          header_lnum = 1,
        },
      },
      cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    },

    -- Markdown Render
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown", "Avante" },
      dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
      opts = {},
    },

    -- OSC52 Clipboard
    {
      "ojroques/nvim-osc52",
      lazy = false,
      opts = {
        max_length = 0,
        silent = false,
        trim = false,
      },
      init = function()
        function copy()
          if vim.v.event.operator == "y" and vim.v.event.regname == "+" then
            require("osc52").copy_register "+"
          end
        end

        vim.api.nvim_create_autocmd("TextYankPost", { callback = copy })
      end,
    },

    -- Log Highlight
    {
      "fei6409/log-highlight.nvim",
      lazy = false,
      event = { "BufRead" },
      config = function()
        require("log-highlight").setup {
          extension = { "log", "error", "err", "0", "warnings" },
          pattern = { "*.err", "*.log", "*.err", "*.0", "*.warnings" },
          keyword = {
            error = { "ERROR", "error1" },
          },
        }
      end,
      opts = {
        keyword = {
          error = { "ERROR", "error1" },
        },
      },
    },

    -- Telescope: Fuzzy finder
    {
      "nvim-telescope/telescope.nvim",
      branch = "0.1.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        {
          "nvim-telescope/telescope-fzf-native.nvim",
          build = "make",
        },
      },
      cmd = "Telescope",
      keys = {
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
        { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Live grep" },
        { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers" },
        { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "Help tags" },
      },
      config = function()
        local telescope = require("telescope")
        telescope.setup({
          defaults = {
            prompt_prefix = " ",
            selection_caret = " ",
            path_display = { "truncate" },
            file_ignore_patterns = { "node_modules", ".git/", "%.lock" },
            mappings = {
              i = {
                ["<C-j>"] = "move_selection_next",
                ["<C-k>"] = "move_selection_previous",
                ["<C-c>"] = "close",
              },
            },
          },
          pickers = {
            find_files = {
              hidden = true,
            },
          },
          extensions = {
            fzf = {
              fuzzy = true,
              override_generic_sorter = true,
              override_file_sorter = true,
              case_mode = "smart_case",
            },
          },
        })
        pcall(telescope.load_extension, "fzf")
      end,
    },

    -- Yazi: File manager
    {
      "mikavilpas/yazi.nvim",
      event = "VeryLazy",
      keys = {
        { "<leader>-",  "<cmd>Yazi<cr>",        desc = "Open yazi at current file" },
        { "<leader>cw", "<cmd>Yazi cwd<cr>",    desc = "Open yazi in working directory" },
        { "<c-up>",     "<cmd>Yazi toggle<cr>", desc = "Resume the last yazi session" },
      },
      opts = {
        open_for_directories = false,
        keymaps = {
          show_help = "<f1>",
        },
      },
    },

    -- Bookmarks: Mark and jump
    {
      "tomasky/bookmarks.nvim",
      event = "VimEnter",
      dependencies = { "nvim-telescope/telescope.nvim" },
      config = function()
        require("bookmarks").setup({
          save_file = vim.fn.expand("$HOME/.bookmarks"),
          keywords = {
            ["@t"] = "☑️ ", -- mark annotation startswith @t ,bindpicker_color = green
            ["@w"] = "⚠️ ", -- bindpicker_color = red
            ["@f"] = "⛏ ", -- bindpicker_color = blue
            ["@n"] = " ", -- bindpicker_color = yellow
          },
          on_attach = function(bufnr)
            local bm = require("bookmarks")
            local map = vim.keymap.set
            map("n", "mm", bm.bookmark_toggle, { desc = "Toggle bookmark", buffer = bufnr })
            map("n", "mi", bm.bookmark_ann, { desc = "Add annotation", buffer = bufnr })
            map("n", "mc", bm.bookmark_clean, { desc = "Clean bookmarks", buffer = bufnr })
            map("n", "mn", bm.bookmark_next, { desc = "Next bookmark", buffer = bufnr })
            map("n", "mp", bm.bookmark_prev, { desc = "Prev bookmark", buffer = bufnr })
            map("n", "ml", bm.bookmark_list, { desc = "List bookmarks", buffer = bufnr })
          end,
        })
        -- Load telescope extension
        pcall(function()
          require("telescope").load_extension("bookmarks")
        end)
      end,
    },
    -- Snacks.nvim: Utility library
    {
      "folke/snacks.nvim",
      lazy = false,
      opts = {
        input = {},
        picker = {},
        terminal = {
          win = {
            position = "right",
            width = 0.25, -- 1/4 of the screen
          },
        },
      },
      keys = {
        {
          "<C-q>",
          function()
            local wins = vim.api.nvim_tabpage_list_wins(0)
            local items = {}
            for i, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              local name = vim.api.nvim_buf_get_name(buf)
              local ft = vim.bo[buf].filetype
              local display_name = name ~= "" and vim.fn.fnamemodify(name, ":t") or ("[" .. ft .. "]")
              table.insert(items, {
                text = i .. ": " .. display_name,
                idx = i,
                win = win,
              })
            end
            Snacks.picker.select(items, {
              prompt = "Select Window",
            }, function(item)
              if item then
                vim.api.nvim_set_current_win(item.win)
              end
            end)
          end,
          desc = "Pick window (tmux style)",
        },
      },
    },
    -- opencode
    {
      "NickvanDyke/opencode.nvim",
      dependencies = { "folke/snacks.nvim" },
      config = function()
        ---@type opencode.Opts
        vim.g.opencode_opts = {
          enabled = "snacks",
          snacks = {
          }
        }

        -- Required for `opts.events.reload`.
        vim.o.autoread = true
        -- Recommended/example keymaps.
        vim.keymap.set({ "n", "x" }, "<M-l>", function() require("opencode").ask("@this: ", { submit = true }) end,
          { desc = "Ask opencode…" })
        vim.keymap.set({ "n", "x" }, "<S-M-l>", function() require("opencode").select() end,
          { desc = "Execute opencode action…" })
        vim.keymap.set({ "n", "t" }, "<M-b>", function() require("opencode").toggle() end, { desc = "Toggle opencode" })
        vim.keymap.set({ "n", "x" }, "<M-i>", function() return require("opencode").operator("@this ") end,
          { desc = "Add range to opencode", expr = true })
        -- vim.keymap.set({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end,
        --   { desc = "Add range to opencode", expr = true })
        -- vim.keymap.set("n", "goo", function() return require("opencode").operator("@this ") .. "_" end,
        --   { desc = "Add line to opencode", expr = true })

        vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end,
          { desc = "Scroll opencode up" })
        vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end,
          { desc = "Scroll opencode down" })

        -- You may want these if you stick with the opinionated "<C-a>" and "<C-x>" above — otherwise consider "<leader>o…".
        vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
        vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
      end,
    }
  },

})
