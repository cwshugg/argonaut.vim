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
    \ {'opener': "(",   'closer': ")",  'postprocess': v:null},
    \ {'opener': "{",   'closer': "}",  'postprocess': v:null},
    \ {'opener': "$(",  'closer': ")",  'postprocess': 'shell'},
    \ {'opener': "${",  'closer': "}",  'postprocess': 'envvar'},
    \ {'opener': ":(",  'closer': ")",  'postprocess': 'vim_command'},
\ ]


" ======================== Argument Object Interface ========================= "
" Creates a new parser object.
function! argonaut#argparser#new(...) abort
    let l:result = deepcopy(s:argparser_template)

    " if at least one argument was provided, we'll use this as the argset
    if a:0 > 0
        let l:argset = a:1
        call argonaut#argset#verify(l:argset)
        let l:result.argset = l:argset
    endif

    " make sure too many arguments weren't provided
    if a:0 > 1
        let l:errmsg = 'argonaut#argparser#new() accepts no more than 1 argument'
        call argonaut#utils#panic(l:errmsg)
    endif

    return l:result
endfunction

" Checks the given object for all fields in the parser template. An error is
" thrown if they are all not found.
function! argonaut#argparser#verify(parser) abort
    for l:key in keys(s:argparser_template)
        if !has_key(a:parser, l:key)
            let l:errmsg = 'the provided object does not appear to be a valid ' .
                         \ 'argparser object'
            call argonaut#utils#panic(l:errmsg)
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

" A built-in helper menu that shows all arguments stored in the argparser's
" argset. This is handy for showing a help menu without requiring a user of
" argonaut to write one themselves.
function! argonaut#argparser#show_help(parser) abort
    call argonaut#argparser#verify(a:parser)
    let l:set = a:parser.argset

    " the argset must have been set for this function to run
    if argonaut#utils#is_null(l:set)
        let l:errmsg = 'this argparser does not have an argset; ' .
                     \ 'a help menu cannot be shown'
        call argonaut#utils#panic(l:errmsg)
    endif

    " if there are no arguments in the set, quit early
    if len(l:set.arguments) == 0
        echo 'There are no specific arguments.'
        return
    endif

    echo 'Available arguments:'

    " iterate through each argument
    for l:arg in l:set.arguments
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

