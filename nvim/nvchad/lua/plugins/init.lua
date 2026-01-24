return {
  ------------------------------------------------------------
  ------------------------- extension ------------------------
  ------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
      },
      -- These options will be passed to conform.format()
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },

  ------------------------------------------------------------
  ------------------------- extension ------------------------
  ------------------------------------------------------------
  {
    "ojroques/nvim-osc52",
    lazy = false,
    opts = {
      max_length = 0, -- Maximum length of selection (0 for no limit)
      silent = false, -- Disable message on successful copy
      trim = false,   -- Trim surrounding whitespaces before copy
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

  ------------------------------------------------------------
  ------------------------- extension ------------------------
  ------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  ------------------------------------------------------------
  ------------------------- extension ------------------------
  ------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "bash",
      },
    },
  },

  ------------------------------------------------------------
  ------------------------- extension ------------------------
  ------------------------------------------------------------
  {
    "HiPhish/rainbow-delimiters.nvim",
    lazy = false,
    init = function()
      ---@type rainbow_delimiters.config
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
          -- 'RainbowDelimiterRed',
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

  ------------------------------------------------------------
  ------------------------- extension ------------------------
  ------------------------------------------------------------
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

  ------------------------------------------------------------
  ------------------------- nvim-cmp -------------------------
  ------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/vim-vsnip",
      "onsails/lspkind-nvim",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      -- "hrsh7th/cmp-omni",
      -- "hrsh7th/cmp-emoji",
      "hrsh7th/cmp-cmdline",
      -- "quangnguyen30192/cmp-nvim-ultisnips",
      -- "rafamadriz/friendly-snippets",
    },
    config = function()
      local status, cmp = pcall(require, "cmp")
      if not status then
        vim.notify "not found nvim-cmp"
        return
      end
      -- set keymap
      cmp.setup {
        preselect = cmp.PreselectMode.Item,
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        snippet = {
          expand = function(args)
            -- For `vsnip` users.
            vim.fn["vsnip#anonymous"](args.body)
          end,
        },
        sources = cmp.config.sources({ { name = "nvim_lsp" } }, { { name = "buffer" }, { name = "path" } }),
        mapping = {
          ["<Up>"] = cmp.mapping.select_prev_item(),
          ["<Down>"] = cmp.mapping.select_next_item(),
          ["<Tab>"] = cmp.mapping.confirm {
            select = true,
            behavior = cmp.ConfirmBehavior.Replace,
          },
          ["<CR>"] = cmp.mapping.confirm {
            select = true,
            behavior = cmp.ConfirmBehavior.Replace,
          },
        },
      }
    end,
  },

  ------------------------------------------------------------
  ------------------------- extension ------------------------
  ------------------------------------------------------------
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

  ------------------------------------------------------------
  ------------------------- extension ------------------------
  ------------------------------------------------------------
  {
    "FelipeLema/cmp-async-path",
    enabled = false,
  },
  ------------------------------------------------------------
  -------------------------- easymotion ----------------------
  ------------------------------------------------------------
  {
    "Lokaltog/vim-easymotion",
    init = function()
      -- Global settings for EasyMotion
      vim.g.EasyMotion_smartcase = true -- Case-insensitive search when no uppercase characters are present
      vim.g.EasyMotion_do_mapping = 0   -- Disable default EasyMotion mappings to define custom ones
      vim.g.EasyMotion_keys = "abcdefhjkmnoprstuvwxyz"
    end,
    keys = {
      { "r", "<plug>(easymotion-overwin-f)", desc = "Jump to location", mode = "n" },
    },
  },
  ------------------------------------------------------------
  -------------------------- auto-reload----------------------
  ------------------------------------------------------------
  { "djoshea/vim-autoread", lazy = false },
  ------------------------------------------------------------
  ----------------------------- winbar -----------------------
  ------------------------------------------------------------
  {
    "Bekaboo/dropbar.nvim",
    -- optional, but required for fuzzy finder support
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
  ------------------------------------------------------------
  ---------------------------- rainbow -----------------------
  ------------------------------------------------------------
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = function()
      local hooks = require "ibl.hooks"
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#6c3e3e" })    -- 暗红
        vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#6b4f3a" }) -- 暗橙
        vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#6b5e32" }) -- 暗黄
        vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#4f5b34" })  -- 暗绿
        vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#3a4b6b" })   -- 暗蓝
        vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#4d3a6b" }) -- 暗紫
      end)
      return {
        indent = {
          highlight = { "RainbowRed", "RainbowOrange", "RainbowYellow", "RainbowGreen", "RainbowBlue", "RainbowViolet" },
          char = "│", -- 可选：用细线更柔和
        },
        scope = { highlight = "RainbowYellow" },
      }
    end,
  },
  ------------------------------------------------------------
  ------------------------ accelerated -----------------------
  ------------------------------------------------------------
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
        -- when 'enable_deceleration = true', 'deceleration_table = { {200, 3}, {300, 7}, {450, 11}, {600, 15}, {750, 21}, {900, 9999} }'
        deceleration_table = { { 150, 9999 } },
      }
    end,
  },
  ------------------------------------------------------------
  --------------------------- csv ----------------------------
  ------------------------------------------------------------
  {
    "hat0uma/csvview.nvim",
    ---@module "csvview"
    ---@type CsvView.Options
    opts = {
      parser = {
        -- comments = { "#", "//" },
        delimiter = {
          ft = {
            csv = "|",  -- Always use comma for .csv files
            tsv = "\t", -- Always use tab for .tsv files
          },
          fallbacks = { -- Try these delimiters in order for other files
            ",",
            "\t",
            ";",
          },
        },
      },
      view = {
        display_mode = "border",
        header_lnum = 1, -- Use line 1 as header
      },
    },
    keymaps = {
      -- Text objects for selecting fields
      textobject_field_inner = { "if", mode = { "o", "x" } },
      textobject_field_outer = { "af", mode = { "o", "x" } },
    },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
  },

  ------------------------------------------------------------
  ------------------------ markdown --------------------------
  ------------------------------------------------------------
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "Avante" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },

  ------------------------------------------------------------
  -------------------------- blink ---------------------------
  ------------------------------------------------------------
  -- { import = "nvchad.blink.lazyspec" }
}
