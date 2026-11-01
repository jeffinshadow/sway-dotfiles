" ~/.vimrc — Shadow Materia
set nocompatible
syntax on
filetype plugin indent on
set termguicolors
colorscheme shadow-materia

set number
set cursorline
set mouse=a
set clipboard=unnamedplus     " y/p usam o clipboard do sistema (wl-clipboard)
set encoding=utf-8
set ignorecase smartcase incsearch hlsearch
set expandtab shiftwidth=4 tabstop=4 softtabstop=4
set scrolloff=5
set laststatus=2
set wildmenu
set backspace=indent,eol,start
set undofile undodir=~/.cache/vim/undo
silent! call mkdir(expand('~/.cache/vim/undo'), 'p')