" Attempts to split a given string by whitespace, while also factoring in
" strings surrounded by quotes. Returns a list of splitbit objects.
function! argonaut#argparser#split(parser, str) abort
    let l:current_np = v:null
    let l:np_stack = []
    let l:current_arg = v:null
    let l:args = []
    
    " walk through the string, character by character
    let l:str_len = len(a:str)
    let l:previous_backslash = 0
    let l:idx = 0
    while l:idx <= l:str_len
        " to make the below logic simpler, this loop is doing one extra
        " iteration. On the final iteration, the 'current character' will be a
        " whitespace
        let l:char = ' '
        if l:idx < l:str_len
            let l:char = a:str[l:idx]
        endif

        " if we're currently tracking a nesting pair (i.e. we have at least
        " one entry in the stack)...
        let l:np_stack_len = len(l:np_stack)
        if l:np_stack_len > 0
            let l:np = l:np_stack[0]
            
            " retrieve the current stack entry's closer string
            let l:np_closer = l:np.closer
            let l:np_cmp_len = len(l:np_closer)

            " is there enough room left in the string to compare?
            if l:np_cmp_len <= l:str_len - l:idx
                " if the current string matches with the nesting pair's closer, we
                " need to pop the current entry off of the stack
                let l:np_cmp_str = strpart(a:str, l:idx, l:np_cmp_len)
                if argonaut#utils#str_cmp(l:np_closer, l:np_cmp_str) &&
                 \ !l:previous_backslash
                    " pop the top entry off the stack (at index 0)
                    call remove(l:np_stack, 0)

                    " was that the final entry in the stack? If so, we need to
                    " stop tracking the current argument. Add it to our result
                    " list and continue to the next loop iteration
                    if l:np_stack_len == 1
                        call add(l:args, l:current_arg)
                        let l:current_arg = v:null
                    " otherwise, if this isn't the final entry in the stack,
                    " we want to include this closer string as part of the
                    " current argument's string
                    else
                        call s:splitbit_add_text(l:current_arg, l:np_cmp_str)
                    endif

                    " in either case, shift past the closer string and skip to
                    " the next iteration
                    let l:idx += l:np_cmp_len
                    continue
                endif
            endif
        endif

        " iterate through the nesting pairs and compare the opener string with
        " the current string
        let l:found_np_opener = v:false
        for l:np in s:argparser_nesting_pairs
            " make sure we have enough room left in the string to compare with
            let l:np_opener = l:np.opener
            let l:np_cmp_len = len(l:np_opener)
            if l:np_cmp_len > l:str_len - l:idx
                continue
            endif
            
            let l:np_cmp_str = strpart(a:str, l:idx, l:np_cmp_len)
            if argonaut#utils#str_cmp(l:np_opener, l:np_cmp_str) &&
             \ !l:previous_backslash
                " if a match is found, push it to the stack (this'll shift
                " everything existing down and place the new item at index 0)
                call insert(l:np_stack, l:np)

                " was this the first entry on the stack? If so, we need to
                " start tracking a new argument. Additionally, shift the
                " string index down such that the next characters we examine
                " are the ones immediately after the nesting pair's opener.
                " Then, jump to the next loop iteration
                if len(l:np_stack) == 1
                    let l:current_arg = s:splitbit_new(l:np)
                " otherwise, if this is a nesting pair that is nested within
                " the first nesting pair, we want to include it as part of the
                " argument's string
                else
                    call s:splitbit_add_text(l:current_arg, l:np_cmp_str)
                endif

                let l:found_np_opener = v:true
                break
            endif
        endfor

        " if the above loop succeeded in finding a nesting pair and pushing it
        " to the stack, we need to shift the index down such that the next
        " characters to examine are the ones that appear directly after the
        " nesting pair's opener
        if l:found_np_opener
            let l:np = l:np_stack[0]
            let l:idx += len(l:np.opener)
            continue
        endif

        " now, if none of the above caused us to skip to the next iteration,
        " we know that the current string didn't match a closer OR an opener.
        " If we're currently tracking a nesting pair, we should add the
        " current character as-is to the current argument, and continue to the
        " next loop iteration
        if l:np_stack_len > 0
            call s:splitbit_add_text(l:current_arg, l:char)
            let l:idx += 1
            continue
        endif
        
        " at this point, we know the following:
        "
        " 1. The current string didn't match a nesting pair closer (if we're
        "    even tracking a nesting pair)
        " 1. The current string didn't match a nesting pair opener
        " 2. We aren't currently tracking any nesting pair. We're looking at
        "    text that's in the 'wide open'
        "
        " So, if we encounter whitespace at this point, do one of the
        " following:
        if argonaut#utils#char_is_whitespace(l:char)
            " if we're tracking an argument at the moment, we need to stop
            " tracking it, now what we've hit non-nested whitespace
            if !argonaut#utils#is_null(l:current_arg)
                call add(l:args, l:current_arg)
                let l:current_arg = v:null
            endif
            
            " regardless of if we're tracking an argument or not, we are
            " currently looking at non-nested whitespace. Continue to the next
            " loop iteration
            let l:idx += 1
            continue
        endif
       
        " at this point, we know that we're looking at a non-whitespace
        " character. If we're not currently tracking an argument, create one
        if argonaut#utils#is_null(l:current_arg)
            let l:current_arg = s:splitbit_new(v:null)
        endif

        " add the current character to the current argument
        call s:splitbit_add_text(l:current_arg, l:char)

        " move to the next character
        let l:idx += 1
    endwhile

    " at this point, we should have an empty nesting pair stack. If we don't,
    " then the user must not have added a corresponding closer to an opener
    if len(l:np_stack) > 0
        let l:np = l:np_stack[0]
        let l:errmsg = 'syntax error: the opener string "' .
                     \ l:np.opener . '" was not closed properly.'
        call argonaut#utils#panic(l:errmsg)
    endif
    
    return l:args
endfunction

