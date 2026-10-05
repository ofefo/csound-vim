" this file is part of csound-vim
" https://github.com/luisjure/csound-vim
" Language:	csound	
" Maintainer:	luis jure <lj@eumus.edu.uy>
" License:	MIT
" Last Change:	2024-01-18

" configure dictionary for autocompletion
au FileType csound execute 'setlocal dict=<sfile>:p:h:h/words/csound.txt'
au FileType csound execute 'setlocal complete+=k'
au FileType csound execute 'setlocal completeopt=longest,menuone'

" detect OS 
if !exists("g:os")
  if has("win32")
    let g:os = "Windows"
  elseif has("haiku")
    let g:os = "Haiku"
  elseif has("unix")
    if system('uname')=~?'Darwin'
      let g:os = "OSX"
    elseif system('uname')=~?'Linux'
      let g:os = "Linux"
    elseif system('uname')=~?'MINGW'
      let g:os = "Mingw"
    endif
  endif
endif

" stops the running csound process and closes its window
function! CsoundStop() abort
  let l:stopped = 0
  for l:w in getwininfo()
    let l:buf = winbufnr(l:w.winid)
    if l:buf > 0 && getbufvar(l:buf, '&buftype') ==# 'terminal'
      let l:job = getbufvar(l:buf, 'terminal_job_id', 0)
      if l:job > 0
        call chansend(l:job, "\003")
        sleep 200m
        call jobstop(l:job)
        let l:stopped = 1
      endif
      execute win_execute(l:w.winid, 'bwipeout!')
    endif
  endfor
  if !l:stopped
    echohl WarningMsg
    echomsg 'csound-vim: no running csound to stop'
    echohl None
  endif
endfunction

" load macros from a file
let mycsound_macros=globpath(&rtp, "macros/mycsound_macros")

" open the manual page for the opcode under the cursor
function! OpenManual()
  if !exists ("g:csound_manual")
    let manual_dir = "http://csound.github.io/docs/manual/"
  else
    let manual_dir = resolve(expand(g:csound_manual))
  endif
  let opcode = expand("<cword>")
  let manual_page = manual_dir . "/" . opcode . ".html"
  if g:os == "Linux"
    let l:cmd = 'xdg-open ' . shellescape(manual_page)
  elseif g:os == "OSX"
    let l:cmd = 'open ' . shellescape(manual_page)
  elseif g:os == "Windows"
    let l:cmd = 'start cmd /c start "" ' . shellescape(manual_page)
  elseif g:os == "Mingw"
    let l:cmd = 'start "" ' . shellescape(manual_page)
  elseif g:os == "Haiku"
    let l:cmd = 'open ' . shellescape(manual_page)
  else
    echohl ErrorMsg
    echomsg 'csound-vim: cannot detect your OS; set g:os in your vimrc'
    echohl None
    return
  endif
  echomsg 'csound-vim: ' . l:cmd
  let l:out = system(l:cmd . ' 2>&1')
  if v:shell_error
    echohl ErrorMsg
    echomsg 'csound-vim: failed (exit ' . v:shell_error . ') ' . l:out
    echohl None
  elseif l:out =~# '\S'
    echomsg 'csound-vim: ' . l:out
  endif
endfunction

" open the example csd for the opcode under the cursor
function! OpenExample()
  if exists ("g:csound_manual")
    let opcode = expand("<cword>")
    let examplecsd = resolve(expand(g:csound_manual)) . "/examples/" . opcode . ".csd"
    if filereadable(examplecsd)
  	  execute "tabnew | silent view" examplecsd
    else
  	  echo examplecsd "does not exist"
    endif
  else
    echo 'the variable g:csound_manual does not exist'
    echo 'set it in your .vimrc pointing to the html csound manual'
  endif
endfunction

" enable the manual key mappings by default
if !exists('g:csound_enable_manual_keys')
	let g:csound_enable_manual_keys = 1
endif
if g:csound_enable_manual_keys
	noremap <F1> :call OpenManual()<CR>
	noremap <F2> :call OpenExample()<CR>
endif
