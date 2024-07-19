" " Python specific settings.
" Make sure black is installed. (python3 pip install black)

" let g:neoformat_enabled_python = ['black', 'docformatter']
let g:neoformat_enabled_python = ['ruff', 'docformatter']

augroup fmt
  autocmd!
  autocmd BufWritePre * silent | Neoformat | noh | redraw!
augroup END

let s:script_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
execute ("source " . s:script_dir . "/" . "google_python_style.vim")

