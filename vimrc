" vim: set foldmethod=marker foldlevel=0 nomodeline:
" Most of the formatting and styling was inspired by Junegunn Choi's dotfiles
" https://github.com/junegunn-x/dotfiles

" TODO: Go through junegunn's dot files and add more to my vimconfig
"       [~/forge/junegunn-dotfiles/dotfiles-master/vimrc]

" ============================================================================
" Global Settings and Variables {{{1
" ============================================================================
set nocompatible

" From: https://stackoverflow.com/questions/4976776/how-to-get-path-to-the-current-vimscript-being-executed
" If you're using a symlink to your script, but your resources are in
" the same directory as the actual script, you'll need to do this:
"   1: Get the absolute path of the script
"   2: Resolve all symbolic links
"   3: Get the folder of the resolved absolute file
let g:vim_root = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let s:root = g:vim_root

execute "set runtimepath^=".s:root
execute "set runtimepath+=".s:root."/after"

if (has("nvim"))
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  let &packpath = &runtimepath
endif

if exists('g:vscode')
  let g:coc_start_at_startup = 0  " Disable Coc, use [CocStart] if I want to start it, as per the docs
endif

" }}}
" ============================================================================
" Helper Functions {{{1
" ============================================================================

function! s:source(name)
  execute ("source " . s:root . "/" . a:name)
endfunction

" }}}
" ============================================================================
" Settings that need to be configured befor vim-plug {{{1
" ============================================================================

  "" Nothing Here Yet ""

" }}}
" ============================================================================
" Source bundles from vim-plug and plugins {{{1
" ============================================================================

call s:source('bundles')
packadd! matchit

" If node isn't installed, let's not load coc
if !executable('node') || exists('g:vscode')
  execute ("set runtimepath-=" . s:root . "/plugged/coc.nvim")
else
  " Helper function for updating coc
  function! CocQuitAfterUpdate(timer_id)
      for buf in range(1, bufnr('$'))
          if bufexists(buf) && buflisted(buf)
              let lines = getline(1, '$')
              if index(lines, 'Update finished') >= 0
                  call timer_stop(a:timer_id)
                  :qa!
                  return
              endif
          endif
      endfor
  endfunction

  function! CocUpdateAndQuit()
      CocUpdate
      call timer_start(1000, 'CocQuitAfterUpdate', {'repeat': -1})
  endfunction

  command! CocUpdateAndQuit call CocUpdateAndQuit()

endif

" }}}
" ============================================================================
" Settings to enable after bundles loaded / Plugin Configurations {{{1
" ============================================================================

" Ack
if executable('rg')
  let g:ackprg = 'rg --vimgrep'
elseif executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" Enable markdown fences for these languages
let g:vim_markdown_fenced_languages = ["viml=vim", "bash=sh", "python=python"]
" Open markdown files with all folds expanded

if !exists('g:netrw_list_hide')
  let g:netrw_list_hide=',.*\.cmx$,.*\.d$,.*\.cmt$,.*\.cmti$,.*\.a$,.*\.cmi$,.*\.o$,.*\.deps$,.*\.cmxa$,.*\.libdeps$,.*\.pack-order$,.*\.ml-gen$,.merlin$,.*\.stub.names$,.*\.modules$'
endif

" }}}
" ============================================================================
" Autocmds/Augroups {{{1
" ============================================================================

augroup qf
  autocmd!
  autocmd QuickFixCmdPost [^l]* cwindow
  autocmd QuickFixCmdPost l*    cwindow
  autocmd VimEnter        *     cwindow
augroup END
function! s:Run_rg(switches)
  setlocal efm=%f:%l:%m
  cexpr system("rg ".escape(a:switches, ' '))
endfunction
command! -nargs=* Rg call <SID>Run_rg(<q-args>)

" }}}
" ============================================================================
" Filetype augroups {{{1
" ============================================================================

