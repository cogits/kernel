" colorscheme {{{1
if ! has("gui_running")
    set t_Co=256
endif

set background=dark
colorscheme sonokai


" options {{{1
set nocompatible                             " 这个要放在最上面
set backspace=indent,eol,start
"set whichwrap=b,s,<,>,[,],h,l
" https://www.zhihu.com/question/22363620/answer/21199296
set encoding=utf-8
"set fileencodings=ucs-bom,utf-8,utf-16,cp932,cp936,gb18030,big5,euc-jp,euc-kr,latin1
set fileencodings=ucs-bom,utf-8,cp932,cp936,gb18030,big5,euc-jp,euc-kr,latin1
" :e ++enc=utf-8 [filename]         " 修改显示编码
" :set fileencoding=utf-8           " 修改文件编码

set mouse=nvr

syntax on                  " syntax highlighting
set number                 " 显示行号
set ruler                  " 在状态栏显示光标的当前位置
set rnu                    " 相对行号，可能不生效，需要手动执行
set signcolumn=number      " display signs in the 'number' column.
set showcmd                " 在底部显示，当前键入的指令

filetype plugin indent on

set tabstop=4              " 设定 tab 长度为 4
set expandtab              " 用space替代tab的输入 "某些时候一定要 Tab，而不是4个空格，比如 makefile 。。
set shiftwidth=4           " 设定 << 和 >> 命令移动时的宽度为 4, code auto indent width
set softtabstop=4          " 使得按退格键时可以一次删掉 4 个空格
set cindent                " c 语言语法缩进
set autoindent             " copy indent from current line when starting a new line
"set textwidth=120         " break lines when line length increases，没啥用，需要手动 gggqG 应用

set ignorecase             " 搜索时忽略大小写
set smartcase              " 但在有一个或以上大写字母时仍保持对大小写敏感
set wrapscan               " 搜索到文件两端时重新搜索
set hlsearch               " 查找匹配高亮 ，用 :noh 取消
set incsearch              " 在查找过程中逐字匹配高亮

set showmatch              " 插入括号时，短暂地跳转到匹配的对应括号
set matchtime=2            " 短暂跳转到匹配括号的时间
set scrolloff=5            " 距离屏幕最上或最下5行时scrollbar开始滚动
set hidden                 " 允许在有未保存的修改时切换缓冲区

set wildmenu               " vim 自身命令行模式智能补全，好像没什么用
set showmode               " 显示insert visual等模式提示
set wrap                   " 自动折行，即太长的行分成几行显示
set noerrorbells           " 出错时，不要发出响声
set updatetime=560         " 设定更新.swp 文件时间，milliseconds，此值影响taglist插件更新快慢
set fdm=manual             " 先选中行，再选中用zf折叠，或者设为syntax，用zr(zR),zm(zM),zo,zc控制


"set list                  " 显示不可视字符 , 如tab符号，行结尾符号
"set nolist
"set ff=unix
"set bomb?
"set nobomb
"set fileencoding=utf8
":%!xxd (-r)             "查看16进制

" macros {{{1
" qp"0pq     "使用 @p 粘贴
" qoviw"0pq  "使用 @o 替换一个单词
let @p = '"0p'
let @o = 'viw"0p'

":dig
" CTRL-k 两个字母



" Mappings {{{1
" 进入 paste mode，要：
" Alt+i: paste mode, i: insert mode
" Alt+i: turn off paste mode, Alt+i: normal mode
set pastetoggle=<Esc>i
inoremap <Esc>i <Esc>
xnoremap <Esc>i <Esc>
snoremap <Esc>i <Esc>

" Editing Mapping
nnoremap <leader>ev :vsplit $MYVIMRC<CR>
" Sourcing Mapping
nnoremap <leader>sv :source $MYVIMRC<CR>

