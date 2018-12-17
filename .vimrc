
" On new install TODO:
" https://github.com/ggreer/the_silver_searcher
"   sudo apt install silversearcher-ag
" https://github.com/sharkdp/fd
"   sudo dpkg -i fd_7.2.0_amd64.deb # adapt version number and architecture

" Download and install vim-plug if not there and install plugins
if empty(glob('~/.vim/autoload/plug.vim'))
      silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
          \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
    endif

" Vim plug - https://github.com/junegunn/vim-plug
call plug#begin()

Plug 'tpope/vim-sensible' " Sensible defaults
" Install fzf to ~ if not there
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim' " fzf vim bindings
Plug 'fatih/molokai' " Nicer colour scheme
Plug 'octol/vim-cpp-enhanced-highlight' " C++ syntax highlighting
Plug 'ntpeters/vim-better-whitespace' " Trailing whitespace stripper/highlighter
Plug 'tpope/vim-commentary' " Commenting
Plug 'tpope/vim-unimpaired' " Awesome shortcuts

Plug 'itchyny/vim-cursorword' " Highlights current word - on trial
Plug 'scrooloose/nerdtree' " , { 'on':  'NERDTreeToggle' } - Dir browser - on trial

Plug 'pangloss/vim-javascript' " Javascript highlighting for react tutorial

Plug 'ludovicchabant/vim-gutentags' " Better tag management etc
Plug 'majutsushi/tagbar' " Sidebar for ctags based class overview

"Plug 'tpope/vim-fugitive' " Git plugin
"Plug 'w0rp/ale' " Language client
"Plug 'MaskRay/ccls' " Language server for C/C++ based on cquery
"Plug 'mbbill/undotree' " Undo tree visualised

call plug#end() " Calls 'filetype plugin indent on' and 'syntax enable'

" octol/vim-cpp-enhanced-highlight
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_experimental_simple_template_highlight = 1
"let g:cpp_experimental_template_highlight = 1
let g:cpp_concepts_highlight = 1

" tpope/vim-commentary
" use gcc to comment and gcgc to uncomment
" can also use gc5j to toggle commenting on next 5 lines
" gcu uncomments

" scrooloose/nerdtree
nnoremap <c-n> :NERDTreeToggle<CR>
"let NERDTreeToggle = "<s-k>"

" https://stackoverflow.com/a/15378816
" As long as TERM is correctly set in .bashrc to xterm-256color or
" screen-256color this shouldn't be necessary
"set t_Co=256 " This line is F*****G crucial it seems on DCS machines

colorscheme molokai
"let g:molokai_original = 1
"let g:rehash256 = 1
set background=dark
" Must be after colorscheme - make highlighted text white
hi Visual term=reverse cterm=reverse guibg=White

" Sets (soft)tab width
" Sets effective tab width -
" First arg is number of spaces for tab, supply second arg for loud
function! Tab(...)
    let tabw = (a:0 >= 1) ? a:1 : 4
    let loud = (a:0 >= 2) ? a:2 : 1
    if loud
      echom "Settings tab width to" tabw
    endif
    " Sets number of columns for tab
    execute "setlocal softtabstop=".tabw
    " Width of tab shown as number of spaces
    execute "setlocal tabstop=".tabw
    " Size of indent in spaces
    execute "setlocal shiftwidth=".tabw
    " Tab key -> 4 spaces
    setlocal expandtab
    " Not exactly sure if I want this in my life but it sounds good?
    "setlocal smarttab
    "setlocal autoindent
endfunction

set number " Absolute line numbering
set nohlsearch " Turns off search highlighting
set wrap linebreak nolist " Wraps whole words onto next line
set whichwrap+=<,>,h,l,[,] " Linewrap for cursor
set virtualedit=block " Visual block into empty space
set wildmenu " Command line completion - <Tab>/<S-Tab> or <C-d> to go to full menu
set wildignorecase " On trial
set wildmode=list:longest,full " Nicer command line completion

" Disable accidental ZZ quit rather than centre screen
nnoremap <s-z> <NOP>
" Remap control c to escape
inoremap <C-c> <esc>
nnoremap <C-c> <esc>

" Type :Pwd to print working dir of file
command! Pwd echo expand("%:p")
" Source ~/.vimrc
command! Source source ~/.vimrc

" Enables cursor line so can see lineup on F8
function! Cursorcross()
    set cursorline!
    set cursorcolumn!
endfunction
nnoremap <F8> :call Cursorcross()<CR>
inoremap <F8> <C-o>:call Cursorcross()<CR>

" See ":help formatoptins" and ":help fo-table"
set formatoptions=crqoj

" So ":messages" cmd functions like normal vim and can use for plugin debug
set shortmess-=F

" Default set to tab width of 4 and no spaces
call Tab(4, 0)

" Cpp and python settings in ~/.vim/after/ftplugin/cpp.vim
augroup Filetypes
    autocmd!

    " Makefile.inc is recognised as a Makefile by vim
    autocmd BufNewFile,BufRead Makefile,Makefile.* set filetype=make
    " Real tabs, and they appear as 8 spaces wide
    autocmd FileType make set noexpandtab shiftwidth=8 softtabstop=0 tabstop=8

    " Default to 4 tabs if no filetype detected - not needed with default to 4
    "au BufNewFile,BufRead * if &ft == '' | call Tab(4) | endif
augroup END

" Fix syntax highlighting from start of file
nnoremap <F12> <Esc>:syntax sync fromstart<CR>
inoremap <F12> <C-o>:syntax sync fromstart<CR>

highlight ColorColumn ctermbg=darkgray

set showcmd " Remove if slow - show cmd string in bottom right
set showmode " Enable status line saying in insert or visual mode

