" This change was made as test user?! Hopefully
"
"set nocompatible " required for vundle
"filetype off " required for vundle
"
"set rtp+=~/.vim/bundle/Vundle.vim " required for vundle
"call vundle#begin() " required for vundle
"Plugin 'VundleVim/Vundle.vim' " required for vundle
"Plugin 'fatih/vim-go' " go syntax highlighting
"Plugin 'fatih/molokai' " nicer go colour scheme
"Plugin 'octol/vim-cpp-enhanced-highlight' " C++ syntax highlighting
"Plugin 'tikhomirov/vim-glsl' " glsl highlighting
"call vundle#end() " required for vundle
filetype plugin indent on " required for vundle
syntax on

" no net on work linux machine so these are commented out
" just place molokai.vim in ~/.vim/syntax (if I remember correctly?)

" although 'export TERM="xterm-256color" >> ~/.bashrc' should be enough
set t_Co=256 " This line is F*****G crucial it seems

colorscheme molokai
let g:molokai_original = 1
let g:rehash256 = 1 " 

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

" sets tab and associated -> call Tab(4)
" first arg is number of spaces for tab
" supply second arg for non-silent

"function Retab!()
  " todo
"endfunction

function! Tab(...)
    let tabw = (a:0 >= 1) ? a:1 : 4
    let loud = (a:0 >= 2) ? a:2 : 1
    if loud
      echom "Settings tab width to" tabw
    endif
    " sets number of columns for tab
    execute "set softtabstop=".tabw
    " show existing tab with 4 spaces
    execute "set tabstop=".tabw
    " '>' results in 4 spaces
    execute "set shiftwidth=".tabw
    " press tab -> 4 spaces
    set expandtab

endfunction

" don't want to print crap on startup
call Tab(4,0)

set number
"set relativenumber " performance killer
set nohlsearch " turns off search highlighting
set wrap linebreak nolist " wraps whole words onto next line
set whichwrap+=<,>,h,l,[,] " linewrap for cursor
set backspace=indent,eol,start " allow backspace past start of insert
set virtualedit=block " can vis block into empty space
set wildmode=longest,list " bash like file opening!

" disables any auto-commenting
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" vulkan highlighting, from ~/.vim/syntax/vulkan1.0.vim
"autocmd FileType cpp,c source ~/.vim/syntax/vulkan1.0.vim
"autocmd BufNewFile,BufRead *.shader set syntax=glsl
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
" ex mode
noremap <Q> <NOP>
" man page
noremap <K> <NOP>

" must be after molokai
" make visual highlighted text more readable - after syntax on
hi Visual term=reverse cterm=reverse guibg=Grey

" type :Pwd to print working dir of file
command! Pwd echo expand("%:p")

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
