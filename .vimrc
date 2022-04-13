call plug#begin('~/.vim/plugged')
    " Better Syntax Support
    Plug 'sheerun/vim-polyglot'
    " File Explorer
    Plug 'scrooloose/NERDTree'
    Plug 'ryanoasis/vim-devicons'
    " Auto pairs for '(' '[' '{'
    Plug 'jiangmiao/auto-pairs'
    " Rich Presence
    Plug 'vimsence/vimsence'
    " AirLine
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    " source $HOME/.vim/themes/airline.vim
    " CSS color
    Plug 'ap/vim-css-color'
    " Surround
    Plug 'tpope/vim-surround'
    " Commentary
    Plug 'tomtom/tcomment_vim'
    " Syntax Check (ale)
    " Plug 'dense-analysis/ale'
    " Theme
    Plug 'bluz71/vim-moonfly-colors'
call plug#end()

" Change cursor shape in different modes
let &t_SI = "\<Esc>[6 q"
let &t_SR = "\<Esc>[4 q"
let &t_EI = "\<Esc>[2 q"

" General Settings
syntax on
filetype plugin on
set nocompatible
set clipboard=unnamedplus
set number relativenumber
set tabstop=4 softtabstop=4
set shiftwidth=4
set noendofline
set nofixendofline
set autoread
set autoindent
set noexpandtab
set nosmarttab
set termguicolors
set smartindent
set cmdheight=1
set ignorecase
set smartcase
set noswapfile
set splitbelow
set splitright
set incsearch
set autowrite
set mouse=a

" Mappings
:map<C-n>    :NERDTree<CR>
nnoremap <C-Left> :tabprevious<CR>
nnoremap <C-Right> :tabnext<CR>
nnoremap <C-q> :qa!<CR>
nnoremap <C-s> :w<CR>
autocmd filetype python nnoremap <buffer> <C-c> :!python3 %<CR>