" The main parser function. Takes in the parser and a string to parse.
" Arguments are parsed and they are returned.
function! argonaut#argparser#parse(parser, str) abort
    call argonaut#argparser#verify(a:parser)
    let a:parser.args = []

    " before splitting the string and processing it, we'll set up a local
    " list to keep track of the number of occurrences for each argument in the
    " argset
    let l:presence_counts = {}
    for l:arg in a:parser.argset.arguments
        let l:key = argonaut#argid#to_string(l:arg.identifiers[0])
        let l:presence_counts[l:key] = 0
    endfor

    " first, split the string into pieces
    let l:splitbits = argonaut#argparser#split(a:parser, a:str)
    
    " postprocess all splitbits
    let l:splitbits_len = len(l:splitbits)
    let l:last_result = v:null
    for l:idx in range(l:splitbits_len)
        let l:splitbit = l:splitbits[l:idx]
        call s:splitbit_postprocess(l:splitbit)

        " search the parser's argument set to determine if the text identifies
        " with any of the argument specifications within
        let l:match = argonaut#argset#cmp(a:parser.argset, l:splitbit.text)

        " if there was no match, make sure the text doesn't start with one of
        " the argset's prefixes. If so, we'll consider this to be an
        " unrecognized argument
        if argonaut#utils#is_null(l:match)
            let l:pfx_matches = argonaut#argset#cmp_prefix(a:parser.argset, l:splitbit.text)
            if len(l:pfx_matches) > 0
                let l:errmsg = 'Unrecognized argument: "' . l:splitbit.text . '".'
                call argonaut#utils#panic(l:errmsg)
            endif
        endif

        " create an argument parser result object and store it
        let l:new_result = s:argparser_result_new(l:match, v:null)

        " if this argument doesn't match one of the arguments in the argument
        " set, there are one of two possibilities:
        if argonaut#utils#is_null(l:match)
            " possibility 1: the last iteration's result was stored, which
            " means the previous argument requires a value. Save this
            " splitbit's value to the previous result
            if !argonaut#utils#is_null(l:last_result)
                let l:last_result.value = l:splitbit.text
                let l:last_result = v:null
                continue
            endif

            " possibility 2: this is a plain-old unnamed argument (i.e.
            " something that wasn't recognized as an argument). Update the new
            " result to hold the splitbit's value and add it to the parser
            let l:new_result.value = l:splitbit.text
            call add(a:parser.args, l:new_result)
            continue
        endif

        " otherwise, the argument DOES match one of the speciufied arguments.
        " Make sure we aren't expecting a value from the previous iteration
        let l:arg_with_missing_value = v:null
        if !argonaut#utils#is_null(l:last_result)
            let l:arg_with_missing_value = l:last_result
        elseif l:match.value_required && l:idx == l:splitbits_len - 1
            let l:arg_with_missing_value = l:new_result
        endif
        if !argonaut#utils#is_null(l:arg_with_missing_value)
            let l:arg = l:arg_with_missing_value.arg
            let l:arg_str = argonaut#argid#to_string(l:arg.identifiers[0])
            let l:errmsg = 'the argument "' . l:arg_str . '" expects a value to ' .
                         \ 'be specified alongside it'
            call argonaut#utils#panic(l:errmsg)
        endif

        " increment the result's presence counter and add it to the parser
        let l:presence_counts_key = argonaut#argid#to_string(l:match.identifiers[0])
        let l:presence_counts[l:presence_counts_key] += 1
        call add(a:parser.args, l:new_result)

        " if the matched argument specification requires that a value be
        " specified along with it, set `l:last_result` so we can capture this
        " value on the next iteration
        if l:match.value_required
            let l:last_result = l:new_result
        endif
    endfor

    " iterate through the argument set's argument specifications and count the
    " number of occurrences. Make sure they're within the required range
    for l:arg in a:parser.argset.arguments
        " retrieve the presence counter for this argument
        let l:presence_counts_key = argonaut#argid#to_string(l:arg.identifiers[0])
        let l:presence_count = l:presence_counts[l:presence_counts_key]

        " the minimum amount must be met
        if l:presence_count < l:arg.presence_count_min
            let l:arg_str = argonaut#argid#to_string(l:arg.identifiers[0])
            let l:errmsg = 'the argument "' . l:arg_str . '" must be specified ' .
                         \ 'at least ' . l:arg.presence_count_min . ' time(s)'
            call argonaut#utils#panic(l:errmsg)
        endif

        " the maximum amount must not be exceeded
        if l:presence_count > l:arg.presence_count_max
            let l:arg_str = argonaut#argid#to_string(l:arg.identifiers[0])
            let l:errmsg = 'the argument "' . l:arg_str . '" must not be specified ' .
                         \ 'more than ' . l:arg.presence_count_max . ' time(s)'
            call argonaut#utils#panic(l:errmsg)
        endif
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
    let l:result = []
    
    " examine each of the arguments that were parsed
    for l:argresult in a:parser.args
        " if this argument has an argument specification, compare against the
        " provided ID string. If there's a match, add the result's value to
        " the list
        let l:arg = l:argresult.arg
        if !argonaut#utils#is_null(l:arg) &&
         \ !argonaut#utils#is_null(argonaut#arg#cmp(l:arg, a:id_str))
            call add(l:result, l:argresult.value)
        endif
    endfor

    return l:result
