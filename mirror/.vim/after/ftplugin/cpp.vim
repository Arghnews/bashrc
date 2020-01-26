call Tab(2, 0)
setlocal cc=80
setlocal textwidth=80

" Stripwhitespace plugin has mappings that we remove first
" silent! means we ignore errors in case they're not mapped
silent! nunmap <Leader>s
silent! nunmap <Leader>s<Space>

nmap <buffer> <Leader>v ostd::cout <<  << "\n";<ESC>bbbbhi
nmap <buffer> <Leader>s ofmt::print("\n");<ESC>bbhi
nmap <buffer> <Leader>S Ofmt::print("\n");<ESC>bbhi

" See help cinoptions-values
" Don't indent code in namespaces at all
" h-0: don't indent line after public: or private: access specifier
set cinoptions=N-s,h-0

" Don't indent template functions if they are one lined.
" Not perfect (but then parsing C++ (in vimscript) was always going to be
" tough but will see how it fairs for now.
" Rule is - if template starts/end on same line then we indent to template.
" Else one indent in from template. Obv we can't parse this using regex so
" will need to iterate over string and match up < and > chars until word
" template.
" TODO: implement one day, perhaps, even this will have failure cases I think
" (word in front of word template).
" function! CppNoNamespaceAndTemplateIndent()
"     let l:cline_num = line('.')
"     let l:cline = getline(l:cline_num)
"     let l:pline_num = prevnonblank(l:cline_num - 1)
"     let l:pline = getline(l:pline_num)
"     return cindent(v:lnum)
"     while l:pline =~# '\(^\s*{\s*\|^\s*//\|^\s*/\*\|\*/\s*$\)'
"         let l:pline_num = prevnonblank(l:pline_num - 1)
"         let l:pline = getline(l:pline_num)
"     endwhile
"     " echom "Current line ".l:cline
"     " echom "Previous line ".l:pline
"     let l:retv = cindent('.')
"     let l:pindent = indent(l:pline_num)
" 	" echom "hi"
"     " if l:pline =~# '^\s*template\s*\s*$'
" 	    " " echom "Choosing 1"
"     "     " let l:retv = l:pindent
"     " elseif l:pline =~# '\s*typename\s*.*,\s*$'
" 	    " " echom "Choosing 2"
"     " "     let l:retv = l:pindent
"     " elseif l:cline =~# '^\s*>\s*$'
" 	    " " echom "Choosing 3"
"     "     let l:retv = l:pindent - &shiftwidth
"     " elseif l:pline =~# '\s*typename\s*.*>\s*$'
"     if l:pline =~# '\s*\(typename\|class\).*$'
" 	    " echom "Choosing 4"
"         let l:retv = l:pindent
"     " elseif l:pline =~# '\s*typename\s*.*>\s*$'
" 	    " echom "Choosing 4"
"         " let l:retv = l:pindent - &shiftwidth
"         " let l:retv = l:pindent
"     " elseif l:pline =~# '^\s*namespace.*'
"     "     let l:retv = 0
"     endif
"     " echom "_"
"     return l:retv
" endfunction

" setlocal indentexpr=CppNoNamespaceAndTemplateIndent()
" " if has("autocmd")
" "     autocmd BufEnter *.{cc,cxx,cpp,h,hh,hpp,hxx} setlocal indentexpr=CppNoNamespaceAndTemplateIndent()
" " endif

