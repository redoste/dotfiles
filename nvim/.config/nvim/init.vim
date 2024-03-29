" == Style ==

set number
set nowrap
set foldmethod=syntax
set foldlevelstart=20

" Disable intro
set shortmess=I

" Colors
highlight Pmenu      ctermfg=242 ctermbg=232
highlight PmenuSel   ctermfg=0 ctermbg=13
highlight NonText    ctermfg=8
highlight SpecialKey ctermfg=8

" No line numbers in terminals
autocmd TermOpen * setlocal nonumber norelativenumber

" Show white spaces
set list
set listchars=tab:>·,trail:~,extends:>,precedes:<

" Column for commit messages and mails
autocmd FileType gitcommit set colorcolumn=73
autocmd FileType mail set colorcolumn=73

" == Keyboard ==

" Bad habits
inoremap <Up> <nop>
inoremap <Down> <nop>
inoremap <Right> <nop>
inoremap <Left> <nop>

" Better paste
nnoremap p ]p
nnoremap P ]P
nnoremap <c-p> p

" Easy escape of terminals
tnoremap <esc><esc> <C-\><C-n>

" Easy buffer switch
nnoremap <silent> <C-o> :bn<CR>
nnoremap <silent> <C-i> :bp<CR>
nnoremap <silent> <C-M-o> :bdel<CR>
nnoremap <silent> <C-M-i> :bdel<CR>

" Previous / next jumps
nnoremap <silent> <Tab> <C-O>
nnoremap <silent> <S-Tab> <C-I>

" Build and format
nnoremap <silent> <F5> :silent make!<CR>
function ClangFormat()
	let l:lines="all"
	py3f /usr/share/clang/clang-format.py
endfunction
command! ClangFormat :call ClangFormat()
nnoremap <silent> <F6> :ClangFormat<CR>

" == System ==

set clipboard+=unnamedplus
set mouse=a
" Mark all buffers as `hidden` to allow switching without saving
set hidden
" Use a prompt for saving
set confirm
" Always show the quick fix buffer
autocmd QuickFixCmdPost * botright copen 6 | wincmd p

" == Plugins ==
call plug#begin()
Plug 'vim-airline/vim-airline'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'dpelle/vim-Grammalecte'
Plug 'gpanders/editorconfig.nvim'
Plug 'tikhomirov/vim-glsl'
call plug#end()

" Airline
" Enable tabs
let g:airline#extensions#tabline#enabled=1
" Show more tabs
let g:airline#extensions#tabline#ignore_bufadd_pat="!"
" Change some symbols
if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif
let g:airline_symbols.linenr = ' ln:'
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.colnr = ' c:'


" FZF
source /usr/share/vim/vimfiles/plugin/fzf.vim
nnoremap <F3> :FZF<CR>
nnoremap <F2> :Rg<CR>
nnoremap <F4> :Buffers<CR>

" coc
let g:coc_start_at_startup = 0
" Popup
nnoremap <silent> m :call CocActionAsync('dohover')<CR>
" Navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Rename
nmap cr <Plug>(coc-rename)
" Colors
highlight CocInlayHint ctermfg=242

" GitGutter
highlight GitGutterAdd    ctermfg=2
highlight GitGutterChange ctermfg=3
highlight GitGutterDelete ctermfg=1
" Fast update
set updatetime=100
" Always show left column without any color
set signcolumn=yes
highlight! link SignColumn LineNr

" Grammalecte
let g:grammalecte_cli_py="/usr/bin/grammalecte-cli.py"
