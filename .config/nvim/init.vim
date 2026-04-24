call plug#begin()

" List your plugins here
Plug 'kien/ctrlp.vim'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'ellisonleao/gruvbox.nvim'
Plug 'preservim/nerdtree'
Plug 'frazrepo/vim-rainbow'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'easymotion/vim-easymotion'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'OXY2DEV/markview.nvim'

call plug#end()

colorscheme gruvbox
set tabstop=4 autoindent shiftwidth=4 expandtab number
set smartcase ignorecase
set incsearch
set backspace=indent,eol,start
set listchars=tab:▸\ ,trail:·
set list
set mouse=
set relativenumber

let mapleader="\<space>"

map <c-i> :tabn<CR>

"Easy quotes life
inoremap "" ""<left>
inoremap "<CR> {<CR>}<Esc>O<Tab>
inoremap ''' '''<left>
inoremap () ()<left>
inoremap (<CR> (<CR>)<Esc>O<Tab>
inoremap {} {}<left>
inoremap {<CR> {<CR>}<Esc>O<Tab>
inoremap [] []<left>
inoremap [<CR> [<CR>]<Esc>O<Tab>
inoremap <> <><left>
inoremap <C-a> <right>
nmap <Leader>' ysiw'
nmap <Leader>" ysiw"
noremap <Leader>/ :Commentary<cr>

" jk kj to exit insert mode
inoremap jk <Esc>
inoremap kj <Esc>

" Coc settings
inoremap <expr> <cr> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"
inoremap <expr> <Tab> coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"
inoremap <expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<S-Tab>"
nmap <Leader>gd :call CocActionAsync('jumpDefinition')<cr>

" The silver-searcher Ag find in files
nmap <Leader>f :Ag<cr>

" Jump settings
:nmap <Leader>b <C-O>
:nmap <Leader>n <C-I>

" $ in visual mode should jump one less
vnoremap $ $<left>

" Format raw json using jq
function! FormatJson()
        %!jq .
        let &syntax = "json"
endfunction
noremap <Leader>fj :call FormatJson()<cr>

" yank and paste from clipboard
noremap <Leader>y "+y
noremap <Leader>p "+p

