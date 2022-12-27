if exists("g:loaded_local_ocaml")
  finish
endif
let g:loaded_local_ocaml = 1

setlocal nowrap

" arpeggio map to add a cr
" The <ESC>a is to keep fe from interpreting this vim config as having a CR
call arpeggio#map("n", "", 0, "gc", "O(* C<ESC>aR <C-R>=substitute(system(\"whoami\"), '\\n', '', 'g')<CR>: *)<ESC>bT:i ")
call arpeggio#map("n", "", 0, "ui", "O(* C<ESC>aR <C-R>=substitute(system(\"whoami\"), '\\n', '', 'g')<CR>: *)<ESC>bT:i ")

" altr setup
call altr#define('%.ml', '%.mli', '%_intf.ml', '%0.ml', '%0.mli', '%1.ml', '%1.mli', '%.mly')

" merlin setup
nnoremap <localleader>s :MerlinLocate<CR>
nnoremap <localleader>t :TypeOf<CR>

" Autoformat

augroup fmt
  autocmd!
  autocmd BufWritePost * silent! execute "!ocamlformat --profile janestreet --enable-outside-detected-project -i % >/dev/null 2>&1" | redraw!
augroup END


""""""""""""""""""""""""""""""""""""""""""""""""
" Make FzfMerlin in insert mode actually usable. "
""""""""""""""""""""""""""""""""""""""""""""""""
function! Fzf_merlin_insert_mode_rev()
  let l:fzf_default_opts = "$FZF_DEFAULT_OPTS"
  let $FZF_DEFAULT_OPTS = "--reverse"
  :FzfMerlinInsertMode
  let $FZF_DEFAULT_OPTS = l:fzf_default_opts
endfunction
:command! FzfMerlinInsertModeRev :call Fzf_merlin_insert_mode_rev()

function! s:merlin_append(lines)
  if a:lines != []
    let s = matchstr(a:lines[0], '^\S*')
    call feedkeys(s)
  endif
endfunction

function! Fzf_merlin_insert_mode()
  let start = merlin#Complete(1, "")
  let base = strpart(getline('.'), start, col('.') - 1 - start)
  let source = map(merlin#Complete(0, base), 'printf("%-25s %s", v:val.word, v:val.menu)')

  call fzf#run(fzf#wrap('merlin', {
        \ 'source': source,
        \ 'sink*': function('s:merlin_append'),
        \ 'options': '+x -n 1,1..', }))
endfunction
:command! FzfMerlinInsertMode :call Fzf_merlin_insert_mode()


" Wrapper for jumping to mli
" This is meant to make it easy to jump to either the ml or mli
" By default, MerlinLocate will only let you do one or the other.
function! MerlinLocateMli()
  let l:user_merlin_locate_preference = g:merlin_locate_preference
  let g:merlin_locate_preference = 'mli'
  :MerlinLocate
  let g:merlin_locate_preference = l:user_merlin_locate_preference
endfunction
:command! MerlinLocateMli :call MerlinLocateMli()

" in insert mode, run merlin at the current cursor position and show results in
" fzf
inoremap <silent> <C-G>t <C-O>:FzfMerlin<CR>

" FzfMerlin popdown. Useful alternative to supertab
inoremap <silent> <C-f> <C-O>:FzfMerlinInsertModeRev<CR>

" use omnicompletion for supertab
let g:SuperTabDefaultCompletionType = "<C-P>"
" <C-p> only completes words present in the buffer, but on .ml[i] files merlin
" can do better than that and list us what is in the environment at the current
" point.
augroup ocaml_tab_complete
  au!
  au FileType ocaml
    \ if exists ("*SuperTabSetDefaultCompletionType") |
    \   call SuperTabSetDefaultCompletionType("<C-x><C-o>") |
    \ endif
augroup END

""""""""""""""""""""""
"" Merlin Additions ""
""""""""""""""""""""""
" switch between mli/ml
nmap <leader>a <Plug>(altr-forward)

" yank type def
nmap <localleader>y :MerlinYankLatestType<CR>

" pop open window with last set type
nmap <localleader>h :MerlinToggleTypeHistory<CR>

" List to all instances
nnoremap <localleader>j :MerlinOccurrences<CR>

" Show documentation
nnoremap <localleader>d :MerlinDocument<CR>

" Jump to mli
nnoremap <localleader>i :MerlinLocateMli<CR>

"" Rename variables ""
nmap <LocalLeader>r  <Plug>(MerlinRename)
nmap <LocalLeader>R  <Plug>(MerlinRenameAppend)

" pop open window with outstanding errors
nmap <leader>e :MerlinErrorCheck<CR>


" Wrapper for jumping to mli
" This is meant to make it easy to jump to either the ml or mli
" By default, MerlinLocate will only let you do one or the other.
function! MerlinLocateMli()
  let l:user_merlin_locate_preference = g:merlin_locate_preference
  let g:merlin_locate_preference = 'mli'
  :MerlinLocate
  let g:merlin_locate_preference = l:user_merlin_locate_preference
endfunction
:command! MerlinLocateMli :call MerlinLocateMli()

" in insert mode, run merlin at the current cursor position and show results in
" fzf
inoremap <silent> <C-G>t <C-O>:FzfMerlin<CR>


nnoremap <leader>o :OcamlFormat<CR>
" Can't seem to format a block of text
"vnoremap <leader>o :OcamlFormat<C-U><CR>
vnoremap <leader>s :%!sexp pp<CR>
vnoremap <leader>S :%!sexp print -machine<CR>
