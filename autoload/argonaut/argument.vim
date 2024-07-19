" This file implements functions for defining and configuring a single
" argument.
"
" The Argument object represents a single command argument, with the following
" properties:
"
"  * `identifiers` - A list of argument identifier objects, used to recognize
"    the argument when the user specifies it.
"  * `presence_required` - A boolean, indicating if this argument *must* be
"    specified by the user.
"  * `value_required` - A boolean, indicating if this argument *must* be
"    followed by a value.

" Template object used to create and format all argument objects.
let s:argument_template = {
        \ 'identifiers': [],
        \ 'presence_required': 0,
        \ 'value_required': 0
    \ }


" ======================== Argument Object Interface ========================= "
" Creates a new argument object.
function! argonaut#argument#new() abort
    " make a copy of the template object
    return deepcopy(s:argument_template)
endfunction

" Checks the given object for all fields in the argument template. An error is
" thrown if they are all not found.
function! argonaut#argument#verify(arg) abort
    for s:key in keys(s:argument_template)
        if !has_key(a:arg, s:key)
            call argonaut#utils#panic('the provided object does not appear to be a valid argument object')
        endif
    endfor
endfunction

" Builds and returns a string representation of the argument object.
function! argonaut#argument#to_string(arg) abort
    call argonaut#argument#verify(a:arg)
    let s:result = ''

    " iterate through all identifiers and build a string to display them all
    let s:num_aids = len(a:arg.identifiers)
    let s:aid_str = ''
    if s:num_aids > 0
        for s:idx in range(s:num_aids)
            let s:aid = a:arg.identifiers[s:idx]
            let s:aid_str .= argonaut#argument_id#to_string(s:aid)
    
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
    let s:result .= '[presence_required: ' . a:arg.presence_required . '] '
    let s:result .= '[value_required: ' . a:arg.value_required . '] '
    return s:result
endfunction

" Adds the given argument identifier object to the argument.
function! argonaut#argument#add_identifier(arg, aid) abort
    call argonaut#argument_id#verify(a:aid)
    call add(a:arg.identifiers, a:aid)
endfunction

" Setter for `presence_required`.
function! argonaut#argument#set_presence_required(arg, presence_required) abort
    call argonaut#argument#verify(a:arg)
    let a:arg.presence_required = argonaut#utils#sanitize_bool(a:presence_required)
endfunction

" Getter for `presence_required`.
function! argonaut#argument#get_presence_required(arg) abort
    call argonaut#argument#verify(a:arg)
    return get(a:arg, 'presence_required')
endfunction

" Setter for `value_required`.
function! argonaut#argument#set_value_required(arg, value_required) abort
    call argonaut#argument#verify(a:arg)
    let a:arg.value_required = argonaut#utils#sanitize_bool(a:value_required)
endfunction

" Getter for `value_required`.
function! argonaut#argument#get_value_required(arg) abort
    call argonaut#argument#verify(a:arg)
    return get(a:arg, 'value_required')
endfunction

" Compares against all of the argument's identifiers. If one of them matches,
" the corresponding identifier object is returned. Otherwise, v:null is
" returned.
function! argonaut#argument#cmp(arg, str)
    " TODO - use argonaut#argument_id#cmp()
    return v:null
endfunction

