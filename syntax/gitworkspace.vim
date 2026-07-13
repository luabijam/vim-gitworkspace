if exists("b:current_syntax")
  finish
endif

syn sync fromstart

syn match GwRepo   /^[▼▶] \S\+/ contains=GwBranch
syn match GwBranch /\[.*\]/ contained
syn match GwUnstagedHeading /^  ▼ Unstaged (\d\+)$/
syn match GwStagedHeading   /^  ▼ Staged (\d\+)$/
syn match GwUnstagedModifier "^     M " nextgroup=GwFile
syn match GwUntrackedModifier "^    ?? " nextgroup=GwFile
syn match GwStagedModifier   "^    [MADRC] " nextgroup=GwFile
syn match GwFile "\S.*$" contained

hi def link GwRepo               Label
hi def link GwBranch             Comment
hi def link GwUnstagedHeading    Macro
hi def link GwStagedHeading      Include
hi def link GwUnstagedModifier   Structure
hi def link GwUntrackedModifier  StorageClass
hi def link GwStagedModifier     Typedef
hi def link GwFile               String

let b:current_syntax = "gitworkspace"
