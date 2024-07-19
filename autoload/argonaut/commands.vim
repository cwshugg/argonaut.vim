" This file implements the front-facing functions for all plugin commands.

" DEBUGGING - TODO - REMOVE WHEN DONE DEVELOPING
function! argonaut#commands#test(...) abort
    try
        let s:a = argonaut#argument#new()
        call argonaut#argument#set_presence_required(s:a, 0)
        call argonaut#argument#set_presence_required(s:a, 1)
        call argonaut#argument#set_value_required(s:a, 1)
        echo 'ARGUMENT OBJECT: ' . argonaut#argument#to_string(s:a)
        
        let s:aid = argonaut#argument_id#new()
        call argonaut#argument_id#set_prefix(s:aid, '-')
        call argonaut#argument_id#set_name(s:aid, 'h')
        call argonaut#argument#add_identifier(s:a, s:aid)
        echo 'ARGUMENT OBJECT: ' . argonaut#argument#to_string(s:a)
        
        let s:aid = argonaut#argument_id#new()
        call argonaut#argument_id#set_prefix(s:aid, '--')
        call argonaut#argument_id#set_name(s:aid, 'hello')
        call argonaut#argument#add_identifier(s:a, s:aid)
        echo 'ARGUMENT OBJECT: ' . argonaut#argument#to_string(s:a)
        
        let s:aid = argonaut#argument_id#new()
        call argonaut#argument_id#set_prefix(s:aid, '++')
        call argonaut#argument_id#set_name(s:aid, 'HELLO')
        call argonaut#argument#add_identifier(s:a, s:aid)
        echo 'ARGUMENT OBJECT: ' . argonaut#argument#to_string(s:a)
    catch
        echoerr 'Caught an error: ' . v:exception
    endtry

    echo 'Argonaut tests complete!'
endfunction

