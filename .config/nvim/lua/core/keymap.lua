vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap
local autocmd = vim.api.nvim_create_autocmd

-- general
keymap("n","<Y>","y$",opts)
keymap("n","<J>","mzJ`z",opts)
keymap("n","<leader><leader>","<c-^>",opts)
keymap("n","<leader>gs",":G<CR>",opts)

-- autocompile
autocmd("FileType", { pattern = "python", 
	callback = function()
		vim.api.nvim_buf_set_keymap(0,"n","<C-k>",":split<CR>:te python3 '%'<CR>i",opts)
	end})
