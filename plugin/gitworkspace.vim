if exists('g:loaded_gitworkspace')
  finish
endif
let g:loaded_gitworkspace = 1

command! GitWorkspace call gitworkspace#Run()
nnoremap <silent> <leader>ga :call gitworkspace#ToggleWindow()<CR>