endfunction

" Convenience function that returns true or false depending on if the argument
" matching the specific argument identifier was present in the parsed results.
" This is most useful for arguments that didn't require a value, whose
" presence indicates something useful to the user.
"
" This should be called after `parser()`.
function! argonaut#argparser#has_arg(parser, id_str) abort
    call argonaut#argparser#verify(a:parser)
    return len(argonaut#argparser#get_arg(a:parser, a:id_str)) > 0
endfunction

" Returns a list of arguments that matched with the parser's argset.
" Each list entry is a dictionary containing the argument object and the
" associated value.
"
" This should be called after `parser()`.
function! argonaut#argparser#get_args(parser) abort
    call argonaut#argparser#verify(a:parser)
    let l:result = []
    
    " examine each of the arguments that were parsed
    for l:argresult in a:parser.args
        " if this argument has no argument specification, add it
        if !argonaut#utils#is_null(l:argresult.arg)
            call add(l:result, l:argresult)
        endif
    endfor

    return l:result
endfunction

" Returns a list of arguments that were parsed that did not match any of the
" specific arguments provided in the parser's argset.
"
" This should be called after `parser()`.
function! argonaut#argparser#get_extra_args(parser) abort
    call argonaut#argparser#verify(a:parser)
    let l:result = []
    
    " examine each of the arguments that were parsed
    for l:argresult in a:parser.args
        " if this argument has no argument specification, add it
        if argonaut#utils#is_null(l:argresult.arg)
            call add(l:result, l:argresult.value)
        endif
    endfor

    return l:result
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
    
    let l:result = deepcopy(s:argparser_result_template)
    let l:result.arg = a:arg
    return l:result
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
    let l:result = deepcopy(s:argparser_splitbit_template)
    let l:result.nesting_pair = a:nesting_pair
    return l:result
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
    let l:np = a:splitbit.nesting_pair
    if argonaut#utils#is_null(l:np)
        " does the text begin with '$'? It may be an environment variable that
        " was specified without the '{}' brackets
        let l:text = trim(a:splitbit.text)
        if argonaut#utils#str_begins_with(l:text, '$')
            let a:splitbit.text = expand(l:text)
        endif

        return
    endif

    " if the nesting pair has no post-process field, we're done
    if argonaut#utils#is_null(l:np.postprocess)
        return
    endif

    " otherwise, use the post-process value to determine what to do
    if l:np.postprocess == 'envvar'
        let l:envvar = argonaut#utils#get_env(trim(a:splitbit.text))
        if !argonaut#utils#is_null(l:envvar)
            let a:splitbit.text = l:envvar
        endif
    elseif l:np.postprocess == 'shell'
        let l:shellout = trim(argonaut#utils#run_shell_command(a:splitbit.text))
        let a:splitbit.text = l:shellout
    elseif l:np.postprocess == 'vim_command'
        let l:vimout = ''
        redir =>> l:vimout
        silent execute a:splitbit.text
        redir END
        let a:splitbit.text = trim(l:vimout)
    endif
endfunction

