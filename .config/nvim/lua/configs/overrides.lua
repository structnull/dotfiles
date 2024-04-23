-- overriding default plugin configs!
local M = {}

M.nvimtree = {
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
}

return M