" Jumps to matching bracket on typing for sec*0.1*matchtime
set showmatch
set matchtime=10

" Stolen from http://got-ravings.blogspot.com/2008/08/vim-pr0n-making-statuslines-that-own.html
" Haven't yet bothered to understand it
set statusline=   " clear the statusline for when vimrc is reloaded
set statusline+=%-3.3n\                      " buffer number
set statusline+=%f\                          " file name
set statusline+=%h%m%r%w                     " flags
set statusline+=[%{strlen(&ft)?&ft:'none'},  " filetype
set statusline+=%{strlen(&fenc)?&fenc:&enc}, " encoding
set statusline+=%{&fileformat}]              " file format
set statusline+=%=                           " right align
set statusline+=%{synIDattr(synID(line('.'),col('.'),1),'name')}\  " highlight
set statusline+=%b,0x%-8B\                   " current char
set statusline+=%-14.(%l,%c%V%)\ %<%P        " offset<Paste>

" Ignore vim globbing finding these file extensions
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.gz,*.o,*.obj,*/vendor/*,*/\.git/*,*~,*.pyc,*.vim

" Open new splits in bottom right by default
set splitbelow
set splitright

" TODO: learn how to do fzf buffer open and keep in fzf window
" This is the default extra key bindings
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" Enable per-command history.
" CTRL-N and CTRL-P will be automatically bound to next-history and
" previous-history instead of down and up. If you don't like the change,
" explicitly bind the keys to down and up in your $FZF_DEFAULT_OPTS.
let g:fzf_history_dir = '~/.local/share/fzf-history'

" You can set up fzf window using a Vim command (Neovim or latest Vim 8 required)
"let g:fzf_layout = { 'window': 'enew' }
"let g:fzf_layout = { 'window': '-tabnew' }
"let g:fzf_layout = { 'window': '10split enew' }

" I don't understand vimscript and it looks like garbage
" Hence I am currently powerless to understand this
"command! Buffers call fzf#run(fzf#wrap(
"    \ {'source': map(range(1, bufnr('$')), 'bufname(v:val)')}))

" https://jesseleite.com/posts/2/its-dangerous-to-vim-alone-take-fzf
" https://github.com/junegunn/fzf.vim#Commands
" With some of my own
let mapleader = ","
nmap <Leader>F :Files<Space>
nmap <Leader>f :Files<CR>
nmap <Leader>g :GFiles<CR>
nmap <Leader>b :Buffers<CR>
nmap <Leader>h :History<CR>
" Vim command history
nmap <Leader>c :History:<CR>
nmap <Leader>w :Windows<CR>

nmap <Leader>l :BLines<CR>
nmap <Leader>L :Lines<CR>
" This is a backtick
nmap <Leader>` :Marks<CR>
"nmap <Leader>a :Ag -A 1 -B 1 --nocolor --silent -f --hidden -U -t<Space>
"nmap <Leader>a :Ag<CR>
nmap <Leader>a :Ag!<Space>
nmap <Leader>A :Agraw<Space>
nmap <Leader>r :Rg<Space>

" Trying fd - apparently faster than find
" https://github.com/sharkdp/fd
"sudo dpkg -i fd_7.2.0_amd64.deb

" From (the ultimate vimrc)
" https://github.com/amix/vimrc
" Set to auto read when a file is changed from the outside
set autoread
" :W sudo saves the file
" (useful for handling the permission-denied error)
" Untested
command! W w !sudo tee % > /dev/null

let $LANG='en'
set langmenu=en
" Makes search act like search in modern browsers
set incsearch
" Don't redraw while executing macros (good performance config)
set lazyredraw
" For regular expressions turn magic on - helps with regex escaping?
set magic

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

"autocmd VimEnter * command! -bang -nargs=* Ag
"    \ call fzf#vim#ag(<q-args>, {'down': '40%', 'options': '--color hl:220,hl+:196'})

" Press ? to open preview window with ag
command! -bang -nargs=* Ag
  \ call fzf#vim#ag(<q-args>,
  \                 <bang>0 ? fzf#vim#with_preview('up:60%')
  \                         : fzf#vim#with_preview('right:50%:hidden', '?'),
  \                 <bang>0)

" To call ag search with arguments to ag/no auto quoting
" https://github.com/junegunn/fzf.vim/issues/273
command! -bang -nargs=* Agraw
  \ call fzf#vim#ag_raw(<q-args>,
  \                 <bang>0 ? fzf#vim#with_preview('up:60%')
  \                         : fzf#vim#with_preview('right:50%:hidden', '?'),
  \                 <bang>0)

" TOGET: https://github.com/tpope/vim-fugitive
" TODO: open marked files as buffers from fzf files
"" TODO: buffer navigation, (c++) completer engine, path/finder setup,
"" cpp/python etc file setup defaults setup, setup script for all this
" Learn vimscript...

" Oh god, here we go...
" YCM.
" Fuck this for now.

" Trying ctags
" As per unimpaired.vim as ctags
" <C-]> explore tag, <C-[> to come up
" ]t and [t and [T ]T to move about tag stack
nnoremap <C-[> <C-t>
" NOTE: universal ctags install currently external program no nice way
" https://github.com/universal-ctags/ctags

" Always centre on jumped to function
nnoremap <C-]> <C-]>zz
" Consider function maybe? Want to open in new tab but the cmd stops after the
" input prompt
"nnoremap g<C-]> <C-w>g<C-]>

if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" majutsushi/tagbar
" Really neat helper bar to see overview of classes
nnoremap <Leader>t :TagbarToggle<CR>
nnoremap <Leader>z :TagbarTogglePause<CR>
let g:tagbar_left = 1
let g:tagbar_autoclose = 1
let g:tagbar_show_visibility = 1
