local overrides = require "custom.configs.overrides"

return {

    ----------------------------------------- default plugins ------------------------------------------

    {
        "neovim/nvim-lspconfig",
        dependencies = {
            {
                -- format & linting
                "jose-elias-alvarez/null-ls.nvim",
                config = function()
                    require "custom.configs.null-ls"
                end,
            },
        },
        config = function()
            require "plugins.configs.lspconfig"
            require "custom.configs.lspconfig"
        end,
    },

    --------------------------------------------- custom plugins ----------------------------------------------
    -- autoclose tags in html, jsx only
    {
        "christoomey/vim-tmux-navigator",
        lazy = false,
    },
	{
		"eandrju/cellular-automaton.nvim",
		lazy = false,
	},

}
