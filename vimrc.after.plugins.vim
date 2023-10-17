" vim: set foldmethod=marker foldlevel=0 nomodeline:

" This file is sourced automatically via a symlink from
" [after/plugins/post-plugin-config.vim -> ../../vimrc.after.plugins.vim]
"
" This is sourced after all of the plugins are loaded. Add configuration here
" that you want to:
"   1. Take precedence over a bundle config
"   2. Add configurations/functions that relies on a bundle or its mappings
"   3. Add some other setting and guarantee it will be set (this file will
"      always be last to load)

" Easily find commands or key mappings
nnoremap <leader><Space> :Commands<CR>
nnoremap <localleader><Space> :Maps<CR>

" ============================================================================
" Helper Functions {{{1
" ============================================================================

function! s:source(name)
  execute ("source " . s:root . "/" . a:name)
endfunction

" }}}
" ============================================================================
" Global and Script Variables {{{1
" ============================================================================

let s:root = g:vim_root
let g:projectroot = getcwd()
let g:netrw_fastbrowse = 0

" Enable the list of buffers
let g:airline#extensions#tabline#enabled = 1
" Show just the filename
let g:airline#extensions#tabline#fnamemod = ':t'

" }}}
" ============================================================================
" Commented out debugging tips {{{1
" ============================================================================

" :verbose imap <KEY>
" Example :verbose imap <cr>

" }}}
" ============================================================================
"  Syntax highlighting with treesiter {{{1
" ============================================================================

" In my experience, treesitter has been pretty good. Use its highlighting
" Only turn on tree-sitter highlighting for nvim
if has('nvim') && executable('node')
  TSEnable highlight
endif

" }}}
" ============================================================================
"  HG {{{1
" ============================================================================

vnoremap <leader>u :<C-U>!hg blame -fu <C-R>=expand("%:p") <CR> \| sed -n <C-R>=line("'<") <CR>,<C-R>=line("'>") <CR>p <CR>
" This code ^--- is still useful, but taking back this prefix
" nmap <leader>h  :HGblame<CR>

" }}}
" ============================================================================
"  Diff Shortcuts, linediff and window diff{{{1
" ============================================================================

vnoremap <leader>l :Linediff<CR>
nmap <localleader>l :LinediffReset<CR>

nmap <leader>w :windo diffthis<CR>
nmap <localleader>w :windo diffoff<CR>

nmap <leader>do :DiffviewOpen<CR>
nmap <leader>dc :DiffviewOpen<CR>
nmap <leader>dt :DiffviewToggleFiles<CR>
nmap <leader>dr :DiffviewRefresh<CR>
nmap <leader>df :DiffviewFileHistory<CR>

" }}}
" ============================================================================
" Searching {{{1
" ============================================================================

function! RgRoot(term)
" files from local dir
  let s:cwd_old = getcwd()
  let s:gitroot = trim(system('git rev-parse --show-toplevel'))
  let s:cwd_new = g:projectroot
  if len(s:gitroot) != 0
    let s:cwd_new = s:gitroot
  endif

  execute ':lcd ' . s:cwd_new
  execute ':Rg ' . a:term
  execute ':lcd ' . s:cwd_old
endfunction
command! -nargs=* RgRoot call RgRoot(<q-args>)

" Stolen from: https://gist.github.com/danmikita/d855174385b3059cd6bc399ad799555e
" ripgrep
if executable('rg')
  let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*"'
  set grepprg=rg\ --vimgrep
  command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>).'| tr -d "\017"', 1, <bang>0)
endif

" }}}
" ============================================================================
" Buffer helper commands {{{1
" ============================================================================

" Command to delete everything except current working buffer              "
command! -nargs=? -complete=buffer -bang BufOnly
    \ :call BufOnly('<args>', '<bang>')

function! BufOnly(buffer, bang)
  if a:buffer == ''
    " No buffer provided, use the current buffer.
    let buffer = bufnr('%')
  elseif (a:buffer + 0) > 0
    " A buffer number was provided.
    let buffer = bufnr(a:buffer + 0)
  else
    " A buffer name was provided.
    let buffer = bufnr(a:buffer)
  endif

  if buffer == -1
    echohl ErrorMsg
    echomsg "No matching buffer for" a:buffer
    echohl None
    return
  endif

  let last_buffer = bufnr('$')

  let delete_count = 0
  let n = 1
  while n <= last_buffer
    if n != buffer && buflisted(n)
      if a:bang == '' && getbufvar(n, '&modified')
        echohl ErrorMsg
        echomsg 'No write since last change for buffer'
              \ n '(add ! to override)'
        echohl None
      else
        silent exe 'bdel' . a:bang . ' ' . n
        if ! buflisted(n)
          let delete_count = delete_count+1
        endif
      endif
    endif
    let n = n+1
  endwhile

  if delete_count == 1
    echomsg delete_count "buffer deleted"
  elseif delete_count > 1
    echomsg delete_count "buffers deleted"
  endif
