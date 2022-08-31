function! fzf#decls#cmd(...) abort
  let normal_fg = s:code("Normal", "fg")
  let normal_bg = s:code("Normal", "bg")
  let cursor_fg = s:code("CursorLine", "fg")
  let cursor_bg = s:code("CursorLine", "bg")
  let colors = printf(" --color %s%s%s%s%s",
        \ &background,
        \ empty(normal_fg) ? "" : (",fg:".normal_fg),
        \ empty(normal_bg) ? "" : (",bg:".normal_bg),
        \ empty(cursor_fg) ? "" : (",fg+:".cursor_fg),
        \ empty(cursor_bg) ? "" : (",bg+:".cursor_bg),
        \)
  call fzf#run(fzf#wrap('GoDecls', {
        \ 'source': <sid>source(0),
        \ 'options': printf('-n 1 --with-nth 1,2 --delimiter=$''\t'' --preview "echo {3}" --ansi --prompt "GoDecls> " --expect=ctrl-t,ctrl-v,ctrl-x%s', colors),
        \ 'sink*': function('s:sink')
        \ }))
endfunction

function! s:code(group, attr) abort
  let code = synIDattr(synIDtrans(hlID(a:group)), a:attr, "cterm")
  if code =~ '^[0-9]\+$'
    return code
  endif
endfunction

function! s:color(str, group) abort
  let fg = s:code(a:group, "fg")
  let bg = s:code(a:group, "bg")
  let bold = s:code(a:group, "bold")
  let italic = s:code(a:group, "italic")
  let reverse = s:code(a:group, "reverse")
  let underline = s:code(a:group, "underline")
  let color = (empty(fg) ? "" : ("38;5;".fg)) .
            \ (empty(bg) ? "" : (";48;5;".bg)) .
            \ (empty(bold) ? "" : ";1") .
            \ (empty(italic) ? "" : ";3") .
            \ (empty(reverse) ? "" : ";7") .
            \ (empty(underline) ? "" : ";4")
  let l:out = printf("\x1b[%sm%s\x1b[m", color, a:str)
  return  l:out
endfunction

function! s:sink(str) abort
  if len(a:str) < 2
    return
  endif
  try
    " we jump to the file directory so we can get the fullpath via fnamemodify
    " below
    let l:dir = s:chdir(s:current_dir)

    let vals = matchlist(a:str[1], '|\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)|')

    " i.e: main.go
    let filename =  vals[1]
    let line =  vals[2]
    let col =  vals[3]

    " i.e: /Users/fatih/vim-go/main.go
    let filepath =  fnamemodify(filename, ":p")

    let cmd = get({'ctrl-x': 'split',
          \ 'ctrl-v': 'vertical split',
          \ 'ctrl-t': 'tabe'}, a:str[0], 'e')
    execute cmd fnameescape(filepath)
    call cursor(line, col)
    silent! norm! zvzz
  finally
    "jump back to old dir
    call s:chdir(l:dir)
  endtry
endfunction

function! s:testSource() abort 
 let ret_decls = []
 let l:cmd = ['motion',
        \ '-format', 'vim',
        \ '-mode', 'decls',
        \ '-include', s:declsIncludes(),
        \ ]

  call s:autowrite()

  " current file mode
  let l:fname = expand("%:p")
  if a:0 && !empty(a:1)
    let l:fname = a:1
   endif

  let cmd += ['-file', l:fname]
 
  let l:out =  call('system', [l:cmd])

  let result = eval(out)
  if type(result) != 4 || !has_key(result, 'decls')
    return ret_decls
  endif

  let decls = result.decls

  " find the maximum function name
  let max_len = 0
  for decl in decls
    if len(decl.ident)> max_len
      let max_len = len(decl.ident)
    endif
  endfor

  for decl in decls
    " paddings
    let space = " "
    for i in range(max_len - len(decl.ident))
      let space .= " "
    endfor

    let pos = printf("|%s:%s:%s|",
          \ fnamemodify(decl.filename, ":t"),
          \ decl.line,
          \ decl.col
          \)
    call add(ret_decls, printf("%s\t%s\t%s\t%s",
          \ s:color(decl.ident . space, "goDeclsFzfFunction"),
          \ s:color(decl.keyword, "goDeclsFzfKeyword"),
          \ s:color(decl.full, "goDeclsFzfComment"),
          \ s:color(pos, "goDeclsFzfSpecialComment"),
          \))
  endfor

  return sort(ret_decls)
endfunction




