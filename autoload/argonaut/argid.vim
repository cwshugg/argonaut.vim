" This file implements functions for defining and configuring an argument
" identifier string.
"
" The Argument Identifier object represents a single argument name and prefix
" that can be used to identify an Argument. Each Argument can have multiple
" identifiers.
"
" Each identifier has the following properties:
"
"  * `prefix` - The string that comes before the name (ex: '--' in '--hello')
"  * `name` - The string that comes after the prefix (ex: 'hello' in '--hello')
"  * `case_sensitive` - A boolean that indicates whether or not the identifier
"    must be matched with the specified case. If true, comparisons only
"    succeed on exact matches. If false, comparisons will succeed
"    case-insensitively.
"  * `show_in_autocomplete` - A boolean that indicates whether or not the
"    identifier is shown to the user when using command autocomplete. This is
"    useful when a command has several argids, and the programmer only wants
"    one or two to show up (to waste less of the user's time cycling through a
"    list of argids that all point to the same command). This is enabled by
"    default for all argids.

" Template object used to create and format all argument identifier objects.
let s:argid_template = {
    \ 'name': '',
    \ 'prefix': '-',
    \ 'case_sensitive': 1,
    \ 'show_in_autocomplete': 1
\ }


" ====================== Argument Identifier Interface ======================= "
" Creates a new argument ID object.
function! argonaut#argid#new(...) abort
    let l:result = deepcopy(s:argid_template)

    " argument 1 (if provided) represents the prefix
    if a:0 > 0
        let l:result.prefix = argonaut#utils#sanitize_value(a:1)
    endif
    
    " argument 2 (if provided) represents the name
    if a:0 > 1
        let l:result.name = argonaut#utils#sanitize_value(a:2)
    endif
    
    " make sure too many arguments weren't provided
    if a:0 > 2
        let l:errmsg = 'argonaut#argid#new() accepts no more than 2 arguments'
        call argonaut#utils#panic(l:errmsg)
    endif

    return l:result
endfunction

" Checks the given object for all fields in the argument identifier template.
" An error is thrown if they are all not found.
function! argonaut#argid#verify(aid) abort
    for l:key in keys(s:argid_template)
        if !has_key(a:aid, l:key)
            let l:errmsg = 'the provided object does not appear to be a valid ' .
                         \ 'argid object'
            call argonaut#utils#panic(l:errmsg)
        endif
    endfor
endfunction

" Builds and returns a string representation of the argument ID object.
function! argonaut#argid#to_string(aid) abort
    call argonaut#argid#verify(a:aid)
    return '' . a:aid.prefix . a:aid.name
endfunction

" Setter for `name`.
function! argonaut#argid#set_name(aid, name) abort
    call argonaut#argid#verify(a:aid)
    
    " make sure the name isn't null
    let l:name = argonaut#utils#sanitize_value(a:name)
    if argonaut#utils#is_null(l:name)
        let l:errmsg = 'an argid (argument identifier) cannot have a null ' .
                     \ 'name'
        call argonaut#utils#panic(l:errmsg)
    endif

    " make sure the name doesn't contain whitespace
    let l:pieces = split(l:name)
    if len(l:pieces) > 1
        let l:errmsg = 'an argid (argument identifier) cannot have a name ' .
                     \ 'containing whitespace ' .
                     \ '(you provided: "' . l:name . '")'
        call argonaut#utils#panic(l:errmsg)
    endif

    let a:aid.name = l:name
endfunction

" Getter for `name`.
function! argonaut#argid#get_name(aid) abort
    call argonaut#argid#verify(a:aid)
    return get(a:aid, 'name')
endfunction

" Setter for `prefix`.
function! argonaut#argid#set_prefix(aid, prefix) abort
    call argonaut#argid#verify(a:aid)
    
    " make sure the prefix isn't null
    let l:prefix = argonaut#utils#sanitize_value(a:prefix)
    if argonaut#utils#is_null(l:prefix)
        let l:errmsg = 'an argid (argument identifier) cannot have a null ' .
                     \ 'prefix'
        call argonaut#utils#panic(l:errmsg)
    endif

    " make sure the prefix doesn't contain whitespace
    let l:pieces = split(l:prefix)
    if len(l:pieces) > 1
        let l:errmsg = 'an argid (argument identifier) cannot have a name ' .
                     \ 'containing whitespace ' .
                     \ '(you provided: "' . l:prefix . '")'
        call argonaut#utils#panic(l:errmsg)
    endif

    let a:aid.prefix = l:prefix
endfunction

" Getter for `prefix`.
function! argonaut#argid#get_prefix(aid) abort
    call argonaut#argid#verify(a:aid)
    return get(a:aid, 'prefix')
endfunction

" Setter for `case_sensitive`.
function! argonaut#argid#set_case_sensitive(aid, case_sensitive) abort
    call argonaut#argid#verify(a:aid)
    let a:aid.case_sensitive = argonaut#utils#sanitize_bool(a:case_sensitive)
endfunction

" Getter for `case_sensitive`.
function! argonaut#argid#get_case_sensitive(aid) abort
    call argonaut#argid#verify(a:aid)
    return get(a:aid, 'case_sensitive')
endfunction

" Setter for `show_in_autocomplete`.
function! argonaut#argid#set_show_in_autocomplete(aid, show_in_autocomplete) abort
    call argonaut#argid#verify(a:aid)
    let a:aid.show_in_autocomplete = argonaut#utils#sanitize_bool(a:show_in_autocomplete)
endfunction

" Getter for `show_in_autocomplete`.
function! argonaut#argid#get_show_in_autocomplete(aid) abort
    call argonaut#argid#verify(a:aid)
    return get(a:aid, 'show_in_autocomplete')
endfunction

" Compares against the given string and returns true if the string matches the
" combination of the prefix and the name.
"
" Depending on `aid.case_sensitive`, this will succeed or fail if the string
" matches with or without case sensitivity.
function! argonaut#argid#cmp(aid, str) abort
    call argonaut#argid#verify(a:aid)
    
    " build a string with the argument ID to compare with
    let l:aid_str = argonaut#argid#to_string(a:aid)

    " compare differently, depending on the case sensitivity
    if a:aid.case_sensitive
        return argonaut#utils#str_cmp(l:aid_str, a:str)
    endif
    return argonaut#utils#str_cmp_case_insensitive(l:aid_str, a:str)
endfunction

" Compares the given string against the argid's prefix. If the string begins
" with the prefix, true is returned.
" If the argid has an empty prefix, this always returns false.
function! argonaut#argid#cmp_prefix(aid, str) abort
    call argonaut#argid#verify(a:aid)

    " if the prefix is null or an empty string, return early; it's never
    " considered to be a match
    if argonaut#utils#is_empty(a:aid.prefix)
        return v:false
    endif
    
    " compare with the prefix, depending on case sensitivity
    if a:aid.case_sensitive
        return argonaut#utils#str_begins_with(a:str, a:aid.prefix)
    endif
    return argonaut#utils#str_begins_with_case_insensitive(a:str, a:aid.prefix)
endfunction

