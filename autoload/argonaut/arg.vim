" This file implements functions for defining and configuring a single
" argument.
"
" The Argument object represents a single command argument, with the following
" properties:
"
"  * `identifiers` - A list of argument identifier objects, used to recognize
"    the argument when the user specifies it.
"  * `description` - A description of the argument and what it represents.
"  * `presence_count_min` - The minimum number of times this argument must
"    occur, if it occurs at all. (If this argument is present in the user's
"    arguments, but the number of times it is present is less than the
"    minimum, an error is thrown.)
"  * `presence_count_max` - The maximum number of times this argument can
"    occur, if it occurs at all. (If this argument is present in the user's
"    arguments, but the number of times it is present is more than the
"    maximum, an error is thrown.)
"  * `value_required` - A boolean, indicating if this argument *must* be
"    followed by a value.
"  * `value_hint` - A string used to briefly describe what the value should be
"    for this argument. This is used when argonaut displays a help menu, to
"    help the user understand what value should be provided.

" Template object used to create and format all argument objects.
let s:arg_template = {
    \ 'identifiers': [],
    \ 'description': '',
    \ 'presence_count_min': 0,
    \ 'presence_count_max': 1,
    \ 'value_required': 0,
    \ 'value_hint': 'VALUE'
\ }


" ======================== Argument Object Interface ========================= "
" Creates a new argument object.
function! argonaut#arg#new(...) abort
    let s:result = deepcopy(s:arg_template)

    " argument 1 (if provided) represents the identifier list
    if a:0 > 0
        let s:result.identifiers = a:1
    endif
    
    " argument 2 (if provided) represents the description
    if a:0 > 1
        let s:result.description = argonaut#utils#sanitize_value(a:2)
    endif
    
    " argument 3 (if provided) represents the presence count minimum
    if a:0 > 2
        let s:result.presence_count_min = a:3
    endif
    
    " argument 4 (if provided) represents the presence count maximum
    if a:0 > 3
        let s:result.presence_count_max = a:4
    endif

    " argument 5 (if provided) represents whether or not a value is required
    if a:0 > 4
        let s:result.value_required = argonaut#utils#sanitize_bool(a:5)
    endif

    " argument 6 (if provided) represents the value hint, which is used to
    " help the user understand what value they should provide for tthis
    " argument
    if a:0 > 5
        let s:result.value_hint = argonaut#utils#sanitize_value(a:6)
    endif

    " make sure too many arguments weren't provided
    if a:0 > 6
        let s:errmsg = 'argonaut#arg#new() accepts no more than 6 arguments'
        call argonaut#utils#panic(s:errmsg)
    endif

    return s:result
endfunction

" Checks the given object for all fields in the argument template. An error is
" thrown if they are all not found.
function! argonaut#arg#verify(arg) abort
    for s:key in keys(s:arg_template)
        if !has_key(a:arg, s:key)
            let s:errmsg = 'the provided object does not appear to be a valid ' .
                         \ 'arg object'
            call argonaut#utils#panic(s:errmsg)
        endif
    endfor
endfunction

" Builds and returns a string representation of the argument object.
function! argonaut#arg#to_string(arg) abort
    call argonaut#arg#verify(a:arg)
    let s:result = ''

    " iterate through all identifiers and build a string to display them all
    let s:num_aids = len(a:arg.identifiers)
    let s:aid_str = ''
    if s:num_aids > 0
        for s:idx in range(s:num_aids)
            let s:aid = a:arg.identifiers[s:idx]
            let s:aid_str .= argonaut#argid#to_string(s:aid)
    
            " add a space if this isn't the last one
            if s:idx < s:num_aids - 1
                let s:aid_str .= ' '
            endif
        endfor
    else
        let s:aid_str = '(NONE)'
    endif
    let s:result .= '[identifiers: ' . s:aid_str . '] '

    " add the rest of the properties to the string
    let s:result .= '[presence_count_min: ' . a:arg.presence_count_min . '] '
    let s:result .= '[presence_count_max: ' . a:arg.presence_count_max . '] '
    let s:result .= '[value_required: ' . a:arg.value_required . '] '
    return s:result
