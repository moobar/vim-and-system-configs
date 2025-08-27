"" Copied from vscode-tab-commands.vim in the ovverides directory for neovim-vscode
function! s:switchEditor(...) abort
    let count = a:1
    let direction = a:2
    for i in range(1, count ? count : 1)
        call VSCodeCall(direction ==# 'next' ? 'workbench.action.nextEditorInGroup' : 'workbench.action.previousEditorInGroup')
    endfor
endfunction

function! s:gotoEditor(...) abort
    let count = a:1
    call VSCodeCall(count ? 'workbench.action.openEditorAtIndex' . count : 'workbench.action.nextEditorInGroup')
endfunction

function! s:vscodeGoToDefinition(str)
    if exists('b:vscode_controlled') && b:vscode_controlled
        call VSCodeNotify('editor.action.' . a:str)
    else
        " Allow to function in help files
        exe "normal! \<C-]>"
    endif
endfunction

"" VS Code Commands to migrate over ""
" gj, and gk added by me
nnoremap <C-n> <Cmd>call <SID>gotoEditor(v:count, 'next')<CR>
nnoremap <C-p> <Cmd>call <SID>switchEditor(v:count, 'prev')<CR>
nnoremap gj <Cmd>call <SID>gotoEditor(v:count, 'next')<CR>
nnoremap gk <Cmd>call <SID>switchEditor(v:count, 'prev')<CR>
nnoremap gh <Cmd>call VSCodeNotify('editor.action.showHover')<CR>
nnoremap gf <Cmd>call <SID>vscodeGoToDefinition('revealDeclaration')<CR>
nnoremap gd <Cmd>call <SID>vscodeGoToDefinition('revealDefinition')<CR>
"" Taken from coc-this is pretty nice
nnoremap gy <Cmd>call VSCodeNotify('editor.action.goToTypeDefinition')<CR>
nnoremap gi <Cmd>call VSCodeNotify('editor.action.goToImplementation')<CR>
nnoremap gO <Cmd>call VSCodeNotify('workbench.action.gotoSymbol')<CR>

nnoremap gF <Cmd>call VSCodeNotify('editor.action.peekDeclaration')<CR>
nnoremap gD <Cmd>call VSCodeNotify('editor.action.peekDefinition')<CR>
nnoremap gH <Cmd>call VSCodeNotify('editor.action.referenceSearch.trigger')<CR>
nnoremap gY <Cmd>call VSCodeNotify('editor.action.peekTypeDefinition')<CR>
nnoremap gI <Cmd>call VSCodeNotify('editor.action.peekImplementation')<CR>

" open quickfix menu for spelling corrections and refactoring
nnoremap z= <Cmd>call VSCodeNotify('editor.action.quickFix')<CR>
nnoremap g= <Cmd>call VSCodeNotify('editor.action.quickFix')<CR>
nnoremap g. <Cmd>call VSCodeNotify('editor.action.quickFix')<CR>

xnoremap gh <Cmd>call VSCodeNotify('editor.action.showHover')<CR>
xnoremap gf <Cmd>call <SID>vscodeGoToDefinition('revealDeclaration')<CR>
xnoremap gd <Cmd>call <SID>vscodeGoToDefinition('revealDefinition')<CR>
xnoremap gy <Cmd>call VSCodeNotify('editor.action.goToTypeDefinition')<CR>
xnoremap gi <Cmd>call VSCodeNotify('editor.action.goToImplementation')<CR>
xnoremap gO <Cmd>call VSCodeNotify('workbench.action.gotoSymbol')<CR>

xnoremap gF <Cmd>call VSCodeNotify('editor.action.peekDeclaration')<CR>
xnoremap gD <Cmd>call VSCodeNotify('editor.action.peekDefinition')<CR>
xnoremap gH <Cmd>call VSCodeNotify('editor.action.referenceSearch.trigger')<CR>
xnoremap gY <Cmd>call VSCodeNotify('editor.action.peekToTypeDefinition')<CR>
xnoremap gI <Cmd>call VSCodeNotify('editor.action.peekImplementation')<CR>

" open quickfix menu for spelling corrections and refactoring
xnoremap z= <Cmd>call VSCodeNotify('editor.action.quickFix')<CR>
xnoremap g= <Cmd>call VSCodeNotify('editor.action.quickFix')<CR>
xnoremap g. <Cmd>call VSCodeNotify('editor.action.quickFix')<CR>

" <C-w> gf opens definition on the side
nnoremap <C-w>gf <Cmd>call VSCodeNotify('editor.action.revealDefinitionAside')<CR>
nnoremap <C-w>gd <Cmd>call VSCodeNotify('editor.action.revealDefinitionAside')<CR>
xnoremap <C-w>gf <Cmd>call VSCodeNotify('editor.action.revealDefinitionAside')<CR>
xnoremap <C-w>gd <Cmd>call VSCodeNotify('editor.action.revealDefinitionAside')<CR>

"" REMOVED "" " nnoremap K <Cmd>call VSCodeNotify('editor.action.showHover')<CR>
"" REMOVED "" nnoremap <C-]> <Cmd>call <SID>vscodeGoToDefinition('revealDefinition')<CR>
"" REMOVED "" " xnoremap K <Cmd>call VSCodeNotify('editor.action.showHover')<CR>
"" REMOVED "" xnoremap <C-]> <Cmd>call <SID>vscodeGoToDefinition('revealDefinition')<CR>
"" END VS Code Commands to migrate over ""


