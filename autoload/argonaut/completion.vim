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
    let s:argids = argonaut#completion#complete_argids(a:arglead, a:cmdline, a:cursorpos, a:argset)
    if len(s:argids) > 0
        return s:argids
    endif

    " next, look for environment variables
    let s:envvars = argonaut#completion#complete_envvars(a:arglead, a:cmdline, a:cursorpos)
    if len(s:envvars) > 0
        return s:envvars
    endif

    " next, look for files/directories
    let s:paths = argonaut#completion#complete_files(a:arglead, a:cmdline, a:cursorpos)
    if len(s:paths) > 0
        return s:paths
    endif
endfunction

" Returns a list of argument ID strings that align with the arguments
" contained within `argset`.
"
" The first three arguments in this function represent the three input values
" for a vim completion function. Run `:h command-completion-customlist` to see
" this in the vim documentation.
function! argonaut#completion#complete_argids(arglead, cmdline, cursorpos, argset) abort
    let s:argids = argonaut#argset#get_all_argids(a:argset)
    let s:result = []

    " for each of the identifiers, determine if the user's current input
    " matches the beginning of the argument. If it does, add it to a final
    " result
    for s:argid in s:argids
        let s:argid_str = argonaut#argid#to_string(s:argid)

        " if this argid allows for case-insensitive matching, we'll compare
        " here accordingly
        let s:argid_match = 0
        if argonaut#argid#get_case_sensitive(s:argid)
            let s:argid_match = argonaut#utils#str_begins_with(s:argid_str, a:arglead)
        else
            let s:argid_match = argonaut#utils#str_begins_with_case_insensitive(s:argid_str, a:arglead)
        endif

        " if there was a match, add it to the result
        if s:argid_match
            call add(s:result, s:argid_str)
        endif
    endfor

    return s:result
endfunction

" Uses the provided arguments to suggest file paths based on the user's
" current input.
function! argonaut#completion#complete_files(arglead, cmdline, cursorpos) abort
    " expand the argument in case environment variables are included
    let s:arg = expand(a:arglead)

    " examine the current user input; is it a valid directory?
    if argonaut#utils#is_dir(s:arg)
        " if so, we'll generate a list of all files within the directory and
        " return it
        return argonaut#utils#list_dir(s:arg)
    endif
    
    " otherwise, does the input match a specific file path? (Or, does it at
    " least match the beginning of the file's name?) If so, return it
    let s:path_dirname = argonaut#utils#get_dirname(s:arg)
    let s:path_basename = argonaut#utils#get_basename(s:arg)
    let s:files = split(globpath(s:path_dirname, s:path_basename . '*'), "\n")
    if len(s:files) > 0
        return s:files
    endif
endfunction

" Uses the provided arguments to suggest environment variable names as the
" user is typing an environment variable.
function! argonaut#completion#complete_envvars(arglead, cmdline, cursorpos) abort
    " does the user's current string start with the correct prefix?
    let s:prefix = v:null
    let s:suffix = v:null
    if argonaut#utils#str_begins_with(a:arglead, '${')
        let s:prefix = '${'
        let s:suffix = '}'
    elseif argonaut#utils#str_begins_with(a:arglead, '$')
        let s:prefix = '$'
        let s:suffix = ''
    endif

    " if environment variable syntax was not detected, return early
    if argonaut#utils#is_null(s:prefix)
        return []
    endif

    " otherwise, extract the name based on the detected prefix
    let s:prefix_len = len(s:prefix)
    let s:arglead_len = len(a:arglead)
    let s:name = strpart(a:arglead, s:prefix_len, s:arglead_len - s:prefix_len)
    
    " get a list of all defined environment variables and iterate through them
    let s:result = []
    let s:env = argonaut#utils#get_envs()
    for s:env_name in keys(s:env)
        " if the user's current input name matches the beginning of the
        " current environment variable, add it to the resulting list
        if argonaut#utils#str_begins_with(s:env_name, s:name)
            " build a string to add to the result, based on the prefix and
            " suffix that was parsed earlier
            let s:result_str = s:prefix . s:env_name . s:suffix
            call add(s:result, s:result_str)
        endif
    endfor

    return s:result
endfunction

