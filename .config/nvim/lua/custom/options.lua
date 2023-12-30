local opt = vim.opt

-- Enable syntax highlight
vim.cmd "syntax enable"

-- Enable filetype plugins
vim.cmd [[
  filetype on
  filetype plugin on
  filetype indent on
]]

-- Disable folder in diff mode
vim.cmd [[
  set diffopt+=context:99999,foldcolumn:0
]]

vim.g["prettier#autoformat_options"] = "--tab-width 4 --use-tabs"

-- disable swap file
-- opt.swapfile = false
-- Set utf8 as standard encoding and en_US as the standard language
opt.encoding = "utf8"
-- Use Unix as the standard file type
opt.ffs = "unix,dos,mac"
-- Turn on the wild menu
opt.wildmenu = true
-- configure backspace so it acts as it should act
opt.backspace = "eol,start,indent"
-- Ignore the case when the search pattern is all lowercase.
opt.ignorecase = true
opt.smartcase = true
-- For regular expressions turn magic on
opt.magic = true
-- Show matching brackets when text indicator is over them
opt.showmatch = true
-- hide/show visible characters
opt.list = false
-- No annoying sound on errors
opt.errorbells = false
opt.visualbell = false
opt.tm = 500
opt.completeopt = "menu,menuone,noselect"
-- Tab set to four
opt.tabstop = 4
opt.shiftwidth = 4
-- opt.softtabstop = 4
opt.expandtab = false
opt.smarttab = true
-- linebreak on 200 characters
opt.lbr = true
opt.tw = 200
-- Auto indent
opt.ai = true
-- Smart indent
opt.si = true
-- Disable line wrapping
opt.wrap = false
