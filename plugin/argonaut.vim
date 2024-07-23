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
let g:argonaut_version = '0.0.1'

" Global settings
" TODO


" =========================== Introductory Command =========================== "
" Argonaut does not provide any commands (besides this one), because it is a
" plugin intended to make writing other plugins easier. This command provides
" introductory information about Argonaut.
"
" It also serves as a simple example of what can be done with the plugin.

let s:command_args = []

" OPTION 1 - Help
" This provides a basic help menu.
let s:command_arg = argonaut#arg#new([
        \ argonaut#argid#new('-', 'h'),
        \ argonaut#argid#new('--', 'help')
    \ ],
    \ 'Displays a help menu.'
\ )
" Presence count minimum = 0. The argument is not required to be specified.
call argonaut#arg#set_presence_count_min(s:command_arg, 0)
" Presence count minimum = 1. The argument can be specified a maximum of once.
call argonaut#arg#set_presence_count_max(s:command_arg, 1)
" This argument does not accept an value immediately after it is specified.
call argonaut#arg#set_value_required(s:command_arg, 0)
call add(s:command_args, s:command_arg)


let s:command_arg = argonaut#arg#new([
        \ argonaut#argid#new('-', 'n'),
        \ argonaut#argid#new('--', 'name')
    \ ],
    \ 'Accepts your name as input.',
    \ 0, 2, 1, 'VALUE'
\ )
call add(s:command_args, s:command_arg)


" Intialize an argument set. This contains all of the above option
" definitions.
let s:command_argset = argonaut#argset#new(s:command_args)

" We'll define a local function to use argonaut's built-in command completion.
" This utilizes the argument set to match up the user's input to available
" options.
function! s:argonaut_command_completion(arg, line, pos)
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:command_argset)
endfunction

" Here's the main function for the command. We'll have the command definition
" (below) invoke this function.
function! s:argonaut_command(input)
    " Create an argument parser object, and pass it the argument set, so it
    " knows what options to look for. Then, invoke the parsing function.
    let s:parser = argonaut#argparser#new(s:command_argset)
    call argonaut#argparser#parse(s:parser, a:input)

    " if the help argument was provided by the user, show a help menu
    if argonaut#argparser#has_arg(s:parser, '-h')
        call argonaut#argset#show_help(s:command_argset)
        return
    endif

    echo 'Welcome to Argonaut.'
    " TODO

endfunction

" Define the comamnd itself. Make sure to use <q-args>; the argparser must
" receive the entire set of arguments as one string.
command! 
    \ -nargs=*
    \ -complete=customlist,s:argonaut_command_completion
    \ Argonaut
    \ call s:argonaut_command(<q-args>)


" DEBUGGING ----------------------------------------------------------------- "
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
" DEBUGGING ----------------------------------------------------------------- "


