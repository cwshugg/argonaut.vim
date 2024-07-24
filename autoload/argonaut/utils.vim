" This file implements utility functions used by the plugin.


" ============================== Error Handling ============================== "
" Throws an error with the given message.
function! argonaut#utils#panic(msg) abort
    throw 'argonaut: ' . a:msg
endfunction


" ======================= Value/Parameter Sanitization ======================= "
" Returns true if the given value is considered null.
function! argonaut#utils#is_null(value) abort
    return a:value is v:null
endfunction

" Returns true if the given value is considered empty.
function! argonaut#utils#is_empty(value) abort
    return len(a:value) == 0
endfunction

" Examines the given parameter and returns v:null if it's empty.
" Otherwise, the original value is returned.
function! argonaut#utils#sanitize_value(value) abort
    if argonaut#utils#is_null(a:value) || argonaut#utils#is_empty(a:value)
        return v:null
    endif

    " let the original value pass through
    return a:value
endfunction

" Treats the given value as a boolean and returns exactly 0 or exactly 1.
function! argonaut#utils#sanitize_bool(value) abort
    if a:value
        return v:true
    endif
    return v:false
endfunction


" ============================== String Helpers ============================== "
" Compares two strings case-sensitively.
function! argonaut#utils#str_cmp(str1, str2) abort
    return a:str1 is# a:str2
endfunction

" Compares two strings case-insensitively.
function! argonaut#utils#str_cmp_case_insensitive(str1, str2) abort
    return a:str1 is? a:str2
endfunction

" Returns true if the string begins with the given prefix.
function! argonaut#utils#str_begins_with(str, prefix) abort
    let s:cmp_len = len(a:prefix)
    let s:cmp_str = strpart(a:str, 0, s:cmp_len)
    return argonaut#utils#str_cmp(s:cmp_str, a:prefix)
endfunction

" Returns true if the string begins with the given prefix.
function! argonaut#utils#str_begins_with_case_insensitive(str, prefix) abort
    let s:cmp_len = len(a:prefix)
    let s:cmp_str = strpart(a:str, 0, s:cmp_len)
    return argonaut#utils#str_cmp_case_insensitive(s:cmp_str, a:prefix)
endfunction

" Examines a single character and returns true if it's whitespace.
function! argonaut#utils#char_is_whitespace(char) abort
    return match(a:char, '\s\|\n\|\t\|\r') == 0
endfunction

" ============================ Shell/Environment ============================= "
" Returns the value of the given environment variable, or v:null if it doesn't
" exist.
function! argonaut#utils#get_env(name) abort
    return getenv(a:name)
endfunction

" Returns a dictionary of all environment variables.
function! argonaut#utils#get_envs() abort
    return environ()
endfunction

" Returns the value of the given environment variable, or v:null if it doesn't
" exist.
function! argonaut#utils#run_shell_command(text) abort
    :silent let s:result = system(a:text)
    return s:result
endfunction


" ============================== File Utilities ============================== "
" Returns the dirname of the given path.
function! argonaut#utils#get_dirname(path) abort
    return fnamemodify(a:path, ':h')
endfunction

" Returns the basename of the given path.
function! argonaut#utils#get_basename(path) abort
    return fnamemodify(a:path, ':t')
endfunction

" Returns true if the given path string points to a valid file.
function! argonaut#utils#is_file(path) abort
    return filereadable(a:path)
endfunction

" Returns true if the given path string points to a valid directory
function! argonaut#utils#is_dir(path) abort
    return isdirectory(a:path)
endfunction

" Returns a list of all files and directories in the given directory.
function! argonaut#utils#list_dir(path) abort
    " make sure the given path is valid
    if !argonaut#utils#is_dir(a:path)
        let s:errmsg = 'the given directory path (' . a:path .
                     \ ') does not point to a valid directory'
        call argonaut#utils#panic(s:errmsg)
    endif

    let s:result = []
    for s:file in split(globpath(a:path, '*'), "\n")
        " if the file is a valid file or directory, add it
        if argonaut#utils#is_file(s:file) || argonaut#utils#is_dir(s:file)
            call add(s:result, s:file)
        endif
    endfor

    return s:result
endfunction

