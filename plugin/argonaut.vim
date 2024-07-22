" Argonaut
"
" A Vim plugin that provides a rich interface through which other Vim plugins
" can create and parse command arguments.
"
" Author:       cwshugg
" Repository:   https://github.com/cwshugg/argonaut.vim
" Version:      0.0.1

" Make sure we don't load this plugin more than once!
if exists('g:argonaut_initialized')
    finish
endif
let g:argonaut_initialized = 1

" Creates a safe command alias for commands that begin with ':'.
"
" * 'alias' represents the string that will become the new alias.
" * 'source' represents the existing command you wish to create an alias for.
"
" Credit to this StackOverflow post:
" https://stackoverflow.com/questions/3878692/how-to-create-an-alias-for-a-command-in-vim
function! s:create_command_alias(source, alias)
      exec 'cnoreabbrev <expr> '.a:alias
         \ .' ((getcmdtype() is# ":" && getcmdline() is# "'.a:alias.'")'
         \ .'? ("'.a:source.'") : ("'.a:alias.'"))'
endfunction


function! s:argonaut_test_completion(arg, line, pos)
    return ['-h', '--hello', '+gb', '++goodbye']
endfunction

" DEBUGGING - TODO - REMOVE WHEN DONE DEVELOPING
command! 
    \ -nargs=*
    \ -complete=customlist,s:argonaut_test_completion
    \ ArgonautTest
    \ call argonaut#commands#test(<f-args>)
call s:create_command_alias('ArgonautTest', 'ArgTest')

