local null_ls = require "null-ls"
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

local notify = vim.notify
vim.notify = function(msg, ...)
	if msg:match("warning: multiple different client offset_encodings") then
		return
	end
	notify(msg, ...)
end
