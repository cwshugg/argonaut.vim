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

" Nesting pairs used for parsing. These are used to carefully split
" white-space-separated strings while also keeping together text that is
" contained by these 'nesting pairs'.
let s:argparser_nesting_pairs = [
    \ {'opener': '"', 'closer': '"'},
    \ {'opener': "'", 'closer': "'"}
\ ]


" ======================== Argument Object Interface ========================= "
" Creates a new parser object.
function! argonaut#argparser#new() abort
    " make a copy of the template object
    return deepcopy(s:argparser_template)
endfunction

" Checks the given object for all fields in the parser template. An error is
" thrown if they are all not found.
function! argonaut#argparser#verify(parser) abort
    for s:key in keys(s:argparser_template)
        if !has_key(a:parser, s:key)
            let s:errmsg = 'the provided object does not appear to be a valid ' .
                         \ 'argparser object'
            call argonaut#utils#panic(s:errmsg)
        endif
    endfor
endfunction

" Setter for `argset`.
function! argonaut#argparser#set_argset(parser, argset) abort
    call argonaut#argparser#verify(a:parser)
    call argonaut#argset#verify(a:argset)
    let a:parser.argset = a:argset
endfunction

" Getter for `argset`.
function! argonaut#argparser#get_argset(parser) abort
    call argonaut#argparser#verify(a:parser)
    return get(a:parser, 'argset')
endfunction

" Attempts to split a given string by whitespace, while also factoring in
" strings surrounded by quotes.
function! argonaut#argparser#split(parser, str) abort
    let s:current_np = v:null
    let s:current_arg = v:null
    let s:args = []
    
    " walk through the string, character by character
    let s:str_len = len(a:str)
    for s:idx in range(s:str_len + 1)
        " to make the below logic simpler, this loop is doing one extra
        " iteration. On the final iteration, the 'current character' will be a
        " whitespace
        let s:char = ' '
        if s:idx < s:str_len
            let s:char = a:str[s:idx]
        endif
        let s:cease_arg_tracking = 0

        " if we're currently not tracking a nesting pair...
        if s:current_np is v:null
            " iterate through the nesting pairs and compare the opener
            " string with the current string
            for s:np in s:argparser_nesting_pairs
                " make sure we have enough room left in the string to compare with
                let s:np_opener = get(s:np, 'opener')
                let s:np_cmp_len = len(s:np_opener)
                if s:np_cmp_len > s:str_len - s:idx
                    continue
                endif
                
                let s:np_cmp_str = strpart(a:str, s:idx, s:np_cmp_len)
                if argonaut#utils#str_cmp(s:np_opener, s:np_cmp_str) &&
                 \ !s:previous_backslash
                    " if the current nesting pair matches, update
                    " `s:current_np` to track the new nesting pair, and start
                    " a new argument
                    let s:current_np = s:np
                    let s:current_arg = ''
                    break
                endif
            endfor

            " if the above loop succeeded in finding a nesting pair, proceed
            " to the next iteration of the main loop
            if s:current_np isnot v:null
                continue
            endif
            
            " additionally, if we're currently examining whitespace, we need to
            " end the current argument
            let s:is_whitespace = argonaut#utils#char_is_whitespace(s:char)
            if s:is_whitespace
                let s:cease_arg_tracking = 1
            endif
        " otherwise, if we currently ARE tracking a nesting pair...
        else
            " make sure we have enough room left in the string to compare with
            let s:np_closer = get(s:current_np, 'closer')
            let s:np_cmp_len = len(s:np_closer)
            if s:np_cmp_len <= s:str_len - s:idx
                " if the current string matches with the nesting pair's closer, we
                " need to end the current argument
                let s:np_cmp_str = strpart(a:str, s:idx, s:np_cmp_len)
                if argonaut#utils#str_cmp(s:np_closer, s:np_cmp_str) &&
                 \ !s:previous_backslash
                    " if the current nesting pair matches, update
                    let s:cease_arg_tracking = 1
                    let s:current_np = v:null
                endif
            endif
        endif
        
        " if we've been told to finish the current argument, and we are in
        " fact tracking an argument, we'll save it to our result list
        if s:cease_arg_tracking
            if s:current_arg isnot v:null
                call add(s:args, s:current_arg)
                let s:current_arg = v:null
            endif
        " otherwise, start a new argument if we currently don't have one
        elseif s:current_arg is v:null
            let s:current_arg = ''
        endif

        " finally, add the next character to our current argument string, as
        " long as we're not in the final (extra) iteration
        let s:previous_backslash = s:char == '\'
        if s:current_arg isnot v:null && s:idx < s:str_len
            let s:char = a:str[s:idx]
            " if we're looking at a backslash, we want to skip the backslash,
            " but remember that the next character is escaped
            if !s:previous_backslash
                let s:current_arg .= s:char
            endif
        endif
    endfor
    
    " at this point, we shouldn't have an unfinished argument, due to our
    " extra iteration in the above loop
    if s:current_arg isnot v:null
        let s:errmsg = 'the provided string was not properly terminated: ' .
                     \ '"' . a:str . '"'
        call argonaut#utils#panic(s:errmsg)
    endif
    
    return s:args
endfunction

" The main parser function. Takes in the parser and a string to parse.
" Arguments are parsed and they are returned.
function! argonaut#argparser#parse(parser, str) abort
    " first, split the string into pieces
    let s:pieces = argonaut#argparser#split(a:parser, a:str)
    
    echo 'ARGUMENTS:'
    echo s:pieces
    " TODO - implement the rest
endfunction

