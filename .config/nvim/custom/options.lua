-- lua/custom/options

local opt = vim.opt

opt.termguicolors = true

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

-- Change blankline context character
vim.g.indent_blankline_context_char = "│"

-- Set utf8 as standard encoding and en_US as the standard language
opt.encoding = "utf8"
-- Use Unix as the standard file type
opt.ffs = "unix,dos,mac"

-- Autosave when navigating between buffers
opt.autowrite = false
-- set.to auto read when a file is changes from outside
opt.autoread = true
-- Set.how many lines of history vim has to remember
opt.history = 1000
-- Disable folding
opt.foldenable = false
-- Show line numbers
opt.number = true
-- Turn on the wild menu
opt.wildmenu = true
-- Always show current postion
opt.ruler = false
-- Enable cursorline
opt.cursorline = false
opt.cursorcolumn = false
opt.foldcolumn = "0"
-- configure backspace so it acts as it should act
opt.backspace = "eol,start,indent"
-- Ignore the case when the search pattern is all lowercase.
opt.ignorecase = true
opt.smartcase = true
-- For regular expressions turn magic on
opt.magic = true
-- Show matching brackets when text indicator is over them
opt.showmatch = true
-- How many tenths of a second to blink when matching brackets
opt.mat = 2
-- Never (0) / always (2) show tabline
opt.showtabline = 0
-- hide (0),  show always (2) or (3) global statusline
opt.laststatus = 3
opt.cmdheight = 0
-- hide/show visible characters
opt.list = false
opt.listchars = {
    eol = "↴",
    tab = "▸ ",
    trail = "·",
    extends = ">",
    precedes = "<",
    space = "·",
}
opt.fillchars = {
    diff = " ", -- ╱ ░
    eob = " ",
    horiz = "━",
    horizup = "┻",
    horizdown = "┳",
    vert = "┃",
    vertleft = "┫",
    vertright = "┣",
    verthoriz = "╋",
}

-- Recommend for vgit
opt.incsearch = false

-- No annoying sound on errors
opt.errorbells = false
opt.visualbell = false
opt.tm = 500
opt.completeopt = "menu,menuone,noselect"
-- Tab set to four spaces
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smarttab = true
-- linebreak on 500 characters
opt.lbr = true
opt.tw = 500
-- Auto indent
opt.ai = true
-- Smart indent
opt.si = true
-- Disable line wrapping
opt.wrap = false
-- Keep lines below cursor when scrolling
opt.scrolloff = 2
opt.sidescrolloff = 5
-- Don't use temp files
opt.backup = false
opt.wb = false
opt.swapfile = false
-- Insert mode completion setting
opt.completeopt = { "menu", "menuone", "noselect" }
