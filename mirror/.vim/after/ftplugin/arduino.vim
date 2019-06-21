" For Arduino cpp files

" For testing if working (this time I made ino.vim rather than arduino.vim
" Can output to messages with :echom "hello world"
" Then read with :messages
" echom "Hi from ino.vim!"

" Copied from cpp.vim
call Tab(2, 0)
setlocal cc=80
setlocal textwidth=80

nmap <buffer> <Leader>s oSerial.print("<C-O>mz<Space>");<CR>Serial.println("");<ESC>`za

" So that automatic indentation works like on normal cpp files
setlocal cindent