" 退出窗口
noremap <silent> <Esc>w :w<CR>
noremap <silent> <Esc>q :q<CR>
noremap <silent> <Esc>` :qa<CR>

" 光标进入 上、下、左、右 的窗口
noremap <silent> <Esc>k <C-W>k
noremap <silent> <Esc>j <C-W>j
noremap <silent> <Esc>h <C-W>h
noremap <silent> <Esc>l <C-W>l

" 在插入模式下移动
inoremap <silent> <Esc>k <C-o>k
inoremap <silent> <Esc>j <C-o>j
inoremap <silent> <Esc>h <C-o>h
inoremap <silent> <Esc>l <C-o>l

" 循环移动窗口
noremap <silent> <Esc>i <C-W>w
noremap <silent> <Esc>W <C-W>W

" 新开一个竖直窗口
noremap <silent> <Esc>v <C-W>v

" 调整竖直窗口的左右间距
noremap <silent> <Esc>( :vertical resize -5<CR>
noremap <silent> <Esc>) :vertical resize +5<CR>

" 调整水平窗口的上下间距
noremap <silent> <Esc>_ :resize -5<CR>
noremap <silent> <Esc>+ :resize +5<CR>

" 当前窗口的宽度调至最大，'|' 转义
noremap <silent> <Esc>- <C-W>\|

" 所有窗口平均划分
noremap <silent> <Esc>= <C-W>=


" 把当前窗口作为新的 tab 打开
noremap <silent> <Esc>T <C-W>T

" 新开一个 tab
noremap <silent> <Esc>N :tabnew<CR>
" 关闭当前 tab
noremap <silent> <Esc>C :tabclose<CR>
" 只保留当前 tab，关闭其他（这个会干扰方向键）
"noremap <silent> <Esc>O :tabonly<CR>

" 进入前一个 tab
noremap <silent> <Esc>p :tabprevious<CR>
" 进入后一个 tab
noremap <silent> <Esc>n :tabnext<CR>

" 移动到行首/尾
noremap  <silent> <Esc>, ^
inoremap <silent> <Esc>, <C-o>^
noremap  <silent> <Esc>. $
inoremap <silent> <Esc>. <C-o>$

noremap  <silent> <Esc>m 5<C-e>
inoremap <silent> <Esc>m <C-o>5<C-e>
noremap  <silent> <Esc>; 5<C-y>
inoremap <silent> <Esc>; <C-o>5<C-y>

" 撤销
inoremap <silent> <Esc>u <C-o>u
" 小/大写
noremap  <silent> <Esc>u viwu
noremap  <silent> <Esc>U viwU
inoremap <silent> <Esc>U <C-o>viwU


" Abbreviations {{{1
iabbrev ture true
iabbrev flase false

iabbrev ctemp #include <stdio.h><CR><CR>int main()<CR>{<CR><CR>return 0;<CR>}



" Statusline {{{1
set laststatus=2

let s:bufnr = '[%n] '                                                   " Buffer number
let s:filepath = '%{bufname() != "" ? expand("%:~:.") : "[No Name]"}'   " Realtive path to the file
let s:hi_file = '%#STLFileName#' . s:filepath . '%*'                    " highlight the filename
let s:flags = '%m%r%h'                          " Modified flag [+], Readonly flag [RO], Help buffer flag [help]
let s:switchR = '%= '                           " Switch to the right side
let s:loc = 'ʟ %l/%L c %c'                      " Line and Column info
let s:separator = ' | '
let s:encoding = '%{(&fenc==""?&enc:&fenc)}'    " file encoding
let s:bomb = '%#STLBOM#%{(&bomb?"[B]":"")}%*'   " with the f**king BOM?
let s:slash = '/'
let s:ff = '%{&ff} '                            " fileformat: dos, unix, or mac?
let s:filefmt = s:encoding . s:bomb . s:slash . s:ff

" status line of current window, see `hl-StatusLine`
highlight StatusLine    cterm=bold ctermfg=251 ctermbg=none
" status lines of not-current windows
highlight StatusLineNC  cterm=None ctermfg=248 ctermbg=none
" status line of filename
highlight STLFileName   cterm=bold ctermfg=39  ctermbg=none
" status line of BOM
highlight STLBOM        cterm=bold ctermfg=208 ctermbg=none


fun! BuildStatusLine()
    " https://github.com/vim/vim/commit/1c6fd1e100fd0457375642ec50d483bcc0f61bb2
    if exists("g:statusline_winid")
        if g:statusline_winid == win_getid()        " active window
            let l:width = winwidth(0)                           " the width of the current window

            if l:width < 32                                     " if the window's width is too small,
                let l:stl = s:bufnr . s:hi_file . s:flags            " discard the right part of statusline
            elseif l:width < 45
                let l:stl = s:bufnr . s:hi_file . s:flags . s:switchR . s:loc
            else
                let l:stl = s:bufnr . s:hi_file . s:flags . s:switchR . s:loc . s:separator . s:filefmt
            endif
        else                                        " inactive window
            let l:stl = s:bufnr . s:filepath . s:flags
        endif
    else        " g:statusline_winid is not supported
        let l:stl = s:bufnr . s:hi_file . s:flags . s:switchR . s:loc . s:separator . s:filefmt
    endif

    return l:stl
endf

set statusline=%!BuildStatusLine()


augroup statusline_autocmd_group
  autocmd!
    autocmd Filetype tagbar RainbowToggleOff
augroup END



" tabline {{{1
set tabline=%!MyTabLine()

function MyTabLine()
    let s = ''
    for i in range(tabpagenr('$'))
        " select the highlighting
        if i + 1 == tabpagenr()
            let s .= '%#TabLineSel#'
        else
            let s .= '%#TabLine#'
        endif

        " set the tab page number (for mouse clicks)
        let s .= '%' . (i + 1) . 'T'

        " the label is made by MyTabLabel()
        let s .= '%{MyTabLabel(' . (i + 1) . ')} '
    endfor

    " after the last tab fill with TabLineFill and reset tab page nr
    let s .= '%#TabLineFill#%T'

    " right-align the label to close the current tab page
    if tabpagenr('$') > 1
        let s .= '%=%#TabLine#%999Xclose'
    endif

    return s
endfunction

" https://blog.csdn.net/fangkailove/article/details/107030468
function MyTabLabel(n)
    let buflist = tabpagebuflist(a:n)
    let winnr = tabpagewinnr(a:n)
    let bname = bufname(buflist[winnr - 1])

    let is_modified = 0
    let file_is_readable = file_readable(bname)
    let label = ''

    for bufnr in buflist
        " Add '+' if one of the buffers in the tab page is modified
        if !is_modified
            if getbufvar(bufnr, "&modified")
                let label = '+'
                let is_modified = 1
            endif
        endif

        " skip NERDTree and Tagbar buffer
        if !file_is_readable
            if file_readable(bufname(bufnr))
                let bname = bufname(bufnr)
                let file_is_readable = 1
            endif
        endif

        if is_modified && file_is_readable
            break
        endif
    endfor

    if bname == ""
        let bname = "[No Name]"
    endif

    return '['.a:n.label.'] '.fnamemodify(bname, ":t")
endfunction

nnoremap <leader>1 :1tabnext<CR>
nnoremap <leader>2 :2tabnext<CR>
nnoremap <leader>3 :3tabnext<CR>
nnoremap <leader>4 :4tabnext<CR>
nnoremap <leader>5 :5tabnext<CR>
nnoremap <leader>6 :6tabnext<CR>
nnoremap <leader>7 :7tabnext<CR>
nnoremap <leader>8 :8tabnext<CR>
nnoremap <leader>9 :9tabnext<CR>



" Autocmd {{{1
if has("autocmd")
    augroup default_autocmd_group
        autocmd!
        " https://stackoverflow.com/questions/16840433/forcing-vimdiff-to-wrap-lines
        " forcing vimdiff to wrap lines
        autocmd VimEnter * if &diff | execute 'windo set wrap' | endif

        " have Vim jump to the last position when reopening a file
        autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
    augroup END

    augroup comment_autocmd_group
        autocmd!
        autocmd Filetype *                  noremap <buffer> <localleader>c I#<Esc>
        autocmd FileType c\|cpp\|vala\|zig  noremap <buffer> <localleader>c I//<Esc>
        autocmd Filetype vim                noremap <buffer> <localleader>c I"<Esc>
        autocmd Filetype lua                noremap <buffer> <localleader>c I--<Esc>
    augroup END
endif


" plugins {{{1
source /usr/share/vim/vimfiles/plugin/fzf.vim

" Epilogue {{{1
" vim:set foldmethod=marker:
