" -*- vim -*-
" FILE: "/home/wlee/vim/vimfiles/plugin/DirDo.vim" {{{
" LAST MODIFICATION: "Mon, 19 Aug 2002 16:39:00 -0700 (wlee)"
" VERSION: 1.1
" (C) 2002 by William Lee, <wlee@sendmail.com>
" }}}
" 
" PURPOSE: {{{
"   - Performs Vim commands over files recursively under multiple
"   directories.
"
"   - This plugin is like :argdo but it works recursively under a directory (or
"   multiple directories).  The limitation for :argdo is that it does not glob
"   the files inside the subdirectories.  DirDo works in a similar manner but
"   you're allowed to specify multiple directories (good for refactoring code
"   and modifying files in a deep hierarchy).  DirDo also globs the files in
"   the subdirectories so you can make sure an operation is performed
"   consistantly.
"   
" REQUIREMENTS:
"   - The :argdo command in Vim 6.0
"
" USAGE:
"   Put this file in your ~/.vim/plugin directory.
"
"   The syntax of the commands:
"
"   First we need to set what directory we would like to perform this
"   command on
"
"       :DirDoDir [/my/directory1] [/my/directory2] [/my/directory3]
"
"       or
"
"       :DDD [/my/directory1] [/my/directory2] [/my/directory3]
"
"   If no argument is given, then it'll display the directories that you're
"   going to work on and let you edit them by separating them with commas
"   (',')
"
"   You can also use the following command to add a directory to the DirDoDir
"   variable:
"
"       :DirDoAdd /my/dir
"
"       or
"
"       :DDA /my/dir
"
"   If you do not give an argument to DDA, it'll add the current working
"   directory to the DirDoDir variable.
"
"   Then we set the file glob pattern
"
"       :DirDoPattern [file glob pattern1] [file glob pattern2] ...
"
"       or
"
"       :DDP [file glob pattern1] [file glob pattern2] ...
"
"   If no argument is given, then it'll display the patterns and let you
"   edit them (separate each pattern with spaces).
"
"   Then, you can do:
"
"       :DirDo [commands]
"
"       or
"
"       :DDO [commands]
"
"   to executes the commands on each file that matches the glob pattern
"   recursively under the directories that you have specified.  The format of
"   [commands] is just like what you do on :argdo. See :help argdo for
"   details.
"
"   If no argument is given, then it'll reuse the last command.
"
"   Examples:
"
"   Replace all the instaces of "Foo" to "Bar" in all the Java or C files under
"   the directory /my/directory and its subdirectories, confirming each match:
"
"       :DDD /my/directory (or just :DDD<CR> and type it in)
"       :DDP *.java *.c (or just :DDP<CR> and type it in)
"       :DDO %s/Foo/Bar/gce | update
"
"   (See :h argdo for the commands after DDO.)
"
"   Same scenario but replacing "Bar" with "Baz" without confirmation for each
"   match (note the directory and patterns are saved):
"
"       :DDO %s/Bar/Baz/ge | update
"
"
"   There is an option to run DirDo with less verbosity, to toggle the
"   setting, run:
"
"       :DirDoVerbose
"
"       or
"
"       :DDV
"
"   You can also set the following variables in your .vimrc to set the default
"   directory and pattern.  This is good for pointing to the directories for
"   code refactoring:
"
"   let g:DirDoPattern = "..."
"
"   let g:DirDoDir = "..."
"
"   For example, if you want by default have the command apply on all your C,
"   C++, and Java source, you can set the DirDoPattern to:
"
"   let g:DirDoPattern = "*.c *.cpp *.java"
"
"   If you want to apply your changes to /dir1, /dir2, and /dir3, you can do:
"
"   let g:DirDoDir = "/dir1,/dir2,/dir3"
"
" CREDITS:
"
"   Please mail any comment/suggestion/patch to 
"
"   William Lee <wlee@sendmail.com>
"
"   (c) 2002. This script is under the same copyright as Vim itself.
"
" HISTORY:
"  1.0  - 8/7/2002 Initial release
"  1.1  - 8/19/2002 Added DirDoAdd command to add directory
"

" Mappings
command! -nargs=* DDO call <SID>DirDo(<f-args>)
command! -nargs=* DirDo call <SID>DirDo(<f-args>)

command! -nargs=0 DDV call <SID>DirDoVerbose()
command! -nargs=0 DirDoVerbose call <SID>DirDoVerbose()

command! -nargs=* -complete=dir DDD call <SID>DirDoDir(<f-args>)
command! -nargs=* -complete=dir DirDoDir call <SID>DirDoDir(<f-args>)

command! -nargs=* -complete=dir DDA call <SID>DirDoAdd(<f-args>)
command! -nargs=* -complete=dir DirDoAdd call <SID>DirDoAdd(<f-args>)

command! -nargs=* DDP call <SID>DirDoPattern(<f-args>)
command! -nargs=* DirDoPattern call <SID>DirDoPattern()

" Sort the import with preferences to the java.* classes
"
if !exists("g:DirDoPattern")
    let g:DirDoPattern = ""
endif

if !exists("g:DirDoDir")
    let g:DirDoDir = ""
endif

if !exists("g:DirDoVerbose")
    let s:Verbose = 1
else
    let s:Verbose = g:DirDoVerbose
endif

let s:LastCommand = ""

" Ask to enter the file
let s:AskFile = 1

" Ask to cancel the operation
let s:CancelFile = 0


" Sets the directory
fun! <SID>DirDoDir(...)
    " Constructs the arguments as a comma separated list
    if (a:0 != 0)
        let ctr = 1
        let g:DirDoDir = ""
        while (ctr <= a:0)
            if (g:DirDoDir != "")
                let g:DirDoDir = g:DirDoDir . ','
            endif
            let g:DirDoDir = g:DirDoDir . a:{ctr}
            let ctr = ctr + 1
        endwhile
    else
        " Edit the directories
        let g:DirDoDir = input ("Set DirDo directories (use ',' to separate multiple entries): " , g:DirDoDir)
    endif
endfun

" Adds to the DirDo directory
fun! <SID>DirDoAdd(...)
    " Constructs the arguments as a comma separated list
    if (a:0 != 0)
        let ctr = 1
        let add_dir = ""
        while (ctr <= a:0)
            if (add_dir != "")
                let add_dir = add_dir . ','
            endif
            let add_dir = add_dir . a:{ctr}
            let ctr = ctr + 1
        endwhile
        if (g:DirDoDir == "")
            let g:DirDoDir = add_dir
        else
            let g:DirDoDir = g:DirDoDir . ',' . add_dir
        endif
    else
        " Add the current directory of the current file to the DirDo Path
        let c_dir = getcwd()
        echo ("Adding to DirDoDir: " . c_dir)
        if (g:DirDoDir == "")
            let g:DirDoDir = c_dir
        else
            let g:DirDoDir = g:DirDoDir . ',' . c_dir
        endif
    endif
endfun

" Sets the pattern
fun! <SID>DirDoPattern(...)
    " Constructs the arguments as a comma separated list
    if (a:0 != 0)
        let ctr = 1
        let g:DirDoPattern = ""
        while (ctr <= a:0)
            if (g:DirDoPattern != "")
                let g:DirDoPattern = g:DirDoPattern . ' '
            endif
            let g:DirDoPattern = g:DirDoPattern . a:{ctr}
            let ctr = ctr + 1
        endwhile
    else
        " Edits the pattern
        let g:DirDoPattern = input ("Set DirDo glob patterns (use ' ' to separate multiple entries): " , g:DirDoPattern)
    endif
endfun

" Sets the directoris that we would like to work on
fun! <SID>DirDoVerbose()
    if (s:Verbose == 1)
        let s:Verbose = 0
        echo "Setting DirDo verbosity to off."
    else
        let s:Verbose = 1
        echo "Setting DirDo verbosity to on."
    endif
endfun

" Trim the string with white spaces in front or at the end
fun! <SID>TrimStr(str)
    let rtn = substitute(a:str, '\(^\s*\|\s$\)', '', 'g')
    return rtn
endfun

