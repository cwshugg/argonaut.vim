" This file implements functions to assist with providing useful command
" completion that utilizes Argonaut.

" Performs all of the below completion functions in a specific order.
"
" If you don't care about the details of argonaut command completion and just
" want all the supported completion types to work, generally in the order you
" would expect them to, then call this function! Otherwise, you can pick and
" choose which of the below functions to call.
function! argonaut#completion#complete(arglead, cmdline, cursorpos, argset) abort
    " start by looking for any matching argument identifiers
    let l:argids = argonaut#completion#complete_argids(a:arglead, a:cmdline, a:cursorpos, a:argset)
    if len(l:argids) > 0
        return l:argids
    endif

    " next, look for environment variables
    let l:envvars = argonaut#completion#complete_envvars(a:arglead, a:cmdline, a:cursorpos)
    if len(l:envvars) > 0
        return l:envvars
    endif

    " next, look for files/directories
    let l:paths = argonaut#completion#complete_files(a:arglead, a:cmdline, a:cursorpos)
    if len(l:paths) > 0
        return l:paths
    endif
endfunction

" Returns a list of argument ID strings that align with the arguments
" contained within `argset`.
"
" The first three arguments in this function represent the three input values
" for a vim completion function. Run `:h command-completion-customlist` to see
" this in the vim documentation.
function! argonaut#completion#complete_argids(arglead, cmdline, cursorpos, argset) abort
    let l:argids = argonaut#argset#get_all_argids(a:argset)
    let l:result = []

    " for each of the identifiers, determine if the user's current input
    " matches the beginning of the argument. If it does, add it to a final
    " result
    for l:argid in l:argids
        let l:argid_str = argonaut#argid#to_string(l:argid)

        " if this argid allows for case-insensitive matching, we'll compare
        " here accordingly
        let l:argid_match = 0
        if argonaut#argid#get_case_sensitive(l:argid)
            let l:argid_match = argonaut#utils#str_begins_with(l:argid_str, a:arglead)
        else
            let l:argid_match = argonaut#utils#str_begins_with_case_insensitive(l:argid_str, a:arglead)
        endif

        " if there was a match, add it to the result
        if l:argid_match
            call add(l:result, l:argid_str)
        endif
    endfor

    return l:result
endfunction

" Uses the provided arguments to suggest file paths based on the user's
" current input.
function! argonaut#completion#complete_files(arglead, cmdline, cursorpos) abort
    " expand the argument in case environment variables are included
    let l:arg = expand(a:arglead)

    " examine the current user input; is it a valid directory?
    if argonaut#utils#is_dir(l:arg)
        " if so, we'll generate a list of all files within the directory and
        " return it
        return argonaut#utils#list_dir(l:arg)
    endif
    
    " otherwise, does the input match a specific file path? (Or, does it at
    " least match the beginning of the file's name?) If so, return it
    let l:path_dirname = argonaut#utils#get_dirname(l:arg)
    let l:path_basename = argonaut#utils#get_basename(l:arg)
    let l:files = split(globpath(l:path_dirname, l:path_basename . '*'), "\n")
    if len(l:files) > 0
        return l:files
    endif
endfunction

" Uses the provided arguments to suggest environment variable names as the
" user is typing an environment variable.
function! argonaut#completion#complete_envvars(arglead, cmdline, cursorpos) abort
    " does the user's current string start with the correct prefix?
    let l:prefix = v:null
    let l:suffix = v:null
    if argonaut#utils#str_begins_with(a:arglead, '${')
        let l:prefix = '${'
        let l:suffix = '}'
    elseif argonaut#utils#str_begins_with(a:arglead, '$')
        let l:prefix = '$'
        let l:suffix = ''
    endif

    " if environment variable syntax was not detected, return early
    if argonaut#utils#is_null(l:prefix)
        return []
    endif

    " otherwise, extract the name based on the detected prefix
    let l:prefix_len = len(l:prefix)
    let l:arglead_len = len(a:arglead)
    let l:name = strpart(a:arglead, l:prefix_len, l:arglead_len - l:prefix_len)
    
    " get a list of all defined environment variables and iterate through them
    let l:result = []
    let l:env = argonaut#utils#get_envs()
    for l:env_name in keys(l:env)
        " if the user's current input name matches the beginning of the
        " current environment variable, add it to the resulting list
        if argonaut#utils#str_begins_with(l:env_name, l:name)
            " build a string to add to the result, based on the prefix and
            " suffix that was parsed earlier
            let l:result_str = l:prefix . l:env_name . l:suffix
            call add(l:result, l:result_str)
        endif
    endfor

    return l:result
endfunction

