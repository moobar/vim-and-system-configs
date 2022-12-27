set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

" Taken from: https://github.com/pwntester/dotfiles/blob/5d8afc3ed6a2c918bdc353e66e81b7d31cabc1b0/config/nvim/init.vim
augroup vimrc
" shada file when there are annoying marks
" :e ~/.local/share/nvim/shada/main.shada
" sagar: [2022-06-29] Added this to automatically remove all marks before exiting.
"        For me I never want marks to stick around between vim sessions.
"        ** This is a nvim specific issue
  autocmd VimEnter * :delmarks 0-9
  autocmd VimLeavePre * :delmarks!
augroup END

source ~/.vimrc