function! s:source(mode,...) abort
  let s:current_dir = expand('%:p:h')
  let ret_decls = []

  let l:cmd = ['motion',
        \ '-format', 'vim',
        \ '-mode', 'decls',
        \ '-include', s:declsIncludes(),
        \ ]

  call s:autowrite()

  if a:mode == 0
    " current file mode
    let l:fname = expand("%:p")
    if a:0 && !empty(a:1)
      let l:fname = a:1
    endif

    let cmd += ['-file', l:fname]
  else
    " all functions mode
    if a:0 && !empty(a:1)
      let s:current_dir = a:1
    endif

    let l:cmd += ['-dir', s:current_dir]
  endif

  let [l:out, l:err] = s:exec(l:cmd)
  if l:err		
    call s:echoError(l:out)		
    return		
  endif
  let result = eval(out)
  if type(result) != 4 || !has_key(result, 'decls')
    return ret_decls
  endif

  let decls = result.decls

  " find the maximum function name
  let max_len = 0
  for decl in decls
    if len(decl.ident)> max_len
      let max_len = len(decl.ident)
    endif
  endfor

  for decl in decls
    " paddings
    let space = " "
    for i in range(max_len - len(decl.ident))
      let space .= " "
    endfor

    let pos = printf("|%s:%s:%s|",
          \ fnamemodify(decl.filename, ":t"),
          \ decl.line,
          \ decl.col
          \)
    call add(ret_decls, printf("%s\t%s\t%s\t%s",
          \ s:color(decl.ident . space, "goDeclsFzfFunction"),
          \ s:color(decl.keyword, "goDeclsFzfKeyword"),
          \ s:color(decl.full, "goDeclsFzfComment"),
          \ s:color(pos, "goDeclsFzfSpecialComment"),
          \))
  endfor

  return sort(ret_decls)
endfunc

function! s:chdir(dir) abort
  if !exists('*chdir')
    let l:olddir = getcwd()
    let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd' : 'cd'
    execute printf('%s %s', cd, fnameescape(a:dir))
    return l:olddir
  endif
  return chdir(a:dir)
endfunction

function! s:declsIncludes() abort
  return get(g:, 'go_decls_includes', 'func,type')
endfunction

function! s:autowrite() abort
  if &autowrite == 1 || &autowriteall == 1
    silent! wall
  else
    for l:nr in range(0, bufnr('$'))
      if buflisted(l:nr) && getbufvar(l:nr, '&modified')
        " Sleep one second to make sure people see the message. Otherwise it is
        " often immediately overwritten by the async messages (which also
        " doesn't invoke the "hit ENTER" prompt).
        call s:echoWarning('[No write since last change]')
        sleep 1
        return
      endif
    endfor
  endif
endfunction

function! s:echoWarning(msg)
  call s:echo(a:msg, 'WarningMsg')
endfunction

function! s:echo(msg, hi)
  let l:msg = []
  if type(a:msg) != type([])
    let l:msg = split(a:msg, "\n")
  else
    let l:msg = a:msg
  endif

  " Tabs display as ^I or <09>, so manually expand them.
  let l:msg = map(l:msg, 'substitute(v:val, "\t", "        ", "")')

  exe 'echohl ' . a:hi
  for line in l:msg
    echom "gomotion: " . line
  endfor
  echohl None
endfunction

function! fzf#decls#test() abort 
  echom s:source(0)
endfunc

" Exec runs a shell command "cmd", which must be a list, one argument per item.
" Every list entry will be automatically shell-escaped
" Every other argument is passed to stdin.
function! s:exec(cmd, ...) abort
  if len(a:cmd) == 0
    call s:echoError("exec() called with empty a:cmd")
    return ['', 1]
  endif

  " Finally execute the command using the full, resolved path. Do not pass the
  " unmodified command as the correct program might not exist in $PATH.
  "let l:which = 'which ' . a:cmd[0]
  " let l:bin = system(l:which) 

  let l:bin = a:cmd[0] 
  let l:cmd = s:shellJoin([l:bin] + a:cmd[1:])
  let l:out = call('system', [l:cmd])
  return [l:out, s:shellError()]
endfunction

function! s:shellError() abort
  return v:shell_error
endfunction

function! s:shellJoin(arglist, ...) abort
  try
    let ssl_save = &shellslash
    set noshellslash
    if a:0
      return join(map(copy(a:arglist), 'shellescape(v:val, ' . a:1 . ')'), ' ')
    endif

    return join(map(copy(a:arglist), 'shellescape(v:val)'), ' ')
  finally
    let &shellslash = ssl_save
  endtry
endfunction

function! s:echoError(msg)
  call s:echo(a:msg, 'ErrorMsg')
endfunction

