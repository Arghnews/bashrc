set nocompatible " required for vundle
filetype off " required for vundle

set rtp+=~/.vim/bundle/Vundle.vim " required for vundle
call vundle#begin() " required for vundle
Plugin 'VundleVim/Vundle.vim' " required for vundle
Plugin 'fatih/vim-go' " go syntax highlighting
Plugin 'fatih/molokai' " nicer go colour scheme
Plugin 'octol/vim-cpp-enhanced-highlight' " C++ syntax highlighting
Plugin 'tikhomirov/vim-glsl' " glsl highlighting
call vundle#end() " required for vundle
filetype plugin indent on " required for vundle

set t_Co=256 " This line is F*****G crucial at least on DCS machines
" go colour according to this color scheme
let g:rehash256 = 1
let g:molokai_original = 1
colorscheme molokai

" C++ class scope highlighting
let g:cpp_class_scope_highlight = 1
" C++ library concepts
let g:cpp_concepts_highlight = 1

" golang syntax settings for vim-go
let g:go_hightlight_functions = 1
let g:go_hightlight_methods= 1
let g:go_hightlight_fields= 1
let g:go_hightlight_types = 1
let g:go_hightlight_operators = 1
"let g:go_hightlight_build_constraints = 1
let g:go_fmt_autosave = 0 " means I get to keep my semi colons on saving :P

set softtabstop=4
set tabstop=4
set expandtab
set shiftwidth=4
set number
set relativenumber
set nohlsearch " turns off search highlighting
set wrap linebreak nolist " wraps whole words onto next line
set whichwrap+=<,>,h,l,[,] " linewrap for cursor

" disables any auto-commenting
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" vulkan highlighting, from ~/.vim/syntax/vulkan1.0.vim
autocmd FileType cpp,c source ~/.vim/syntax/vulkan1.0.vim
autocmd BufNewFile,BufRead *.shader set syntax=glsl
" remap control+c to escape in insert map
" remap shift-k/caps K to just move up, usually I press this by mistake
noremap <s-k> <k>
inoremap <C-c> <esc>
"inoremap jk <esc>
"inoremap kj <esc>
inoremap <Up> <NOP>
inoremap <Down> <NOP>
inoremap <Left> <NOP>
inoremap <Right> <NOP>
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

"
"filetype off
"
"set rtp+=~/.vim/bundle/Vundle.vim
"call vundle#begin()
"Plugin 'VundleVim/Vundle.vim'
"Plugin 'morhetz/gruvbox'
"Plugin 'faith/vim-go'
"call vundle#end()
"let g:gruvbox_contrast_dark='hard'
"let g:gruvbox_termcolors=16
"
"set rtp+=$GOROOT/misc/vim
"filetype plugin indent on
"syntax on
"
"colorscheme gruvbox
"set background=dark
"
"set wrap linebreak nolist
"
"
"
"filetype off
"filetype plugin indent off
"set t_Co=256
"set rtp+=$GOROOT/misc/vim
"filetype plugin indent on
"syntax on
