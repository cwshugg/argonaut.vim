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
function! argonaut#argset#new(...) abort
    let l:result = deepcopy(s:argset_template)

    " argument 1 (if provided) represents the argument list
    if a:0 > 0
        let l:result.arguments = a:1

        " make sure none of the arguments' identifiers collide with eachother
        let l:args_len = len(l:result.arguments)
        for l:i in range(l:args_len)
            let l:arg1 = l:result.arguments[l:i]
            call argonaut#arg#verify(l:arg1)

            for l:j in range(l:args_len)
                " skip comparisons against the same object (i == j)
                if l:i == l:j
                    continue
                endif

                let l:arg2 = l:result.arguments[l:j]

                " for each of the argument IDs in one of the arguments,
                " compare it against the other argument
                for l:argid in l:arg1.identifiers
                    let l:argid_str = argonaut#argid#to_string(l:argid)
                    let l:match = argonaut#arg#cmp(l:arg2, l:argid_str)
                    if !argonaut#utils#is_null(l:match)
                        let l:errmsg = 'the identifier "' . l:argid_str .
                                     \ '" was specified more than once in ' .
                                     \ 'the provided argument list.'
                        call argonaut#utils#panic(l:errmsg)
                    endif
                endfor
            endfor
        endfor
    endif

    " make sure too many arguments weren't provided
    if a:0 > 1
        let l:errmsg = 'argonaut#argset#new() accepts no more than 1 argument'
        call argonaut#utils#panic(l:errmsg)
    endif

    return l:result
endfunction

" Checks the given object for all fields in the argument set template. An
" error is thrown if they are all not found.
function! argonaut#argset#verify(set) abort
    for l:key in keys(s:argset_template)
        if !has_key(a:set, l:key)
            call argonaut#utils#panic('the provided object does not appear to be a valid argset object')
        endif
    endfor
endfunction

" Builds and returns a string representation of the argument set object.
function! argonaut#argset#to_string(set) abort
    call argonaut#argset#verify(a:set)
    
    let l:num_args = len(a:set.arguments)
    let l:result = 'Argument Set - ' . l:num_args . ' argument(s)'

    " iterate through all identifiers and build a string to display them all
    let l:arg_str = ''
    if l:num_args > 0
        for l:idx in range(l:num_args)
            let l:arg = a:set.arguments[l:idx]
            let l:arg_str .= "\n" . argonaut#arg#to_string(l:arg)
        endfor
    endif
    let l:result .= l:arg_str

    return l:result
endfunction

" Adds a new argument object to the set.
function! argonaut#argset#add_arg(set, arg) abort
    call argonaut#argset#verify(a:set)
    call argonaut#arg#verify(a:arg)

    " make sure none of the new argument's identifiers match up with existing
    " arguments in the set
    for l:new_argid in a:arg.identifiers
        let l:new_argid_str = argonaut#argid#to_string(l:new_argid)
        for l:a in a:set.arguments
            let l:argid = argonaut#arg#cmp(l:a, l:new_argid_str)
            if !argonaut#utils#is_null(l:argid)
                let l:errmsg = 'the identifier "' . l:new_argid_str .
                             \ '" already exists in this argument set'
                call argonaut#utils#panic(l:errmsg)
            endif
        endfor
    endfor

    call add(a:set.arguments, a:arg)
endfunction

" Compares the given string with all of the argument set's arguments. The
" first-found argument that has a match is returned. If nothing matches,
" v:null is returned.
function! argonaut#argset#cmp(set, str) abort
    call argonaut#argset#verify(a:set)
    for l:arg in a:set.arguments
        if !argonaut#utils#is_null(argonaut#arg#cmp(l:arg, a:str))
            return l:arg
        endif
    endfor

    " return v:null upon no matches
    return v:null
endfunction

" Returns a list of all argid objects stored within the argset. This is handy
" for implementing command completion on the argset's specific set of
" commands.
function! argonaut#argset#get_all_argids(set) abort
    call argonaut#argset#verify(a:set)
    let l:argids = []

    " iterate through all arguments in the set
    for l:arg in a:set.arguments
        " iterate through all argument identifiers in the argument
        for l:argid in l:arg.identifiers
            call add(l:argids, l:argid)
        endfor
    endfor

    return l:argids
endfunction

