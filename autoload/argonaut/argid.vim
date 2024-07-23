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

" Template object used to create and format all argument identifier objects.
let s:argid_template = {
    \ 'name': '',
    \ 'prefix': '-',
    \ 'case_sensitive': 1
\ }


" ====================== Argument Identifier Interface ======================= "
" Creates a new argument ID object.
function! argonaut#argid#new(...) abort
    let s:result = deepcopy(s:argid_template)

    " argument 1 (if provided) represents the prefix
    if a:0 > 0
        let s:result.prefix = a:1
    endif
    
    " argument 2 (if provided) represents the name
    if a:0 > 1
        let s:result.name = a:2
    endif
    
    " argument 3 (if provided) represents the case sensitivity
    if a:0 > 2
        let s:result.case_sensitive = argonaut#utils#sanitize_bool(a:3)
    endif

    " make sure too many arguments weren't provided
    if a:0 > 3
        let s:errmsg = 'argonaut#argid#new() accepts no more than 3 arguments'
        call argonaut#utils#panic(s:errmsg)
    endif

    return s:result
endfunction

" Checks the given object for all fields in the argument identifier template.
" An error is thrown if they are all not found.
function! argonaut#argid#verify(aid) abort
    for s:key in keys(s:argid_template)
        if !has_key(a:aid, s:key)
            let s:errmsg = 'the provided object does not appear to be a valid ' .
                         \ 'argid object'
            call argonaut#utils#panic(s:errmsg)
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
    let s:name = argonaut#utils#sanitize_value(a:name)
    if argonaut#utils#is_null(s:name)
        let s:errmsg = 'an argid (argument identifier) cannot have a null ' .
                     \ 'name'
        call argonaut#utils#panic(s:errmsg)
    endif

    " make sure the name doesn't contain whitespace
    let s:pieces = split(s:name)
    if len(s:pieces) > 1
        let s:errmsg = 'an argid (argument identifier) cannot have a name ' .
                     \ 'containing whitespace ' .
                     \ '(you provided: "' . s:name . '")'
        call argonaut#utils#panic(s:errmsg)
    endif

    let a:aid.name = s:name
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
    let s:prefix = argonaut#utils#sanitize_value(a:prefix)
    if argonaut#utils#is_null(s:prefix)
        let s:errmsg = 'an argid (argument identifier) cannot have a null ' .
                     \ 'prefix'
        call argonaut#utils#panic(s:errmsg)
    endif

    let a:aid.prefix = s:prefix
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

" Compares against the given string and returns true if the string matches the
" combination of the prefix and the name.
"
" Depending on `aid.case_sensitive`, this will succeed or fail if the string
" matches with or without case sensitivity.
function! argonaut#argid#cmp(aid, str) abort
    call argonaut#argid#verify(a:aid)
    
    " build a string with the argument ID to compare with
    let s:aid_str = argonaut#argid#to_string(a:aid)

    " compare differently, depending on the case sensitivity
    if a:aid.case_sensitive
        return argonaut#utils#str_cmp(s:aid_str, a:str)
    endif
    return argonaut#utils#str_cmp_case_insensitive(s:aid_str, a:str)
endfunction