"" Commands from keyboard shorcuts that are managed via vimrc ""
nnoremap <leader>e <Cmd>call VSCodeNotify('workbench.action.problems.focus')<CR>
nnoremap <leader>t <Cmd>call VSCodeNotify('workbench.action.terminal.toggleTerminal')<CR>


"" DEBUGGING KEYBINDINGS "" -- FIND by searching [editor.debug]  in Keyboard Shortcuts
" Debugging
nnoremap ;d <Cmd>call VSCodeNotify('workbench.action.debug.start')<CR>

nnoremap ;R <Cmd>call VSCodeNotify('workbench.action.debug.restart')<CR>

nnoremap ;p <Cmd>call VSCodeNotify('workbench.action.debug.pause')<CR>

nnoremap ;p <Cmd>call VSCodeNotify('workbench.action.debug.continue')<CR>
" nnoremap <S-c> <Cmd>call VSCodeNotify('workbench.action.debug.continue')<CR>
" <S-c> is already a VS Code default
nnoremap ;<SPACE> <Cmd>call VSCodeNotify('workbench.action.debug.continue')<CR>

nnoremap ;c <Cmd>call VSCodeNotify('editor.debug.action.runToCursor')<CR>

nnoremap ;x <Cmd>call VSCodeNotify('workbench.action.debug.stop')<CR>

" " Debugging with some vim like keys
nnoremap <S-j> <Cmd>call VSCodeNotify('workbench.action.debug.stepOver')<CR>
nnoremap ;n <Cmd>call VSCodeNotify('workbench.action.debug.stepOver')<CR>

nnoremap <S-k> <Cmd>call VSCodeNotify('workbench.action.debug.stepInto')<CR>
nnoremap ;i <Cmd>call VSCodeNotify('workbench.action.debug.stepInto')<CR>

nnoremap <S-h> <Cmd>call VSCodeNotify('workbench.action.debug.stepOut')<CR>
nnoremap ;o <Cmd>call VSCodeNotify('workbench.action.debug.stepOut')<CR>

" " Breakpoints
nnoremap <S-t> <Cmd>call VSCodeNotify('editor.debug.action.toggleBreakpoint')<CR>
nnoremap ;b <Cmd>call VSCodeNotify('workbench.debug.action.focusBreakpointsView')<CR>
nnoremap ;B <Cmd>call VSCodeNotify('workbench.debug.viewlet.action.removeAllBreakpoints')<CR>

nnoremap ;; <Cmd>call VSCodeNotify('workbench.debug.action.toggleRepl')<CR>
vnoremap ;; <Cmd>call VSCodeNotify('workbench.debug.action.toggleRepl')<CR>

nnoremap ;e <Cmd>call VSCodeNotify('editor.debug.action.selectionToRepl')<CR>
vnoremap ;e <Cmd>call VSCodeNotify('editor.debug.action.selectionToRepl')<CR>


