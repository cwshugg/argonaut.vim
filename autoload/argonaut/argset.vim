" This file implements functions for defining and configuring a set of
" arguments.
"
" Argument Sets should contain all the arguments that a user would want to be
" possibly parsed in a Vim command. When parsing is done, a single Argument
" Set is passed into the parser object.

" Template object used to create and format all argument set objects.
let s:argset_template = {
    \ 'arguments': [],
\ }


" ============================ Argument Set Index ============================ "
" Creates a new argument set object.
function! argonaut#argset#new() abort
    " make a copy of the template object
    return deepcopy(s:argset_template)
endfunction

" Checks the given object for all fields in the argument set template. An
" error is thrown if they are all not found.
function! argonaut#argset#verify(set) abort
    for s:key in keys(s:argset_template)
        if !has_key(a:set, s:key)
            call argonaut#utils#panic('the provided object does not appear to be a valid argset object')
        endif
    endfor
endfunction

" Builds and returns a string representation of the argument set object.
function! argonaut#argset#to_string(set) abort
    call argonaut#argset#verify(a:set)
    
    let s:num_args = len(a:set.arguments)
    let s:result = 'Argument Set - ' . s:num_args . ' argument(s)'

    " iterate through all identifiers and build a string to display them all
    let s:arg_str = ''
    if s:num_args > 0
        for s:idx in range(s:num_args)
            let s:arg = a:set.arguments[s:idx]
            let s:arg_str .= "\n" . argonaut#arg#to_string(s:arg)
        endfor
    endif
    let s:result .= s:arg_str

    return s:result
endfunction

" Adds a new argument object to the set.
function! argonaut#argset#add_arg(set, arg) abort
    call argonaut#argset#verify(a:set)
    call argonaut#arg#verify(a:arg)
    call add(a:set.arguments, a:arg)
endfunction

" Compares the given string with all of the argument set's arguments. The
" first-found argument that has a match is returned. If nothing matches,
" v:null is returned.
function! argonaut#argset#cmp(set, str) abort
    call argonaut#argset#verify(a:set)
    for s:arg in a:set.arguments
        if !argonaut#utils#is_null(argonaut#arg#cmp(s:arg, a:str))
            return s:arg
        endif
    endfor

    " return v:null upon no matches
    return v:null
endfunction