" Recursively apply the commands to the list of directories in DirDoDir
fun! <SID>DirDo(...)
    " Update the AskFile to true
    let s:AskFile = 1
    let s:CancelFile = 0

    " Save current document
    update

    " Constructs the arguments
    let ctr = 1
    let cmd = ""
    if (a:0 != 0)
        while (ctr <= a:0)
            if (cmd != "")
                let cmd = cmd . ' '
            endif
            let cmd = cmd . a:{ctr}
            let ctr = ctr + 1
        endwhile
        let s:LastCommand = cmd
    else
        let cmd = s:LastCommand
    endif

    echo "Directories: " . g:DirDoDir
    echo "Glob Pattern: " . g:DirDoPattern

    if (cmd == "")
        echo "You have to specify a command for DirDo!"
        return 1
    endif

    echo "Command: " . cmd
    let in = confirm("Run DirDo?", "&Yes\n&No", 1)
    if (in != 1)
        return 0
    endif

    let s:MatchRegexPattern = <SID>GetRegExPattern()
    let currPaths = <SID>TrimStr(g:DirDoDir)
    " See if currPaths has a ',' at the end, if not, we add it.
        "echo "currPaths begin is " . currPaths
    if (match(currPaths, ',$') == -1)
        let currPaths = currPaths . ','
    endif

    let fileCount = 0

    while (currPaths != "")
        let sepIdx = stridx(currPaths, ",")
        " Gets the substring exluding the newline
        let currPath = strpart(currPaths, 0, sepIdx)
        let currPath = <SID>TrimStr(currPath)
        if (s:Verbose == 1)
            echo "Applying command recursively in root path: " . currPath . " ..."
        endif
        let currPaths = strpart(currPaths, sepIdx + 1, strlen(currPaths) - sepIdx - 1)
        let fileCount = fileCount + <SID>DirDoHlp(currPath, cmd)
    endwhile
    " Reset the argument list
    argl
    echo "Done.  Applied command on " . fileCount . " files."
endfun

" Turns the global glob pattens into a regex pattern
fun! <SID>GetRegExPattern()
    " Trim the string
    let matchPat = <SID>TrimStr(g:DirDoPattern)
    if (matchPat == "")
        " Default to all file
        matchPat = '*'
    endif
    let matchPat = matchPat . ' '
    " We would like to change the * to .* and escape the . in the glob pattern
    " this will work on most cases...
    let patStr = substitute(matchPat, '\.', '\\.', 'g')
    let patStr = substitute(patStr, '\*', '.*', 'g')
    let patStr = substitute(patStr, '\s', '$\\|', 'g')
    " get rid of the extra \\| at the end
    let patStr = substitute(patStr, '\\|$', '', '')
    
    return ('\(' . patStr . '\)')
endfun

" The helper function to apply the command to a directory
fun! <SID>DirDoHlp(cpath, cmd)
    "echo "Arguments " . a:cpath . " cmd is " . a:cmd
    if (!isdirectory(a:cpath) && match(a:cpath, s:MatchRegexPattern) > -1)
        let i = 1
        if (s:CancelFile == 1)
            return 0
        endif
        if (s:Verbose == 1 && s:AskFile == 1)
            let i = confirm("Apply command to file " . a:cpath . "?", "&Yes\nYes for &All Files\n&No\n&Cancel", 1)
        endif
        if (i == 4)
            let s:CancelFile = 1
            return 0
        endif
        if (i == 3)
            return 0
        endif
        if (i == 2)
            let s:AskFile = 0
        endif

        exe "argl " . a:cpath
        exe "argdo " . a:cmd
        return 1
    else
        if (isdirectory(a:cpath))
            let files = glob(a:cpath . "/*")
            let files = files . "\n"

            let fileCtr = 0
            while (files != "" && files !~ '\n$')
                let sepIdx = stridx(files, "\n")
                " Gets the substring exluding the newline
                let file = strpart(files, 0, sepIdx)
                let files = strpart(files, sepIdx + 1, strlen(files) - sepIdx - 1)
                let fileCtr = fileCtr + <SID>DirDoHlp(file, a:cmd)
            endwhile
            return fileCtr
        endif
    endif
endfun

