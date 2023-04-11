local null_ls = require "null-ls"
local b = null_ls.builtins
local format = null_ls.builtins.formatting
local sources = {
    -- b.formatting.prettier,
    format.prettier,
    format.stylua,
    -- cpp
    format.clang_format,
}

null_ls.setup {
    debug = true,
    sources = sources,
}
