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

" A built-in helper menu that shows all arguments stored in the given argset.
" This is handy for showing a help menu without requiring a user of argonaut
" to write one themselves.
function! argonaut#argset#show_help(set) abort
    call argonaut#argset#verify(a:set)

    " if there are no arguments in the set, quit early
    if len(a:set.arguments) == 0
        echo 'There are no specific arguments.'
        return
    endif

    echo 'Available arguments:'

    " iterate through each argument
    for l:arg in a:set.arguments
        " build a string that shows all possible identifiers for the argument
        let l:argid_str = ''
        let l:argids_len = len(l:arg.identifiers)
        for l:idx in range(l:argids_len)
            let l:argid = l:arg.identifiers[l:idx]
            let l:argid_str .= argonaut#argid#to_string(l:argid)

            " if a value is required, show the value hint next to the first
            " argid
            if l:arg.value_required && l:idx == 0
                let l:argid_str .= ' ' . l:arg.value_hint
            endif

            " add a delimeter if we're not on the last argid
            if l:idx < l:argids_len - 1
                let l:argid_str .= ', '
            endif
        endfor

        " if the argument must be specified at least once, prefix the argid
        " string with a special value to indicate this
        let l:argid_prefix = '    '
        if l:arg.presence_count_min > 0
            let l:argid_prefix = '  * '
        endif
        echo l:argid_prefix . l:argid_str
        
        " show the argument's description (if one was provided)
        if !argonaut#utils#is_empty(l:arg.description)
            echo '        ' . l:arg.description
        endif

        " show the number of times the argument can (or must) be specified
        let l:presence_count_str = ''
        if l:arg.presence_count_min > 0
            " if the presence min and max are both 1, then we'll word things
            " differently
            if l:arg.presence_count_min == 1 && l:arg.presence_count_max == 1
                let l:presence_count_str .= 'This argument must be specified exactly once'
            " otherwise, make sure to explain both numbers
            else
                let l:presence_count_str .= 'This argument must be specified at least ' .
                                          \ l:arg.presence_count_min . ' times'
                if l:arg.presence_count_max > 0
                    let l:presence_count_str .= ', but no more than ' . 
                                              \ l:arg.presence_count_max . ' times'
                endif
            endif

        elseif l:arg.presence_count_max > 1
            " only show this if the maximum is more than 1. Typically, an
            " argument can be specified only once, so anything greater
            " warrants some explanation
            let l:presence_count_str .= 'This argument may be specified up to ' .
                                      \ l:arg.presence_count_max . ' times'
        endif
        if !argonaut#utils#is_empty(l:presence_count_str)
            echo '        ' . l:presence_count_str . '.'
        endif
    endfor
endfunction

