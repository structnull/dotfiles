return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    config = function()
      require "configs.conform"
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    opts = {
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    },
    dependencies = {
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      filters = {
        dotfiles = true,
        custom = { "node_modules" },
      },

      git = {
        enable = true,
      },

      renderer = {
        highlight_git = true,
        icons = {
          show = {
            git = true,
          },
        },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "javascript",
        "dart",
        "hyprlang",
        "json",
        "toml",
        "c",
        "markdown",
        "python",
        "cpp",
        "rust",
        "bash",
        "typescript",
      },
    },
  },

  {
    "NvChad/base46",
    branch = "v3.0",
  },

  {
    "NvChad/ui",
    branch = "v3.0",
  },
  { import = "nvchad.blink.lazyspec" },

  --------------------------------------------- custom plugins ----------------------------------------------
  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>pp",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>pb",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>ps",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
    },
  },

  {
    "nvim-flutter/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = true,
    opts = {
      lsp = {
        on_attach = function(_, bufnr)
          local map = vim.keymap.set
          local opts = { buffer = bufnr }

          map("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
          map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
          map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
          map("n", "gs", "<cmd>Telescope lsp_document_symbols<CR>", opts)
          map("n", "gS", "<cmd>Telescope lsp_workspace_symbols<CR>", opts)
          map("n", "gy", "<cmd>Telescope lsp_type_definitions<CR>", opts)
        end,
      },
    },
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
  {
    "eandrju/cellular-automaton.nvim",
    lazy = false,
  },
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  { "nvzone/volt", lazy = true },
  { "nvzone/menu", lazy = true },
}
