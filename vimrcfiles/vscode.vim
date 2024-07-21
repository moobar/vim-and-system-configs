nnoremap gj <Cmd>call <SID>gotoEditor(v:count, 'next')<CR>
nnoremap gk <Cmd>call <SID>switchEditor(v:count, 'prev')<CR>

"" VS Code Commands to migrate over ""
"" REMOVED "" " nnoremap K <Cmd>call VSCodeNotify('editor.action.showHover')<CR>
"" REMOVED "" nnoremap <C-]> <Cmd>call <SID>vscodeGoToDefinition('revealDefinition')<CR>

nnoremap gh <Cmd>call VSCodeNotify('editor.action.showHover')<CR>
nnoremap gf <Cmd>call <SID>vscodeGoToDefinition('revealDeclaration')<CR>
nnoremap gd <Cmd>call <SID>vscodeGoToDefinition('revealDefinition')<CR>
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

"" REMOVED "" " xnoremap K <Cmd>call VSCodeNotify('editor.action.showHover')<CR>
"" REMOVED "" xnoremap <C-]> <Cmd>call <SID>vscodeGoToDefinition('revealDefinition')<CR>
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

"" END VS Code Commands to migrate over ""


" This has been converted to a keybinding "View: Focus Problems" which shows errors
" nmap <leader>e :CocDiagnostics<CR>



"" DEBUGGING KEYBINDINGS "" -- FIND by searching [editor.debug]  in Keyboard Shortcuts
" I set up to integrate with VS Code keymappings.json
" "" Shortcuts to make debugging better
" " for normal mode - the word under the cursor
" nmap <leader>di <Plug>VimspectorBalloonEval
" " for visual mode, the visually selected text
" xmap <leader>di <Plug>VimspectorBalloonEval
"
" nnoremap <S-c> :call vimspector#Continue()<CR>
" nnoremap <leader>dd :call vimspector#Launch()<CR>
" nnoremap <leader>dx :call vimspector#Reset()<CR>
" nnoremap <leader>dp :call vimspector#Pause()<CR>
" nnoremap <leader>dc :call vimspector#Continue()<CR>
" nnoremap <leader>ds :call vimspector#Stop()<CR>
"
" nnoremap <S-r> :call vimspector#RunToCursor()<CR>
" nnoremap <leader>dr :call vimspector#RunToCursor()<CR>
" nnoremap <leader>dD :call vimspector#ShowDisassembly()<CR>
" nnoremap <leader>dn :call vimspector#JumpToNextBreakpoint()<CR>
" nnoremap <leader>dp :call vimspector#JumpToPreviousBreakpoint()<CR>
"
" nnoremap <S-t> :call vimspector#ToggleBreakpoint()<CR>
" nnoremap <leader>db :call vimspector#ListBreakpoints()<CR>
" nnoremap <leader>dt :call vimspector#ToggleBreakpoint()<CR>
" nnoremap <leader>dT :call vimspector#ClearBreakpoints()<CR>
"
" nmap <leader>dR <Plug>VimspectorRestart
"
" nmap <S-h> <Plug>VimspectorStepOut
" nmap <S-k> <Plug>VimspectorStepInto
" nmap <S-j> <Plug>VimspectorStepOver
" nmap <leader>dh <Plug>VimspectorStepOut
" nmap <leader>dk <Plug>VimspectorStepInto
" nmap <leader>dj <Plug>VimspectorStepOver
"
