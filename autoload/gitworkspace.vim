let s:save_cpo = &cpo
set cpo&vim

function! gitworkspace#Collect() abort
  let l:csv = expand('~/.config/gita/repos.csv')
  let l:repo_paths = {}
  let l:repo_order = []
  for l:line in readfile(l:csv)
    let l:parts = split(l:line, ',')
    if len(l:parts) >= 2
      let l:repo_paths[l:parts[1]] = l:parts[0]
      call add(l:repo_order, l:parts[1])
    endif
  endfor

  let l:output = system('gita shell git status --porcelain 2>/dev/null')
  let l:repos = {}
  for l:line in split(l:output, "\n")
    let l:line = substitute(l:line, '^\s\+', '', '')
    if empty(l:line)
      continue
    endif
    let l:match = matchlist(l:line, '^\(\S\+\): \(.\)\(.\) \(.*\)$')
    if empty(l:match)
      continue
    endif
    let l:repo = l:match[1]
    let l:x = l:match[2]
    let l:y = l:match[3]
    let l:file = l:match[4]
    let l:path = get(l:repo_paths, l:repo, '')
    if empty(l:path) || empty(l:file)
      continue
    endif
    if !has_key(l:repos, l:repo)
      let l:repos[l:repo] = {'path': l:path, 'staged': [], 'unstaged': [], 'untracked': []}
    endif
    let l:fullpath = l:path . '/' . l:file
    if l:x ==# '?' && l:y ==# '?'
      call add(l:repos[l:repo].untracked, {'path': l:fullpath, 'file': l:file})
    else
      if l:x !=# ' ' && l:x !=# '?'
        call add(l:repos[l:repo].staged, {'path': l:fullpath, 'file': l:file, 'code': l:x})
      endif
      if l:y !=# ' ' && l:y !=# '?'
        call add(l:repos[l:repo].unstaged, {'path': l:fullpath, 'file': l:file, 'code': l:y})
      endif
    endif
  endfor

  let l:lines = []
  let l:paths = []
  let l:repos_info = []
  for l:repo in l:repo_order
    let l:info = get(l:repos, l:repo, {'path': l:repo_paths[l:repo], 'staged': [], 'unstaged': [], 'untracked': []})
    let l:cnt = len(l:info.staged) + len(l:info.unstaged) + len(l:info.untracked)
    let l:branch = trim(system('git -C ' . shellescape(l:info.path) . ' rev-parse --abbrev-ref HEAD 2>/dev/null'))
    let l:icon = l:cnt > 0 ? '▼' : '▶'

    call add(l:lines, l:icon . ' ' . l:repo . '  [' . l:branch . ']')
    call add(l:paths, '')
    call add(l:repos_info, {'repo': l:repo, 'path': l:info.path, 'section': '', 'file': '', 'staged': 0})

    if l:cnt == 0
      continue
    endif

    let l:unstaged_cnt = len(l:info.unstaged) + len(l:info.untracked)
    if l:unstaged_cnt > 0
      call add(l:lines, '  ▼ Unstaged (' . l:unstaged_cnt . ')')
      call add(l:paths, '')
      call add(l:repos_info, {'repo': l:repo, 'path': l:info.path, 'section': 'unstaged', 'file': '', 'staged': 0})
      for l:f in l:info.unstaged
        call add(l:lines, '     M ' . l:f.file)
        call add(l:paths, l:f.path)
        call add(l:repos_info, {'repo': l:repo, 'path': l:info.path, 'section': 'unstaged', 'file': l:f.file, 'staged': 0})
      endfor
      for l:f in l:info.untracked
        call add(l:lines, '    ?? ' . l:f.file)
        call add(l:paths, l:f.path)
        call add(l:repos_info, {'repo': l:repo, 'path': l:info.path, 'section': 'untracked', 'file': l:f.file, 'staged': 0})
      endfor
    endif
    if !empty(l:info.staged)
      call add(l:lines, '  ▼ Staged (' . len(l:info.staged) . ')')
      call add(l:paths, '')
      call add(l:repos_info, {'repo': l:repo, 'path': l:info.path, 'section': 'staged', 'file': '', 'staged': 1})
      for l:f in l:info.staged
        call add(l:lines, '    ' . l:f.code . ' ' . l:f.file)
        call add(l:paths, l:f.path)
        call add(l:repos_info, {'repo': l:repo, 'path': l:info.path, 'section': 'staged', 'file': l:f.file, 'staged': 1})
      endfor
    endif
  endfor

  return {'lines': l:lines, 'paths': l:paths, 'info': l:repos_info}
endfunction

function! gitworkspace#Maps() abort
  nnoremap <buffer> <silent> <CR> :call gitworkspace#Open()<CR>
  nnoremap <buffer> <silent> o     :call gitworkspace#Open()<CR>
  nnoremap <buffer> <silent> -     :call gitworkspace#Toggle()<CR>
  nnoremap <buffer> <silent> s     :call gitworkspace#Stage()<CR>
  nnoremap <buffer> <silent> u     :call gitworkspace#Unstage()<CR>
  nnoremap <buffer> <silent> U     :call gitworkspace#UnstageAll()<CR>
  nnoremap <buffer> <silent> dd    :call gitworkspace#Diff('Gdiffsplit')<CR>
  nnoremap <buffer> <silent> dv    :call gitworkspace#Diff('Gvdiffsplit')<CR>
  nnoremap <buffer> <silent> dh    :call gitworkspace#Diff('Ghdiffsplit')<CR>
  nnoremap <buffer> <silent> X     :call gitworkspace#Discard()<CR>
  nnoremap <buffer> <silent> gI    :call gitworkspace#Ignore()<CR>
  nnoremap <buffer> <silent> R     :call gitworkspace#Refresh()<CR>
  nnoremap <buffer> <silent> q     :bd!<CR>
  nnoremap <buffer> <silent> g?    :call gitworkspace#Help()<CR>
