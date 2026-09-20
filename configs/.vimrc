" VIM Configuration Profile

" Use the PowerLine plugin. Auto-detect the installed Python 3 version's
" site-packages path instead of hardcoding it (Ubuntu ships a newer Python 3
" with every release, so a fixed version number like python3.8 goes stale).
for s:powerline_bindings in split(glob($HOME . '/.local/lib/python3*/site-packages/powerline/bindings/vim'), '\n')
  execute 'set rtp+=' . s:powerline_bindings
endfor

" Always show statusline
set laststatus=2

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

" Always show the command as it is being typed.
set showcmd

