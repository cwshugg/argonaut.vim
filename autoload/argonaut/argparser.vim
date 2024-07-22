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

" Template object used to create 'splitbits', which is an intermediate object
" used in the argparser to parse arguments from a raw string.
let s:argparser_splitbit_template = {
    \ 'text': '',
    \ 'nesting_pair': v:null
\ }

" Nesting pairs used for parsing. These are used to carefully split
" white-space-separated strings while also keeping together text that is
" contained by these 'nesting pairs'.
let s:argparser_nesting_pairs = [
    \ {'opener': '"',   'closer': '"',  'postprocess': v:null},
    \ {'opener': "'",   'closer': "'",  'postprocess': v:null},
    \ {'opener': "$(",  'closer': ")",  'postprocess': 'shell'},
    \ {'opener': "${",  'closer': "}",  'postprocess': 'envvar'}
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

" The main parser function. Takes in the parser and a string to parse.
" Arguments are parsed and they are returned.
function! argonaut#argparser#parse(parser, str) abort
    " first, split the string into pieces
    let s:splitbits = argonaut#argparser#split(a:parser, a:str)
    
    echo s:splitbits
    " TODO - implement the rest
endfunction

" Attempts to split a given string by whitespace, while also factoring in
" strings surrounded by quotes. Returns a list of splitbit objects.
function! argonaut#argparser#split(parser, str) abort
    let s:current_np = v:null
    let s:current_arg = v:null
    let s:args = []
    
    " walk through the string, character by character
    let s:str_len = len(a:str)
    let s:previous_backslash = 0
    let s:idx = 0
    while s:idx <= s:str_len
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
                let s:np_opener = s:np.opener
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
                    let s:current_arg = s:splitbit_new(s:current_np)
                    break
                endif
            endfor

            " if the above loop succeeded in finding a nesting pair, proceed
            " to the next iteration of the main loop. Adjust our loop index
            " such that the next character we land on is the first one that
            " occurs after the nesting pair's opener string
            if s:current_np isnot v:null
                let s:idx += len(s:current_np.opener)
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
            let s:np_closer = s:current_np.closer
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
            let s:current_arg = s:splitbit_new(v:null)
        endif

        " finally, add the next character to our current argument string, as
        " long as we're not in the final (extra) iteration
        let s:previous_backslash = s:char == '\'
        if s:current_arg isnot v:null && s:idx < s:str_len
            let s:char = a:str[s:idx]
            " if we're looking at a backslash, we want to skip the backslash,
            " but remember that the next character is escaped
            if !s:previous_backslash
                call s:splitbit_add_text(s:current_arg, s:char)
            endif
        endif
        
        " move to the next character
        let s:idx += 1
    endwhile
    
    " at this point, we shouldn't have an unfinished argument, due to our
    " extra iteration in the above loop
    if s:current_arg isnot v:null
        let s:errmsg = 'the provided string was not properly terminated: ' .
                     \ '"' . a:str . '"'
        call argonaut#utils#panic(s:errmsg)
    endif

    " before returning the arguments, run post-processing on each of them
    for s:arg in s:args
        call s:splitbit_postprocess(s:arg)
    endfor
    
    return s:args
endfunction


" ========================= String Splitting Helpers ========================= "
" A 'splitbit' represents a single string argument that was created during the
" parsing of the user's input string.
"
" A splitbit can be as simple as the word 'hello' surrounded by whitespace,
" but it can also be parsed via nesting pairs, each representing different
" intentions. For example:
"
"  * '$(ls -al)' - the text 'ls -al' should be executed on the shell
"  * '${HOME}' - the text 'HOME' should be interpreted as an environment
"    variable

" Constructs a new splitbit object, given text and an associated nesting pair.
function! s:splitbit_new(nesting_pair) abort
    let s:result = deepcopy(s:argparser_splitbit_template)
    let s:result.nesting_pair = a:nesting_pair
    return s:result
endfunction

" Appends the given string to the splitbit's text.
function! s:splitbit_add_text(splitbit, str) abort
    let a:splitbit.text .= a:str
endfunction

" Examines the text and nesting pair within the given splitbit and performs
" any necessary post-processing.
"
" Examples of post-processing would be running shell commands or extracting
" environment variables.
"
" Any postprocessing that is done may modify the text of the splitbit.
function! s:splitbit_postprocess(splitbit) abort
    " if there is no nesting pair, then there's no post-processing to do
    let s:np = a:splitbit.nesting_pair
    if s:np is v:null
        return
    endif

    " if the nesting pair has no post-process field, we're done
    if s:np.postprocess is v:null
        return
    endif

    " otherwise, use the post-process value to determine what to do
    if s:np.postprocess == 'envvar'
        let s:envvar = argonaut#utils#get_env(trim(a:splitbit.text))
        let a:splitbit.text = s:envvar is v:null ? '' : s:envvar
    elseif s:np.postprocess == 'shell'
        let s:shellout = argonaut#utils#run_shell_command(a:splitbit.text)
        let a:splitbit.text = s:shellout
    endif
endfunction