endfunction

" Adds the given argument identifier object to the argument.
function! argonaut#arg#add_argid(arg, aid) abort
    call argonaut#arg#verify(a:arg)
    call argonaut#argid#verify(a:aid)
    call add(a:arg.identifiers, a:aid)
endfunction

" Setter for `description`.
function! argonaut#arg#set_description(arg, description) abort
    call argonaut#arg#verify(a:arg)
    let a:arg.description = argonaut#utils#sanitize_value(a:description)
endfunction

" Getter for `description`.
function! argonaut#arg#get_description(arg) abort
    call argonaut#arg#verify(a:arg)
    return get(a:arg, 'description')
endfunction

" Setter for `presence_count_min`.
function! argonaut#arg#set_presence_count_min(arg, presence_count_min) abort
    call argonaut#arg#verify(a:arg)
    let s:count = argonaut#utils#sanitize_value(a:presence_count_min)

    " make sure the provided value is zero, or a positive integer. If it's
    " zero, that means the argument is not required to be present
    if s:count < 0
        let s:errmsg = 'the presence count minimum for an argument must be ' .
                     \ 'either zero or a positive integer ' .
                     \ '(you provided: ' . s:count . ')'
        call argonaut#utils#panic(s:errmsg)
    endif
    let a:arg.presence_count_min = s:count
endfunction

" Getter for `presence_count_min`.
function! argonaut#arg#get_presence_count_min(arg) abort
    call argonaut#arg#verify(a:arg)
    return get(a:arg, 'presence_count_min')
endfunction

" Setter for `presence_count_max`.
function! argonaut#arg#set_presence_count_max(arg, presence_count_max) abort
    call argonaut#arg#verify(a:arg)
    let s:count = argonaut#utils#sanitize_value(a:presence_count_max)

    " for the count maximum, positive values indicate an upper maximum, while
    " any negative value indicates an unlimited maximum. Zero is the one value
    " that this field cannot hold
    if s:count == 0
        let s:errmsg = 'the presence count maximum for an argument must not ' .
                     \ 'be zero )you provided: ' . s:count . ')'
        call argonaut#utils#panic(s:errmsg)
    endif
    let a:arg.presence_count_max = s:count
endfunction

" Getter for `presence_count_max`.
function! argonaut#arg#get_presence_count_max(arg) abort
    call argonaut#arg#verify(a:arg)
    return get(a:arg, 'presence_count_max')
endfunction

" Setter for `value_required`.
function! argonaut#arg#set_value_required(arg, value_required) abort
    call argonaut#arg#verify(a:arg)
    let a:arg.value_required = argonaut#utils#sanitize_bool(a:value_required)
endfunction

" Getter for `value_required`.
function! argonaut#arg#get_value_required(arg) abort
    call argonaut#arg#verify(a:arg)
    return get(a:arg, 'value_required')
endfunction

" Setter for `value_hint`.
function! argonaut#arg#set_value_hint(arg, value_hint) abort
    call argonaut#arg#verify(a:arg)
    let a:arg.value_hint = argonaut#utils#sanitize_value(a:value_hint)
endfunction

" Getter for `value_hint`.
function! argonaut#arg#get_value_hint(arg) abort
    call argonaut#arg#verify(a:arg)
    return get(a:arg, 'value_hint')
endfunction

" Compares against all of the argument's identifiers. If one of them matches,
" the corresponding identifier object is returned. Otherwise, v:null is
" returned.
function! argonaut#arg#cmp(arg, str)
    call argonaut#arg#verify(a:arg)
    for s:aid in a:arg.identifiers
        if argonaut#argid#cmp(s:aid, a:str)
            return s:aid
        endif
    endfor

    " return v:null upon no matches
    return v:null
endfunction

