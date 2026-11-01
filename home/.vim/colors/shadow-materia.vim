" shadow-materia.vim — paleta Shadow Materia (híbrida M3, PALETA-HIBRIDA.md)
" Escuro, true color (termguicolors); no TTY cai nas 16 cores do terminal.
hi clear
if exists('syntax_on') | syntax reset | endif
set background=dark
let g:colors_name = 'shadow-materia'

" Paleta
let s:p = {
  \ 'bg':      ['#131314', 'NONE'],
  \ 'bg_lat':  ['#161718', 0],
  \ 'ct':      ['#1A1A1C', 0],
  \ 'ct_hi':   ['#222324', 0],
  \ 'ct_max':  ['#2C2C2D', 0],
  \ 'div':     ['#323235', 8],
  \ 'div_hi':  ['#49494B', 8],
  \ 'fg':      ['#F0EDEE', 15],
  \ 'fg2':     ['#ACABAD', 7],
  \ 'dim':     ['#919093', 8],
  \ 'blue':    ['#5294E2', 4],
  \ 'blue_lt': ['#8AB8F0', 12],
  \ 'blue_ct': ['#183A61', 4],
  \ 'on_blue': ['#0B0D10', 0],
  \ 'sec':     ['#3B5170', 4],
  \ 'purple':  ['#B98EFF', 13],
  \ 'cyan':    ['#62C7E0', 14],
  \ 'green':   ['#78CA9F', 10],
  \ 'yellow':  ['#F2DA66', 11],
  \ 'red':     ['#F28B82', 9],
  \ 'on_red':  ['#370303', 0],
  \ 'none':    ['NONE', 'NONE'],
  \ }

function! s:hi(grupo, fg, bg, ...) abort
  let l:attr = a:0 ? a:1 : 'NONE'
  let l:sp = a:0 > 1 ? ' guisp=' . s:p[a:2][0] : ''
  exe 'hi' a:grupo
    \ 'guifg=' . s:p[a:fg][0] 'ctermfg=' . s:p[a:fg][1]
    \ 'guibg=' . s:p[a:bg][0] 'ctermbg=' . s:p[a:bg][1]
    \ 'gui=' . l:attr 'cterm=' . l:attr . l:sp
endfunction

" Interface
call s:hi('Normal',       'fg',      'bg')
call s:hi('NormalFloat',  'fg',      'ct_hi')
call s:hi('LineNr',       'div_hi',  'none')
call s:hi('CursorLineNr', 'blue_lt', 'none', 'bold')
call s:hi('CursorLine',   'none',    'ct')
call s:hi('CursorColumn', 'none',    'ct')
call s:hi('ColorColumn',  'none',    'ct')
call s:hi('SignColumn',   'dim',     'none')
call s:hi('FoldColumn',   'div_hi',  'none')
call s:hi('Folded',       'dim',     'ct')
call s:hi('VertSplit',    'div',     'none')
call s:hi('WinSeparator', 'div',     'none')
call s:hi('StatusLine',   'fg',      'ct_hi')
call s:hi('StatusLineNC', 'dim',     'ct')
call s:hi('TabLine',      'dim',     'ct')
call s:hi('TabLineFill',  'none',    'bg_lat')
call s:hi('TabLineSel',   'on_blue', 'blue', 'bold')
call s:hi('Pmenu',        'fg',      'ct_hi')
call s:hi('PmenuSel',     'fg',      'blue_ct', 'bold')
call s:hi('PmenuSbar',    'none',    'ct_max')
call s:hi('PmenuThumb',   'none',    'div_hi')
call s:hi('Visual',       'none',    'blue_ct')
call s:hi('Search',       'on_blue', 'yellow')
call s:hi('IncSearch',    'on_blue', 'blue_lt', 'bold')
call s:hi('CurSearch',    'on_blue', 'blue_lt', 'bold')
call s:hi('MatchParen',   'blue_lt', 'div', 'bold')
call s:hi('NonText',      'div_hi',  'none')
call s:hi('EndOfBuffer',  'div',     'none')
call s:hi('SpecialKey',   'div_hi',  'none')
call s:hi('Whitespace',   'div',     'none')
call s:hi('Directory',    'blue_lt', 'none')
call s:hi('Title',        'blue_lt', 'none', 'bold')
call s:hi('ErrorMsg',     'red',     'none', 'bold')
call s:hi('WarningMsg',   'yellow',  'none')
call s:hi('ModeMsg',      'fg2',     'none', 'bold')
call s:hi('MoreMsg',      'green',   'none')
call s:hi('Question',     'green',   'none')
call s:hi('WildMenu',     'fg',      'blue_ct')
call s:hi('QuickFixLine', 'none',    'blue_ct')
call s:hi('SpellBad',     'none',    'none', 'undercurl', 'red')
call s:hi('SpellCap',     'none',    'none', 'undercurl', 'yellow')
call s:hi('SpellRare',    'none',    'none', 'undercurl', 'purple')
call s:hi('SpellLocal',   'none',    'none', 'undercurl', 'cyan')
call s:hi('DiffAdd',      'green',   'ct')
call s:hi('DiffChange',   'yellow',  'ct')
call s:hi('DiffDelete',   'red',     'ct')
call s:hi('DiffText',     'on_blue', 'yellow')

" Sintaxe
call s:hi('Comment',      'dim',     'none', 'italic')
call s:hi('Constant',     'purple',  'none')
call s:hi('String',       'green',   'none')
call s:hi('Character',    'green',   'none')
call s:hi('Number',       'purple',  'none')
call s:hi('Boolean',      'purple',  'none')
call s:hi('Float',        'purple',  'none')
call s:hi('Identifier',   'fg',      'none')
call s:hi('Function',     'blue_lt', 'none')
call s:hi('Statement',    'blue',    'none', 'bold')
call s:hi('Operator',     'fg2',     'none')
call s:hi('PreProc',      'cyan',    'none')
call s:hi('Type',         'yellow',  'none')
call s:hi('Special',      'cyan',    'none')
call s:hi('Delimiter',    'fg2',     'none')
call s:hi('Underlined',   'blue_lt', 'none', 'underline')
call s:hi('Ignore',       'div',     'none')
call s:hi('Error',        'on_red',  'red')
call s:hi('Todo',         'on_blue', 'yellow', 'bold')

" Diff/git em arquivos de patch e mensagens de commit
hi! link diffAdded   DiffAdd
hi! link diffRemoved DiffDelete
hi! link diffChanged DiffChange
call s:hi('gitcommitSummary', 'fg', 'none', 'bold')