fun! <SID>StripTrailingWhitespaces()
  let _s = @/
  let l:winview = winsaveview()
  silent! %s/\s\+$//e
  call winrestview(l:winview)
  let @/ = _s
endfun

augroup strip_trailing_whitespace
  au BufWritePre *.{c,cc,cpp,h} :call <SID>StripTrailingWhitespaces()
  au BufWritePre *.{go} :call <SID>StripTrailingWhitespaces()
  au BufWritePre *.{java} :call <SID>StripTrailingWhitespaces()
  au BufWritePre *.{js,ts} :call <SID>StripTrailingWhitespaces()
  au BufWritePre *.{md} :call <SID>StripTrailingWhitespaces()
  au BufWritePre *.{py} :call <SID>StripTrailingWhitespaces()
  au BufWritePre *.{scala} :call <SID>StripTrailingWhitespaces()
  au BufWritePre *.{sh} :call <SID>StripTrailingWhitespaces()
  au BufWritePre *.{vim} :call <SID>StripTrailingWhitespaces()
  au BufWritePre bashrc :call <SID>StripTrailingWhitespaces()
  au BufWritePre bundles :call <SID>StripTrailingWhitespaces()
  au BufWritePre inputrc :call <SID>StripTrailingWhitespaces()
  au BufWritePre vimrc :call <SID>StripTrailingWhitespaces()
augroup end

augroup markdown
  au!
  au BufRead,BufNewFile *.mkd,*.mmd setfiletype markdown
  au BufRead,BufNewFile *.mkd,*.mmd set tw=120
  autocmd FileType markdown normal zR
augroup end

augroup log
  au!
  au BufRead,BufNewFile *.log setfiletype log
  au BufRead,BufNewFile *.log setlocal nowrap
augroup end

augroup dat
  au!
  au BufRead,BufNewFile *.DAT setfiletype dat
  au BufRead,BufNewFile *.dat setfiletype dat
  au BufRead,BufNewFile *.dat setlocal nowrap
  au BufRead,BufNewFile *.DAT setlocal nowrap
augroup end

augroup csv
  au!
  au BufRead,BufNewFile *.{csv,report} setfiletype csv
  au BufRead,BufNewFile *.{csv,report} setlocal nowrap
augroup end

augroup ps
  au!
  autocmd BufReadPre *.{pdf,ps} set ro
  autocmd BufReadPost *.{pdf,ps} silent %!pdftotext -nopgbrk "%" - |fmt -csw78
augroup end

augroup doc
  au!
  autocmd BufReadPre *.doc set ro
  autocmd BufReadPost *.doc silent %!antiword "%"
augroup end

augroup binary
  au!
  au BufReadPre  *.{bin,exe,class,o} let &bin=1
  au BufReadPost *.{bin,exe,class,o} if &bin | %!xxd
  au BufReadPost *.{bin,exe,class,o} set ft=xxd | endif
  au BufWritePre *.{bin,exe,class,o} if &bin | %!xxd -r
  au BufWritePre *.{bin,exe,class,o} endif
  au BufWritePost *.{bin,exe,class,o} if &bin | %!xxd
  au BufWritePost *.{bin,exe,class,o} set nomod | endif
augroup end

augroup py
  au!
  " This red error message was driving me crazy. wtf
  " au BufWinEnter *.{py} let w:m1=matchadd('ErrorMsg', '\%>90v.\+', -1)
augroup end

augroup sh
  au!
  au BufRead,BufNewFile *.{sh} setfiletype bash
augroup end

augroup vim
  au!
  au BufRead,BufNewFile *.{vim} setfiletype vim
augroup end

augroup supertab
  au!
  autocmd Filetype *
  \ if &omnifunc != '' |
  \   call SuperTabChain(&omnifunc, "<c-p>") |
  \   call SuperTabSetDefaultCompletionType("<c-x><c-u>") |
  \ endif
augroup end

" }}}
" ============================================================================
" VIM UX Settings {{{1
" ============================================================================

" TODO - Switch to space as the leader. it's easider to get to and better
let maplocalleader = ",,"
let mapleader = " "

" let maplocalleader = ",,"
" let mapleader = ","

" When splitting, don't auto move to the split buffer
set splitbelow
set splitright

" Always make opening a file with ":e ." relative to current working file
set autochdir

" use filetypes and filetype plugins
filetype plugin indent on

" syntax highlighting
syntax on
set synmaxcol=1000

" line numbers
set number

" Always assume a 256 color terminal
set t_Co=256

" Shift-tab on GNU screen
" http://superuser.com/questions/195794/gnu-screen-shift-tab-issue
set t_kB=[Z

" Use UTF-8
set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8

" Explicitly list tabs for better consistency
set list
set listchars=tab:\|\ ,

" use short messages where possible
set shortmess=at

" always use bash
set shell=bash

" check for a modeline when opening a file
set modeline
set modelines=10

" don't call fsync ever
set nofsync
if exists('&swapsync')
  set swapsync=""
endif

" No backup files
set nobackup
set noswapfile

" No error bells
set noerrorbells
set novisualbell

" Set the terminal title
set title

" Allow moving the cursor anywhere on the screen in block mode
set virtualedit=block

" Use the system clipboard as the unnamed register so that normal
" yank and paste use it
set clipboard=unnamed

" Printing options - here just setting paper size
" set printoptions=paper:letter

" Maintain some more context around the cursor
set scrolloff=3
set sidescrolloff=3

" Always show as much of the last line as possible
set display+=lastline

" Switch to the first window or tab that contains the open file
" instead of duplicating an open window if possible.  Open a new
" tab page if the buffer is not currently open
set switchbuf=usetab

" Hide buffers instead of closing when we open over them to preserve undo
" history
set hidden

" Fancy tab handling
set smarttab

" Tabs are 2 characters
set tabstop=2

" (Auto)indent uses 2 characters
set shiftwidth=2

" indent/outdent to nearest tab stop
set shiftround

" don't put 2 spaces after a .
set nojoinspaces

" spaces instead of tabs
set expandtab

" guess indentation
set autoindent
set smartindent

" remember a long list of our commands from the past
set history=1000

" remember some stuff after quiting vim: marks, registers, searches, buffer list
set viminfo='20,<50,s10,h,%

" Expand the command line using tab
set wildmenu
set wildmode=list:longest,full
set wildignore+=*.o,*.a,*.cm*,*.annot,*.spot,*.spit,*.exe,*.omc,*.d,*.orig,*.gen,*.objdeps,*.deps,*.libdeps,*.names,*.ml-gen,*.a,*.cmxa.*.pack-order,*.modules,*.names,.merlin

" Deprioritize certain extensions
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc,.cmi,.cmo,.cmx,.cmxa,.exe,.ho,.hi,.bc,.out,.annot,.spot,.spit,.omc,.d,.orig

" display the current mode and partially-typed commands in the status line:
set statusline=%F%m%r%h%w\ %y\ [pos=%l,%v]\ [len=%L\ (%p%%)]
set laststatus=2

" better backspaces
set backspace=indent,eol,start

" reasonable wrapping at ends of lines
set whichwrap=b,s,<,>

" but don't wrap by default
set nowrap

" set ng of text and comments
set formatoptions=tn1

" timeout command sequences after half a second, and terminal character codes
" after a tenth of a second
set timeout timeoutlen=500 ttimeoutlen=100

" highlight the searchterms (and let us unhighlight easily)
set hlsearch

" jump to the matches while typing
set incsearch

" assume /g flag on :s substitutions
set gdefault

" don't wrap words
set textwidth=0

" when we do wrap visibly (by calling set wrap) break in
" reasonable places
set linebreak

let &undodir=$HOME . "/.vim_undo"

if !isdirectory(&undodir)
  :call mkdir(&undodir)
endif

set undolevels=1000
set undoreload=10000

" show partial commands
set showcmd

" don't move my cursor to the beginning of lines for me
set nostartofline

" tell us when anything is changed via a ":" command
set report=0

" show matching braces, but don't highlight them all the time, just for
" 5 seconds
set showmatch
set matchtime=5

" set options for autocompletion
set noinfercase

" searching should be case insensitive unless we used a capital letter
set ignorecase
set smartcase

" autocomplete should not ignore case when in insert mode
augroup insert_enter_leave
  au!
  autocmd InsertEnter * set noignorecase
  autocmd InsertLeave * set ignorecase
augroup END

" ignore whitespace when diffing
set diffopt+=iwhite
if has('nvim-0.5.0')
  set diffopt+=filler,closeoff,vertical
else
  set diffopt+=filler,vertical
endif

" better syntax highlighting for shell scripts
" syntax highlight shell scripts as per POSIX,
" not the original Bourne shell which very few use
let g:is_posix = 1

" Always show the menu (even when there is only one match), insert longest match, show
" additional info (this is useful because merlin gives us signature of values)
set completeopt=menuone,longest,preview

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
augroup last_known_cursor
  au!
  autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g`\"" | endif
augroup END

augroup shell_keywords
  au!
  autocmd FileType sh set iskeyword=~,@,48-57,_,192-255,-
augroup END

" tell vim not to use background erase
set t_ut=

" Reload files that change in the background if Vim has no changes
set autoread

" set a default colorscheme - this should be changed in the overrides
" file rather than here if you don't want this colorscheme
set background=dark

let g:vim_monokai_tasty_italic = 1                    " allow italics, set this before the colorscheme
let g:vim_monokai_tasty_machine_tint = 1              " use `mahcine` colour variant
let g:vim_monokai_tasty_highlight_active_window = 1   " make the active window stand out
" colorscheme vim-monokai-tasty
" colorscheme github_dark_colorblind
colorscheme github_dark_default

" Hack to always open folds unless modeline says otherwise
set foldlevelstart=99

" :grep follows this
set grepformat=%f:%l:%c:%m,%f:%l:%m

" Don't highlight where the cursor is
set nocursorline

" If possible, try to set to blowfish2
silent! set cryptmethod=blowfish2

" mouse support
silent! set ttymouse=xterm2
set mouse=a

" 120 chars/line
set textwidth=0
if exists('&colorcolumn')
  set colorcolumn=120
endif

" Some fancy statusline printing
function! s:statusline_expr()
  let mod = "%{&modified ? '[+] ' : !&modifiable ? '[x] ' : ''}"
  let ro  = "%{&readonly ? '[RO] ' : ''}"
  let ft  = "%{len(&filetype) ? '['.&filetype.'] ' : ''}"
  let fug = "%{exists('g:loaded_fugitive') ? fugitive#statusline() : ''}"
  let sep = ' %= '
  let pos = ' %-12(%l : %c%V%) '
  let pct = ' %P'

  return '[%n] %F %<'.mod.ro.ft.fug.sep.pos.'%*'.pct
endfunction
let &statusline = s:statusline_expr()


" }}}
" ============================================================================
" Global Mappings {{{1
" ============================================================================

" load arpeggio, so we have access to chords for mapping
call arpeggio#load()

" ' is easier to get to than `
nnoremap ' `
nnoremap ` '

" Open a fold at the lower part of it, instead of the top of it.
" Useful for vimdiffing files
nmap zl zo]z

" <F5> to bring up the undo window
nnoremap <F5> :GundoToggle<CR>

" lookup keyword is almost never used, invert J instead
nnoremap K i<CR><Esc>

" enter is useless in normal mode, saving is awesome
" Except that some buffers cannot be saved AND have enter
" bound to something really useful (quickfix buffer for example)
" So only save if saving is a useful action otherwise use
" previous mapping if any
nnoremap <expr> <cr> &buftype=="" ? ":w<cr>" : "<cr>"

" space is also useless in normal mode, : is awesome
nnoremap <space> :
vnoremap <space> :

" ex-mode is weird, remap Q
nnoremap Q q

" map ;qj to reformat the current paragraph
call arpeggio#map("n", "", 0, ";qj", ":normal gqip<cr>")

" Change == to reindent the current paragraph instead of the current line.
" Impl details:
" * vip= instead of =ip because the visual highlight of what's being indented
"   is useful
" * Use `9 mark since it's temporary, and we don't wanna overwrite a mark that
"   someone will use
" * g`9 instead of `9 because g`9 doesn't affect the jumplist
:nnoremap == m9vip=g`9

" map < and > to repeated shifting in visual and select modes
vnoremap < <gv
vnoremap > >gv
vnoremap <Left> <gv
vnoremap <Right> >gv

" Replay macros over visual range
function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction

vnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>

" shift arrow keys to move around windows
map    <S-Up>      <esc><C-w><Up>
map    <S-Down>    <esc><C-w><Down>
imap   <S-Up>      <esc><C-w><Up>
imap   <S-Down>    <esc><C-w><Down>
map    <S-Left>    <esc><C-w><Left>
map    <S-Right>   <esc><C-w><Right>
imap   <S-Left>    <esc><C-w><Left>
imap   <S-Right>   <esc><C-w><Right>

" }}}
" ============================================================================
" Copy/Buffer/Clipboard settings. Some OSX specific {{{1
" ============================================================================

"" OSX - Hack so yank and all that stuff won't squash the clipboard
nnoremap yy "0yy
nnoremap dd "0dd

noremap y "0y
" Y yanks to the sytem clipeboard
nnoremap Y "+y
noremap d "0d
noremap D "0D
noremap p "0p
noremap P "0P
noremap x "0x
noremap X "0X

" delete the current word in insert mode, without copying to clipboard
" For more info, see: http://vimdoc.sourceforge.net/htmldoc/motion.html#WORD
" inoremap <C-w> <esc>"_d^i

" TODO: OSX Specific
function! To_clipboard() range abort
  " silent let l:output=systemlist("xclip -f -sel clip | xclip -f | wc -l", @9)
  silent let l:output=systemlist("pbcopy && pbpaste | wc -l | awk '{print $1}'", @9)
  if "0" == l:output[0]
    let l:amt = len(@9) . " char(s)"
  else
    let l:amt = l:output[0] . " line(s)"
  endif

  :echo 'copied ' . l:amt
endfunction

" copy and paste from/to x clipboard
" vnoremap <leader>x "9ygvx:<C-U>call To_clipboard()<CR>
" nnoremap <leader>c "9yy:call To_clipboard()<CR>

vnoremap <leader>c "9ygv:<C-U>call To_clipboard()<CR>
nnoremap <leader>c "9yy:call To_clipboard()<CR>

" TODO: OSX Specific
vmap <leader>v :r !pbpaste<CR>
nmap <leader>v :r !pbpaste<CR>

" This allows you to use paste between vim sessions with ,y ,p
vmap <leader>y :w! /tmp/vitmp<CR>
nmap <leader>p :r! cat /tmp/vitmp<CR>

" }}}
" ============================================================================
" Post Plugin Settings and Functions - Before after/plugins {{{1
" ============================================================================

if has('nvim') && executable('lua')
  let g:CommandTPreferredImplementation='lua'
else
  let g:CommandTPreferredImplementation='ruby'
endif

"" Other Settings can be configured in [.vim/after/plugin]

" }}}
" ============================================================================

let g:airline#extensions#tabline#enabled = 1

"" Experimental ""

" Look into: https://github.com/rockerBOO/awesome-neovim