endfunction

" }}}
" ============================================================================
"  Buffer Navigation {{{1
" ============================================================================

" Bind leader-d to delete the buffer without deleting the window
nmap <leader>db :BufOnly<CR>
nnoremap <leader>bx :bdelete<CR>
nnoremap <leader>bd :bdelete<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bb :Buffers<CR>
nnoremap <C-P> :bprevious<CR>
nnoremap <C-N> :bnext<CR>
nnoremap <C-X> :bdelete<CR>

" }}}
" ============================================================================
" Tab Navigation {{{1
" ============================================================================

nnoremap <leader>tx :tabclose<CR>
nnoremap <leader>td :tabclose<CR>
nnoremap <leader>tp :tabprevious<CR>
nnoremap <leader>tn :tabnext<CR>
nnoremap <leader>tt :tabs<CR>

" }}}
" ============================================================================
" NERDTree {{{1
" ============================================================================

let g:NERDTreeHijackNetrw = 1
let g:NERDTreeQuitOnOpen = 1
au VimEnter NERD_tree_1 enew | execute 'NERDTree '.argv()[0]

" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

nnoremap <leader>n :NERDTreeVCS<CR>
nnoremap <localleader>n :NERDTreeToggle<CR>
nnoremap <leader>o :NERDTreeFind<CR>

" }}}
" ============================================================================
" Command-T {{{1
" ============================================================================

" nnoremap <Leader>b <Plug>(CommandTBuffer)
" nnoremap <Leader>j <Plug>(CommandTJump)
nnoremap <Leader>t <Plug>(CommandT)

" nnoremap <localleader>n :NERDTreeToggle<CR>
" nnoremap <leader>o :NERDTreeFind<CR>

" }}}
" ============================================================================
"  Fzf Settings and Shortcuts {{{1
" ============================================================================

set rtp+=/opt/homebrew/opt/fzf
set rtp+=/usr/local/Homebrew/opt/fzf
set rtp+=/home/linuxbrew/opt/fzf

" files from local dir
nnoremap <leader>j :Files<CR>

" }}}
" ============================================================================
"  Source FZF preview {{{1
" ============================================================================

if filereadable(s:root . '/vimrcfiles/fzf-preview.vim')
  call s:source('vimrcfiles/fzf-preview.vim')
endif

" }}}
" ============================================================================
"  FZF Functions for file traversal (experimenting) {{{1
" ============================================================================

" From the guy who made fzf
" Reloading source on CTRL-P. Requires fd command.
function! FZFSimple(dir)
  let tf = tempname()
  call writefile(['.'], tf)

  call fzf#vim#files(a:dir, {'source': 'fd', 'options': ['--bind', printf('ctrl-p:reload:base="$(cat %s)"/..; echo "$base" > %s; fd . "$base"', shellescape(tf), shellescape(tf))]})
endfunction
command! -nargs=* FZFSimple call FZFSimple(<q-args>)
" Good Ref: https://vi.stackexchange.com/questions/13965/what-is-command-bang-nargs-in-a-vimrc-file

"" Three functions from: https://github.com/junegunn/fzf.vim/issues/338
" Search pattern across repository files
function! FzfExplore(...)
    let inpath = substitute(a:1, "'", '', 'g')
    if inpath == "" || matchend(inpath, '/') == strlen(inpath)
        execute "cd" getcwd() . '/' . inpath
        let cwpath = getcwd() . '/'
        call fzf#run(fzf#wrap(fzf#vim#with_preview({'source': 'ls -1ap', 'dir': cwpath, 'sink': 'FZFExplore', 'options': ['--prompt', cwpath]})))
    else
        let file = getcwd() . '/' . inpath
        execute "e" file
    endif
endfunction
command! -nargs=* FZFExplore call FzfExplore(shellescape(<q-args>))

function! FZFTFile(dir, previous_dirs)
  if empty(a:dir)
    let dir = getcwd()
  else
    let dir = a:dir
  endif
  let previous_dirs = a:previous_dirs
  let parentdir = fnamemodify(dir, ':h')
  let spec = fzf#wrap(fzf#vim#with_preview({'options': ['--expect', 'ctrl-h,ctrl-f'] }))

  " hack to retain original sink used by fzf#vim#files
  let origspec = copy(spec)
  unlet spec.sinklist
  unlet spec['sink*']
  function spec.sinklist(lines) closure
    if len(a:lines) < 2
      return
    endif
    if a:lines[0] == 'ctrl-h'
      let previous_dirs = [dir] + previous_dirs
      call FZFTFile(parentdir, previous_dirs)
    elseif a:lines[0] == 'ctrl-f'
      if !empty(previous_dirs)
        let previous_dir = previous_dirs[0]
        let previous_dirs = previous_dirs[1:]
        call FZFTFile(previous_dir, previous_dirs)
      endif
    else
      call origspec.sinklist(a:lines)
    end
  endfunction
  call fzf#vim#files(dir, spec)
