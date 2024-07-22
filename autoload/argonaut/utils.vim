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
function! argonaut#utils#is_empty(str) abort
    return len(a:str) == 0
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
        return 1
    endif
    return 0
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

" Returns the value of the given environment variable, or v:null if it doesn't
" exist.
function! argonaut#utils#run_shell_command(text) abort
    :silent let s:result = system(a:text)
    return s:result
endfunction

