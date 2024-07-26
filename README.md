# Argonaut

Argonaut is a Vim plugin that gives Vim scripts and plugin developers a simple,
yet powerful interface to create and parse custom command-line arguments for
Vim commands. It provides:

* A clean interface for building and parsing custom command arguments.
* Support for in-line shell command execution, vim command execution, and
  environment variable retrieval.
* Rich tab-completion support that auto-completes your custom arguments, file
  paths, environment variable names, etc.

Want to supercharge your Vim commands? Check it:

## Demo

Here is an example of Argonaut at work.

![](https://shugg.dev/images/argonaut.vim/argonaut_demo.gif)

## Installation

Install Argonaut with your preferred plugin manager:

```vim
" Vundle:
Plugin 'cwshugg/argonaut.vim'

" vim-plug
Plug 'cwshugg/argonaut.vim'

" minpac
call minpac#add('cwshugg/argonaut.vim')
```

Or, clone it manually:

```bash
$ git clone https://github.com/cwshugg/argonaut.vim ~/.vim/bundle/argonaut.vim
```

## Getting Started

Once you've installed Argonaut, you can open up the help page within Vim:

```vim
:h argonaut
:h argonaut-quickstart
```

This documents the entire function interface and the various objects that are
provided and used by Argonaut.

### Quick Start

Here's a quick look at how the plugin works. Start by setting up one or more
argument objects:

```vim
" Help argument: to display the help menu
let s:arg_help = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_help, argonaut#argid#new('-', 'h'))
call argonaut#arg#add_argid(s:arg_help, argonaut#argid#new('--', 'help'))

" Username argument: for the user to input their username (required!)
let s:arg_username = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_username, argonaut#argid#new('-', 'u'))
call argonaut#arg#add_argid(s:arg_username, argonaut#argid#new('--', 'name'))
call argonaut#arg#add_argid(s:arg_username, argonaut#argid#new('--', 'username'))
call argonaut#arg#set_presence_count_min(s:arg_username, 1)
call argonaut#arg#set_value_required(s:arg_username, 1)
call argonaut#arg#set_value_hint(s:arg_username, 'USERNAME')

" Password argument: for the user to input their password (required!)
let s:arg_password = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_password, argonaut#argid#new('-', 'p'))
call argonaut#arg#add_argid(s:arg_password, argonaut#argid#new('--', 'password'))
call argonaut#arg#set_presence_count_min(s:arg_password, 1)
call argonaut#arg#set_value_required(s:arg_password, 1)
call argonaut#arg#set_value_hint(s:arg_password, 'USERNAME')

" Command argument: for the user to specify commands to run once authenticated.
" We'll configure this to allow the user to specify up to 10 commands.
let s:arg_command = argonaut#arg#new()
call argonaut#arg#add_argid(s:arg_command, argonaut#argid#new('+', 'c'))
call argonaut#arg#add_argid(s:arg_command, argonaut#argid#new('++', 'command'))
call argonaut#arg#set_presence_count_max(s:arg_command, 10)
call argonaut#arg#set_value_required(s:arg_command, 1)
call argonaut#arg#set_value_hint(s:arg_command, 'COMMAND_STRING')
```

Next, set up an argument set to contain all of your arguments:

```vim
let s:argset = argonaut#argset#new()
call argonaut#argset#add_arg(s:argset, s:arg_help)
call argonaut#argset#add_arg(s:argset, s:arg_username)
call argonaut#argset#add_arg(s:argset, s:arg_password)
call argonaut#argset#add_arg(s:argset, s:arg_command)
```

Set up your command to execute a function. Have that function create an
`argparser` object and execute it. Make sure to set up a completion function to
take advantage of Argonaut's command completion!

```vim
" Tab-completion function for `your_command`
function! your_command_completion(arg, line, pos) abort
    return argonaut#completion#complete(a:arg, a:line, a:pos, s:argset)
endfunction

" Main command function for `your_command`
function! your_command(input) abort
    let l:parser = argonaut#argparser#new(s:argset)
    try
        call argonaut#argparser#parse(l:parser, a:input)
        
        " did the user specify your `--help` command? If so, we can show the
        " help menu and return
        if argonaut#argparser#has_arg(l:parser, '-h')
            call argonaut#argparser#show_help(l:parser)
            return
        endif

        " ... your command logic ...
    
    catch
        " before we show the error, check to see if the user specified your
        " `--help` command. Not necessary, but handy if you want `--help` to be
        " available even in the event of a parsing error!
        if argonaut#argparser#has_arg(l:parser, '-h')
            call argonaut#argparser#show_help(l:parser)
        endif
        echo string(v:exception)
    endtry
endfunction

" Command declaration for `your_command`. Make sure to use `<q-args>` so the
" Argonaut receives the command input as one concatenated string.
command!
    \ -nargs=*
    \ -complete=customlist,your_command_completion
    \ YourCommand
    \ call your_command(<q-args>)
```

