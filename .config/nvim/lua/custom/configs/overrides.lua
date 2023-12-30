-- overriding default plugin configs!

local M = {}

M.treesitter = {
    ensure_installed = {
        "vim",
        "html",
        "css",
        "javascript",
        "json",
        "toml",
        "c",
        "markdown",
        "python",
        "cpp",
        "rust",
        "bash",
        "lua",
        "typescript",
    },
}

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

M.mason = {
    ensure_installed = {
        -- lua stuff
        "lua-language-server",
		"stylua",
        -- python
        "pyright",
        -- web dev
        "css-lsp",
        "html-lsp",
        "prettier",
        "json-lsp",
        -- shell
        "bash-language-server",
        -- C
        "clangd",
        "clang-format",
    },
}

return M