"" EXPERIMENTAL ""
function! GetHoverInfoInVSCode()
  " Execute the VS Code command to show hover information
  call VSCodeNotify('editor.action.showHover')

  " Sleep for a short while to ensure the hover information is displayed
  sleep 100m

  " Capture the hover information (this part is more complex and might need customization)
  " Assuming that the hover information is in the 'hover' variable
  " This requires that hover information is somehow made accessible
  let l:hover_info = get(g:, 'hover', '')

  " Process the hover information
  let l:type_info = ''
  if l:hover_info =~ '(variable)'
    let l:type_info = matchstr(l:hover_info, ':\s*\zs.*')
    " Remove leading and trailing backticks
    let l:type_info = substitute(l:type_info, '^\s*```', '', '')
    let l:type_info = substitute(l:type_info, '```\s*$', '', '')
    " Remove newlines
    let l:type_info = substitute(l:type_info, '\n', '', 'g')
    " Add a space at the end
    let l:type_info = l:type_info . ' '
  endif

  return l:type_info
endfunction

function! CopyHoverInfoToClipboard()
  let l:type_info = GetHoverInfoInVSCode()
  if l:type_info != ''
    call setreg('+', l:type_info)
    echom 'Type information copied to clipboard: ' . l:type_info
  else
    echom 'No variable type information found.'
  endif
endfunction

function! AppendHoverInfoToCurrentWord()
  let l:type_info = GetHoverInfoInVSCode()
  if l:type_info != ''
    " Save the current position
    let l:current_pos = getpos('.')

    " Move to the end of the current word
    normal! e

    " Append the type information
    execute "normal! a: " . l:type_info

    " Restore the cursor position
    call setpos('.', l:current_pos)

    echom 'Appended type information: ' . l:type_info
  else
    echom 'No variable type information found.'
  endif
endfunction

nnoremap <silent> ;ctc :call CopyHoverInfoToClipboard()<CR>
nnoremap <silent> ;cta :call AppendHoverInfoToCurrentWord()<CR>

function! GetHoverInfo()
  " Execute the VS Code command to show hover information
  call VSCodeNotify('editor.action.showHover')

  " Sleep for a short while to ensure the hover information is displayed
  sleep 100m

  " Get the current file URI using the Lua function
  let l:uri = luaeval('GetCurrentFileURI()')

  " Define the position parameters
  let l:position = {
        \ 'line': line('.') - 1,
        \ 'character': col('.') - 1
        \ }

  " Call the hover provider with the URI and the current cursor position
  let l:hover_result = call('VSCodeCall', ['vscode.executeHoverProvider', l:uri, l:position])

  " Process the hover result if available
  if type(l:hover_result) == type([]) && !empty(l:hover_result)
    let l:hover_text = []
    for l:hover in l:hover_result
      if has_key(l:hover.contents, 'value')
        call add(l:hover_text, l:hover.contents.value)
      endif
    endfor
    return join(l:hover_text, "\n---\n")
  endif

  return ''
endfunction

function! GetHoverInfo()
  " Execute the VS Code command to show hover information
  call VSCodeNotify('editor.action.showHover')

  " Sleep for a short while to ensure the hover information is displayed
  sleep 200m

  " Get the current file URI using the Lua function
  let l:uri = luaeval('GetCurrentFileURI()')

  " Define the position parameters
  let l:position = {
        \ 'line': line('.') - 1,
        \ 'character': col('.') - 1
        \ }

  " Prepare the arguments for the VSCodeCall
  let l:args = [l:uri, l:position]

  " Call the hover provider with the URI and the current cursor position
  let l:hover_result = call('VSCodeCall', ['vscode.executeHoverProvider', l:args])

  " Process the hover result if available
  if type(l:hover_result) == type([]) && !empty(l:hover_result)
    let l:hover_text = []
    for l:hover in l:hover_result
      if type(l:hover.contents) == type([])
        for l:content in l:hover.contents
          if has_key(l:content, 'value')
            call add(l:hover_text, l:content.value)
          elseif type(l:content) == type({})
            if has_key(l:content, 'value')
              call add(l:hover_text, l:content.value)
            elseif has_key(l:content, 'language')
              call add(l:hover_text, l:content.language)
            endif
          elseif type(l:content) == type(0) " String type
            call add(l:hover_text, l:content)
          endif
        endfor
      endif
    endfor
    return join(l:hover_text, "\n---\n")
  endif

  return ''
endfunction


function! EchoHoverInfo()
  let l:hover_info = GetHoverInfo()
  if l:hover_info != ''
    echom l:hover_info
  else
    echom 'No hover information found.'
  endif
endfunction

nnoremap <silent> <leader>hi :call EchoHoverInfo()<CR>


