call Tab(2, 0)
setlocal cc=80
setlocal textwidth=80

" Stripwhitespace plugin has mappings that we remove first
" silent! means we ignore errors in case they're not mapped
silent! nunmap <Leader>s
silent! nunmap <Leader>s<Space>
nmap <buffer> <Leader>s ostd::cout <<  << "\n";<ESC>bbbbhi

" See help cinoptions-values
" Don't indent code in namespaces at all
set cinoptions=N-s
