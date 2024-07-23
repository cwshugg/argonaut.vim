" Argonaut
"
" A Vim plugin that provides a rich interface to create and parse command-line
" arguments for Vim commands. This is useful for other Vim plugins and user
" commands.
"
" Author:       cwshugg
" Repository:   https://github.com/cwshugg/argonaut.vim

" Make sure we don't load this plugin more than once!
if exists('g:argonaut_initialized')
    finish
endif
let g:argonaut_initialized = 1

let s:test_args = []
let s:test_arg = argonaut#arg#new(
    \ [
        \ argonaut#argid#new('-', 'h'),
        \ argonaut#argid#new('--', 'hello')
    \ ],
    \ 1, 1, 0
\ )
call add(s:test_args, s:test_arg)
let s:test_arg = argonaut#arg#new(
    \ [
        \ argonaut#argid#new('+', 'g'),
        \ argonaut#argid#new('++', 'goodbye'),
        \ argonaut#argid#new('+++', 'GOODBYE', 0)
    \ ],
    \ 0, 1, 1
\ )
call add(s:test_args, s:test_arg)
let s:test_argset = argonaut#argset#new(s:test_args)
let s:test_argparser = argonaut#argparser#new(s:test_argset)

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
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:test_argset)
endfunction

" DEBUGGING - TODO - REMOVE WHEN DONE DEVELOPING
command! 
    \ -nargs=*
    \ -complete=customlist,s:argonaut_test_completion
    \ ArgonautTest
    \ call argonaut#commands#test(<f-args>)
call s:create_command_alias('ArgonautTest', 'ArgTest')