endfunction

function! s:CurrentInfo() abort
  let l:idx = line('.') - 1
  return get(b:git_workspace_info, l:idx, {})
endfunction

function! s:GitCmd(repo, args) abort
  call system('git -C ' . shellescape(a:repo) . ' ' . a:args)
endfunction

function! gitworkspace#Render(data) abort
  setlocal modifiable noro
  silent 1,$delete _
  call setline(1, a:data.lines)
  let b:git_workspace_paths = a:data.paths
  let b:git_workspace_info = a:data.info
  setlocal readonly nomodifiable
endfunction

function! gitworkspace#Open() abort
  let l:idx = line('.') - 1
  let l:path = get(b:git_workspace_paths, l:idx, '')
  if empty(l:path)
    return
  endif
  wincmd p
  exec 'edit ' . fnameescape(l:path)
endfunction

function! gitworkspace#Toggle() abort
  let l:info = s:CurrentInfo()
  if empty(l:info) || empty(l:info.file)
    return
  endif
  if l:info.staged
    call s:GitCmd(l:info.path, 'reset -q -- ' . shellescape(l:info.file))
  else
    call s:GitCmd(l:info.path, 'add -- ' . shellescape(l:info.file))
  endif
  call gitworkspace#Refresh()
endfunction

function! gitworkspace#Stage() abort
  let l:info = s:CurrentInfo()
  if empty(l:info) || empty(l:info.file)
    return
  endif
  call s:GitCmd(l:info.path, 'add -- ' . shellescape(l:info.file))
  call gitworkspace#Refresh()
endfunction

function! gitworkspace#Unstage() abort
  let l:info = s:CurrentInfo()
  if empty(l:info) || empty(l:info.file)
    return
  endif
  call s:GitCmd(l:info.path, 'reset -q -- ' . shellescape(l:info.file))
  call gitworkspace#Refresh()
endfunction

function! gitworkspace#UnstageAll() abort
  let l:info = s:CurrentInfo()
  if empty(l:info)
    return
  endif
  call s:GitCmd(l:info.path, 'reset -q')
  call gitworkspace#Refresh()
endfunction

function! gitworkspace#Diff(cmd) abort
  let l:info = s:CurrentInfo()
  if empty(l:info) || empty(l:info.file)
    return
  endif
  let l:path = l:info.path . '/' . l:info.file
  wincmd p
  exec 'edit ' . fnameescape(l:path)
  exec a:cmd
endfunction

function! gitworkspace#Discard() abort
  let l:info = s:CurrentInfo()
  if empty(l:info) || empty(l:info.file)
    return
  endif
  if l:info.section ==# 'untracked'
    call system('rm -f ' . shellescape(l:info.path . '/' . l:info.file))
  else
    call s:GitCmd(l:info.path, 'checkout -- ' . shellescape(l:info.file))
  endif
  call gitworkspace#Refresh()
endfunction

function! gitworkspace#Ignore() abort
  let l:info = s:CurrentInfo()
  if empty(l:info) || empty(l:info.file)
    return
  endif
  let l:entry = l:info.file
  if l:entry =~# '/'
    let l:entry = '/' . l:entry
  endif
  call writefile([l:entry], l:info.path . '/.gitignore', 'a')
  call gitworkspace#Refresh()
endfunction

function! gitworkspace#Refresh() abort
  let l:info = s:CurrentInfo()
  let l:target = ''
  if !empty(l:info) && !empty(l:info.file)
    let l:target = l:info.file
  endif
  let l:data = gitworkspace#Collect()
  call gitworkspace#Render(l:data)
  if !empty(l:target)
    call search(l:target, 'w')
  endif
endfunction

function! gitworkspace#Help() abort
  echo 'GitWorkspace keys: CR=open  -=toggle  s=stage  u=unstage  U=unstage-all  dd=diff  dv=vdiff  dh=hdiff  X=discard  gI=ignore  R=refresh  q=quit'
endfunction

function! gitworkspace#ToggleWindow() abort
  for l:w in range(1, winnr('$'))
    if getbufvar(winbufnr(l:w), '&filetype') ==# 'gitworkspace'
      exec l:w . 'wincmd c'
      return
    endif
  endfor
  GitWorkspace
endfunction

function! gitworkspace#Run() abort
  let l:data = gitworkspace#Collect()
  if empty(l:data.lines)
    echohl WarningMsg | echo 'No changes in any gita repo' | echohl None
    return
  endif

  let l:gw_win = 0
  for l:w in range(1, winnr('$'))
    if getbufvar(winbufnr(l:w), '&filetype') ==# 'gitworkspace'
      let l:gw_win = l:w
      break
    endif
  endfor

  if l:gw_win > 0
    exec l:gw_win . 'wincmd w'
    call gitworkspace#Render(l:data)
  else
    botright vert new
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
    setlocal nonumber norelativenumber signcolumn=no
    exec 'vertical resize ' . (&columns / 2)
    setlocal filetype=gitworkspace
    call gitworkspace#Render(l:data)
    call gitworkspace#Maps()
  endif

  echohl Title | echo 'GitWorkspace: -=toggle  s=stage  u=unstage  dd=diff  X=discard  R=refresh  q=quit  g?=help' | echohl None
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
