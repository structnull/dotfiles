local overrides = require "configs.overrides"

return {

  ----------------------------------------- default plugins ------------------------------------------

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        -- format & linting
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
          require "configs.null-ls"
        end,
      },
    },
    config = function()
      require "nvchad.configs.lspconfig"
      require "configs.lspconfig"
    end,
  },

  --------------------------------------------- custom plugins ----------------------------------------------
  {
    "mrcjkb/rustaceanvim",
    version = "^4", -- Recommended
    lazy = false, -- This plugin is already lazy
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
  {
    "eandrju/cellular-automaton.nvim",
    lazy = false,
  },
  { "nvzone/volt", lazy = true },
  { "nvzone/menu", lazy = true },
}