endfunction
command! -nargs=* FZFTFile call FZFTFile(<q-args>, [])

" Files + devicons
function! Fzf_dev()
  let l:fzf_files_options = '--preview "bat --theme="OneHalfDark" --style=numbers,changes --color always {2..-1} | head -'.&lines.'"'

  function! s:files()
    let l:files = split(system($FZF_DEFAULT_COMMAND), '\n')
    return s:prepend_icon(l:files)
  endfunction

  function! s:prepend_icon(candidates)
    let l:result = []
    for l:candidate in a:candidates
      let l:filename = fnamemodify(l:candidate, ':p:t')
      let l:icon = WebDevIconsGetFileTypeSymbol(l:filename, isdirectory(l:filename))
      call add(l:result, printf('%s %s', l:icon, l:candidate))
    endfor

    return l:result
  endfunction

  function! s:edit_file(item)
    let l:pos = stridx(a:item, ' ')
    let l:file_path = a:item[pos+1:-1]
    execute 'silent e' l:file_path
  endfunction

  call fzf#run({
        \ 'source': <sid>files(),
        \ 'sink':   function('s:edit_file'),
        \ 'options': '-m ' . l:fzf_files_options,
        \ 'down':    '40%' })
endfunction
nnoremap <silent> <leader>q :call Fzf_dev()<CR>

" }}}
" ============================================================================
"  Source coc.vim and add some shortcuts - only if node is installed {{{1
" ============================================================================

if executable('node')
  inoremap <expr> <C-j>               coc#pum#visible() ? coc#pum#next(1) : "\<C-j>"
  inoremap <expr> <C-k>               coc#pum#visible() ? coc#pum#prev(1) : "\<C-k>"
  inoremap <expr> <Tab>           coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"
  inoremap <expr> <S-Tab>         coc#pum#visible() ? coc#pum#prev(1) : "\<S-Tab>"

  if filereadable(s:root . '/vimrcfiles/coc.vim')
    call s:source('vimrcfiles/coc.vim')
  endif

  nmap <leader>hcn :h coc-nvim.txt<CR>
  nmap <leader>hcc :h coc-config.txt<CR>

  " Formatting cocconfig?
  autocmd FileType json syntax match Comment +\/\/.\+$+

  nmap <leader>e :CocDiagnostics<CR>

  "" Use K to show documentation in preview window
  nnoremap <localleader>t :call ShowDocumentation()<CR>

  nnoremap <localleader>r :call CocActionAsync('jumpReferences')<CR>
  nnoremap <localleader>s :call CocActionAsync('jumpDefinition')<CR>
  nnoremap <localleader>i :call CocActionAsync('jumpImplementation')<CR>
  nnoremap <localleader>d :call CocActionAsync('jumpDeclaration')<CR>
  nnoremap <leader>i :call CocActionAsync('jumpTypeDefinition')<CR>
  nnoremap <leader>f :call CocList outline methods<CR>

  " TODO(sagar): figure out how to use <Plug>
  " https://vi.stackexchange.com/questions/31012/what-does-plug-do-in-vim
  "
  " TODO(sagar): Go through everything here and add a bunch of keys
  " https://github.com/neoclide/coc.nvim/blob/03c9add7cd867a013102dcb45fb4e75304d227d7/doc/coc.txt#L2311
endif

" }}}
" ============================================================================
" Text/string manipulation {{{1
" ============================================================================

" This function will format a block of text and make sure it's 80 characters
" or less. Useful for formatting comments. It also strips trailing \ for EOL
" markers
function! FormatText() range
  let l:tmpwidth= &textwidth
  :'<,'>s/[[:space:]]\+\\[[:space:]]*$//
  let &textwidth = 77
  :'<,'>normal gqG
  let &textwidth = tmpwidth
  ":'<,'>s/[[:space:]]*$/ \\/
endfunction
:command! -range FormatText <line1>,<line2>call FormatText()
vnoremap <silent> <leader>w :'<,'>FormatText<CR>
" Add trailing \ to end of line
vnoremap <leader>\ :s/[[:space:]]*$/ \\/<CR>

" Format selected text as json
vnoremap <leader>j :!jq .<CR>

" Delete empty lines in selected text
vnoremap <leader>d :g/^\s*$/d<CR>

" }}}
" ============================================================================

