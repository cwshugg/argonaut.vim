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

" Template object used to create and format the argument parser.
let s:argparser_template = {
    \ 'argset': v:null,
    \ 'args': [],
\ }

" Template object used to create 'splitbits', which is an intermediate object
" used in the argparser to parse arguments from a raw string.
let s:argparser_splitbit_template = {
    \ 'text': '',
    \ 'nesting_pair': v:null
\ }

" Template object used to create and format individual argument parser
" results.
let s:argparser_result_template = {
    \ 'arg': v:null,
    \ 'value': 1
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
function! argonaut#argparser#new(...) abort
    let s:result = deepcopy(s:argparser_template)

    " if at least one argument was provided, we'll use this as the argset
    if a:0 > 0
        let s:argset = a:1
        call argonaut#argset#verify(s:argset)
        let s:result.argset = s:argset
    endif

    " make sure too many arguments weren't provided
    if a:0 > 1
        let s:errmsg = 'argonaut#argparser#new() accepts no more than 1 argument'
        call argonaut#utils#panic(s:errmsg)
    endif

    return s:result
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
        if argonaut#utils#is_null(s:current_np)
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
            if !argonaut#utils#is_null(s:current_np)
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
            if !argonaut#utils#is_null(s:current_arg)
                call add(s:args, s:current_arg)
                let s:current_arg = v:null
            endif
        " otherwise, start a new argument if we currently don't have one
        elseif argonaut#utils#is_null(s:current_arg)
            let s:current_arg = s:splitbit_new(v:null)
        endif

        " finally, add the next character to our current argument string, as
        " long as we're not in the final (extra) iteration
        let s:previous_backslash = s:char == '\'
        if !argonaut#utils#is_null(s:current_arg) && s:idx < s:str_len
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
    if !argonaut#utils#is_null(s:current_arg)
        let s:errmsg = 'the provided string was not properly terminated: ' .
                     \ '"' . a:str . '"'
        call argonaut#utils#panic(s:errmsg)
    endif

    return s:args
endfunction

" The main parser function. Takes in the parser and a string to parse.
" Arguments are parsed and they are returned.
function! argonaut#argparser#parse(parser, str) abort
    call argonaut#argparser#verify(a:parser)
    let a:parser.args = []

    " before splitting the string and processing it, we'll create temporary
    " dictionary fields within each of the argument specification objects in
    " the parser's argument set. These will be used to count the number of
    " occurrences we find below
    for s:arg in a:parser.argset.arguments
        let s:arg.presence_count = 0
    endfor

    " first, split the string into pieces
    let s:splitbits = argonaut#argparser#split(a:parser, a:str)
    
    " after receiving the splitbits, postprocess each. (this'll retrieve
    " environment variables, run shell commands, etc.)
    let s:splitbits_len = len(s:splitbits)
    let s:last_result = v:null
    for s:idx in range(s:splitbits_len)
        let s:splitbit = s:splitbits[s:idx]
        call s:splitbit_postprocess(s:splitbit)

        " search the parser's argument set to determine if the text identifies
        " with any of the argument specifications within
        let s:match = argonaut#argset#cmp(a:parser.argset, s:splitbit.text)

        " create an argument parser result object and store it
        let s:new_result = s:argparser_result_new(s:match, v:null)

        " if this argument doesn't match one of the arguments in the argument
        " set, there are one of two possibilities:
        if argonaut#utils#is_null(s:match)
            " possibility 1: the last iteration's result was stored, which
            " means the previous argument requires a value. Save this
            " splitbit's value to the previous result
            if !argonaut#utils#is_null(s:last_result)
                let s:last_result.value = s:splitbit.text
                let s:last_result = v:null
                continue
            endif

            " possibility 2: this is a plain-old unnamed argument (i.e.
            " something that wasn't recognized as an argument). Update the new
            " result to hold the splitbit's value and add it to the parser
            let s:new_result.value = s:splitbit.text
            call add(a:parser.args, s:new_result)
            continue
        endif

        " otherwise, the argument DOES match one of the speciufied arguments.
        " Make sure we aren't expecting a value from the previous iteration
        let s:arg_with_missing_value = v:null
        if !argonaut#utils#is_null(s:last_result)
            let s:arg_with_missing_value = s:last_result
        elseif s:match.value_required && s:idx == s:splitbits_len - 1
            let s:arg_with_missing_value = s:new_result
        endif
        if !argonaut#utils#is_null(s:arg_with_missing_value)
            let s:arg = s:arg_with_missing_value.arg
            let s:arg_str = argonaut#argid#to_string(s:arg.identifiers[0])
            let s:errmsg = 'the argument "' . s:arg_str . '" expects a value to ' .
                         \ 'be specified alongside it'
            call argonaut#utils#panic(s:errmsg)
        endif

        " increment the result's presence counter and add it to the parser
        let s:match.presence_count += 1
        call add(a:parser.args, s:new_result)

        " if the matched argument specification requires that a value be
        " specified along with it, set `s:last_result` so we can capture this
        " value on the next iteration
        if s:match.value_required
            let s:last_result = s:new_result
        endif
    endfor

    " iterate through the argument set's argument specifications and count the
    " number of occurrences. Make sure they're within the required range
    for s:arg in a:parser.argset.arguments
        " the minimum amount must be met
        if s:arg.presence_count < s:arg.presence_count_min
            let s:arg_str = argonaut#argid#to_string(s:arg.identifiers[0])
            let s:errmsg = 'the argument "' . s:arg_str . '" must be specified ' .
                         \ 'at least ' . s:arg.presence_count_min . ' time(s)'
            call argonaut#utils#panic(s:errmsg)
        endif

        " the maximum amount must not be exceeded
        if s:arg.presence_count > s:arg.presence_count_max
            let s:arg_str = argonaut#argid#to_string(s:arg.identifiers[0])
            let s:errmsg = 'the argument "' . s:arg_str . '" must not be specified ' .
                         \ 'more than ' . s:arg.presence_count_max . ' time(s)'
            call argonaut#utils#panic(s:errmsg)
        endif

        " finally, remove the dictionary field; it's no longer needed
        call remove(s:arg, 'presence_count')
    endfor
endfunction

" Searches for an argument result that matches with the given argument ID
" string. A list of result objects is returned.
"
" If one is not found, v:null is returned.
"
" This should be called after `parser()`.
function! argonaut#argparser#get_arg(parser, id_str) abort
    call argonaut#argparser#verify(a:parser)
    let s:result = []
    
    " examine each of the arguments that were parsed
    for s:argresult in a:parser.args
        " if this argument has an argument specification, compare against the
        " provided ID string. If there's a match, add the result's value to
        " the list
        let s:arg = s:argresult.arg
        if !argonaut#utils#is_null(s:arg) &&
         \ !argonaut#utils#is_null(argonaut#arg#cmp(s:arg, a:id_str))
            call add(s:result, s:argresult.value)
        endif
    endfor

    return s:result
endfunction

" Convenience function that returns true or false depending on if the argument
" matching the specific argument identifier was present in the parsed results.
" This is most useful for arguments that didn't require a value, whose
" presence indicates something useful to the user.
"
" This should be called after `parser()`.
function! argonaut#argparser#has_arg(parser, id_str) abort
    return len(argonaut#argparser#get_arg(a:parser, a:id_str)) > 0
endfunction

" Returns a list of arguments that matched with the parser's argset.
" Each list entry is a dictionary containing the argument object and the
" associated value.
"
" This should be called after `parser()`.
function! argonaut#argparser#get_args(parser) abort
    call argonaut#argparser#verify(a:parser)
    let s:result = []
    
    " examine each of the arguments that were parsed
    for s:argresult in a:parser.args
        " if this argument has no argument specification, add it
        if !argonaut#utils#is_null(s:argresult.arg)
            call add(s:result, s:argresult)
        endif
    endfor

    return s:result
endfunction

" Returns a list of arguments that were parsed that did not match any of the
" specific arguments provided in the parser's argset.
"
" This should be called after `parser()`.
function! argonaut#argparser#get_extra_args(parser) abort
    call argonaut#argparser#verify(a:parser)
    let s:result = []
    
    " examine each of the arguments that were parsed
    for s:argresult in a:parser.args
        " if this argument has no argument specification, add it
        if argonaut#utils#is_null(s:argresult.arg)
            call add(s:result, s:argresult.value)
        endif
    endfor

    return s:result
endfunction


" ========================= Argument Parsing Results ========================= "
" An 'argument parsing result' object is used to represent a single argument
" provided by the user. When the argparser sees this value during its
" `parse()` function, it is stored internal to the parser.

" Creates a new result object.
function! s:argparser_result_new(arg, value) abort
    if !argonaut#utils#is_null(a:arg)
        call argonaut#arg#verify(a:arg)
    endif
    
    let s:result = deepcopy(s:argparser_result_template)
    let s:result.arg = a:arg
    return s:result
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
    " if there's no nesting pair...
    let s:np = a:splitbit.nesting_pair
    if argonaut#utils#is_null(s:np)
        " does the text begin with '$'? It may be an environment variable that
        " was specified without the '{}' brackets
        let s:text = trim(a:splitbit.text)
        if argonaut#utils#str_begins_with(s:text, '$')
            let a:splitbit.text = expand(s:text)
        endif

        return
    endif

    " if the nesting pair has no post-process field, we're done
    if argonaut#utils#is_null(s:np.postprocess)
        return
    endif

    " otherwise, use the post-process value to determine what to do
    if s:np.postprocess == 'envvar'
        let s:envvar = argonaut#utils#get_env(trim(a:splitbit.text))
        if !argonaut#utils#is_null(s:envvar)
            let a:splitbit.text = s:envvar
        endif
    elseif s:np.postprocess == 'shell'
        let s:shellout = argonaut#utils#run_shell_command(a:splitbit.text)
        let a:splitbit.text = s:shellout
    endif
endfunction

