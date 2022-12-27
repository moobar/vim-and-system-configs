fun! <SID>StripTrailingWhitespaces()
  let _s = @/
  let l:winview = winsaveview()
  silent! %s/\s\+$//e
  call winrestview(l:winview)
  let @/ = _s
endfun

augroup omake
  au!
  au BufRead,BufNewFile OMakefile setfiletype omake
  au BufRead,BufNewFile OMakefile setlocal nowrap
augroup end

augroup sexp
  au!
  au BufRead,BufNewFile *.sexp setfiletype scheme
  au BufRead,BufNewFile *.sexp setlocal nowrap
augroup end

augroup ocaml
  au!
  au BufWinEnter *.{ml,mli} let w:m1=matchadd('ErrorMsg', '\%>90v.\+', -1)
  au BufWritePre *.{ml,mli} :call <SID>StripTrailingWhitespaces()
augroup end

