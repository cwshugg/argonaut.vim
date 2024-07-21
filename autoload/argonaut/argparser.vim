" This file implements the argument parser object. This is used to parse a set
" of whitespace-separated command arguments provided by the user.
"
" The argument parser has the following properties:
"
"  * `argset` - An Argument Set object, provided by the user, which specifies
"    the arguments the parser should look for while parsing.
"  * `args` - A list of named arguments (that match up with entries in the
"    argset) that discovered during parsing.
"  * `args_unnamed` - A list of arguments that do not match up with any of the
"    provided argument specifications in the argset. (Basically, any other
"    argument the user wasn't explicitly looking for will end up in here.)

" Template object used to create and format all argument objects.
let s:argparser_template = {
        \ 'argset': v:null,
        \ 'args': [],
        \ 'args_unnamed': []
    \ }


" ======================== Argument Object Interface ========================= "
" Creates a new parser object.
function! argonaut#argparser#new() abort
    " make a copy of the template object
    return deepcopy(s:argparser_template)
endfunction

" Checks the given object for all fields in the parser template. An error is
" thrown if they are all not found.
function! argonaut#argparser#verify(arg) abort
    for s:key in keys(s:arg_template)
        if !has_key(a:arg, s:key)
            let s:errmsg = 'the provided object does not appear to be a valid ' .
                         \ 'argparser object'
            call argonaut#utils#panic(s:errmsg)
        endif
    endfor
endfunction

" TODO - implement function to split strings by whitespace (do this in
" utils.vim)

" TODO - implement function to parse! Make sure to factor for arguments who
" are expecting a value

