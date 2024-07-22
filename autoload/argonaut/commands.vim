" This file implements the front-facing functions for all plugin commands.

" DEBUGGING - TODO - REMOVE WHEN DONE DEVELOPING
function! argonaut#commands#test(...) abort
    try
        let s:a1 = argonaut#arg#new()
        call argonaut#arg#set_presence_count_min(s:a1, 1)
        call argonaut#arg#set_value_required(s:a1, 1)
        echo 'ARGUMENT OBJECT: ' . argonaut#arg#to_string(s:a1)
        
        let s:aid = argonaut#argid#new()
        call argonaut#argid#set_prefix(s:aid, '-')
        call argonaut#argid#set_name(s:aid, 'h')
        call argonaut#arg#add_argid(s:a1, s:aid)
        echo 'ARGUMENT OBJECT: ' . argonaut#arg#to_string(s:a1)
        
        let s:aid = argonaut#argid#new()
        call argonaut#argid#set_prefix(s:aid, '--')
        call argonaut#argid#set_name(s:aid, 'hello')
        call argonaut#arg#add_argid(s:a1, s:aid)
        echo 'ARGUMENT OBJECT: ' . argonaut#arg#to_string(s:a1)

        let s:a2 = argonaut#arg#new()
        call argonaut#arg#set_presence_count_min(s:a2, 0)
        call argonaut#arg#set_presence_count_max(s:a2, 4)
        call argonaut#arg#set_value_required(s:a2, 0)
        let s:aid = argonaut#argid#new()
        call argonaut#argid#set_prefix(s:aid, '+')
        call argonaut#argid#set_name(s:aid, 'gb')
        call argonaut#arg#add_argid(s:a2, s:aid)
        let s:aid = argonaut#argid#new()
        call argonaut#argid#set_prefix(s:aid, '++')
        call argonaut#argid#set_name(s:aid, 'goodbye')
        call argonaut#arg#add_argid(s:a2, s:aid)
        
        let s:set = argonaut#argset#new()
        echo 'ARGSET: ' . argonaut#argset#to_string(s:set)
        call argonaut#argset#add_arg(s:set, s:a1)
        echo 'ARGSET: ' . argonaut#argset#to_string(s:set)
        call argonaut#argset#add_arg(s:set, s:a2)
        echo 'ARGSET: ' . argonaut#argset#to_string(s:set)
    
        let s:str = '++goodbye'
        let s:a = argonaut#argset#cmp(s:set, s:str)
        if argonaut#utils#is_null(s:a)
            echo 'ARGSET CMP AGAINST "' . s:str . '" = NULL'
        else
            echo 'ARGSET CMP AGAINST "' . s:str . '" = ' . argonaut#arg#to_string(s:a)
        endif
        
        " ARG PARSER
        let s:parser = argonaut#argparser#new()
        call argonaut#argparser#set_argset(s:parser, s:set)

        let s:parse_str = "hello there     ++goodbye \"my name\\\" is 'connor' \"     testing --hello"
        let s:parse_result = argonaut#argparser#parse(s:parser, s:parse_str)
    catch
        echoerr 'Caught an error: ' . v:exception
    endtry

    echo 'Argonaut tests complete!'
endfunction

