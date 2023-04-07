call plug#begin('~/.vim/plugged')
" Add plugins here
call plug#end()

set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent

set number
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup END

inoremap jj <Esc>
inoremap ;; <Esc>

nnoremap G Gzz
nnoremap z zz
nnoremap <C-b> <C-b>zz
nnoremap <C-d> <C-d>zz
nnoremap <C-f> <C-f>zz
nnoremap <C-u> <C-u>zz
nnoremap <leader>x :!chmod +x %<CR>
