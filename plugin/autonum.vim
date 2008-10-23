"Author  : Arun Easi
"email   : arunke@yahoo.com
"date    : Tue Oct 21 17:36:31 PDT 2008
"version : 2.0
"
"Description: This script auto-numbers a list.
"
"General recommended settings for editing "*.txt" files
"set nocp et ts=4 sw=4 tw=80 ai
"
"HOW TO INSTALL (requires vim 7.0):
" - Drop the plugin under $HOME/.vim/plugin or
" - :source autonum.vim
"
"HOW TO USE:
" 1. Edit a file
" 2. Insert a number in the below-explained manner (1. )
" 3. Hit enter (A number is automatically inserted for you)
" 4. Hit ctrl-t, line is indented and numbered
" 5. If there are several levels of numbers, ctrl-d and ctrl-t could
"    be used to insert the next number in sequence at the indent level
"    your cursor is in.
" 6. Hit ctrl-g to remove the inserted number
" 7. Hit ctrl-l to forcefully autonumber
"
"Number format expected: "\<\(\d\+\|\a\)\>\W "
" In words: <word-boundary><(numerals or alphabets)><non-word-char><space>
" eg: "1. ",     "32) ",         "a] ",     "D> "
"
" keymappings: ENTER, ctrl-d, ctrl-t, ctlr-l & ctrl-g all in insert mode
"  \as   : To start AutoNumbering
"  \as   : To stop AutoNumbering (yeah, it toggles :)
"  ENTER : start with next number (add 1 to previous)
"  ctrl-d: indent one level back and try to autonumber
"  ctrl-t: indent one level forward and try to autonumber
"  ctrl-l: autonumber.
"  ctrl-g: remove numbering on the line
"
" Known Issue: Does not work inside comments
"
"Uncomment next line to enable mapping always (no need to type \as to on it)
"let g:an_map_enabled_start=1

let s:ind_pat='^\s*'
let s:num_pat='\<\(\d\+\|\a\)\>'
let s:delim_pat='\W '

fu! IncNum(num)
    let num=a:num
    if num =~ '^\d'
        let new_num=num+1
    else
        let new_num=nr2char(char2nr(num)+1)
    endif
    return new_num
endf

fu! CreateNum()
    let cur_ind=matchend(getline('.'), '^\s*')
    if cur_ind < 1 | return '1. ' |endif
    let num_pat=s:num_pat
    let delim_pat=s:delim_pat

    let less_ind_pat='^\s\{,'.(cur_ind-1).'}'
    let lsl=search(less_ind_pat.num_pat.delim_pat, 'nbW')
    if lsl == 0 "We do not have a hit
        return '1. '
    endif

    let num=matchstr(getline(lsl), less_ind_pat.'\zs'.num_pat.'\ze')
    if num == "" |return "bug!"|endif

    return (num =~ '\d') ? 'a. ' : '1. '
endf

fu! GetStr()
    let cur_ind=matchend(getline('.'), '^\s*')
    let ind_pat='^\s\{'.cur_ind.'}'
    let num_pat=s:num_pat
    let delim_pat=s:delim_pat

    let sl=search(ind_pat.num_pat.delim_pat, 'nbW')
    if sl == 0| return "" |endif

    if cur_ind >= 1
        let less_ind_pat='^\s\{,'.(cur_ind-1).'}'
        let lsl=search(less_ind_pat.num_pat.delim_pat, 'nbW')
        "Check if another main section comes between 'sl' and current line
        if lsl != 0 && lsl > sl | return "" |endif
    endif

    let num=matchstr(getline(sl), ind_pat.'\zs'.num_pat.'\ze')
    if num == "" |return ""|endif

    let suff=matchstr(getline(sl), ind_pat.num_pat.'\zs'.delim_pat.'\ze')
    let new_num=IncNum(num)
    return new_num.suff
endf

fu! PutStr(str)
    let str=a:str
    "if str == "" | return | endif
    exe "norm! ^s".str."\<esc>"
endf

fu! DelNum()
    let npat=s:ind_pat.s:num_pat.s:delim_pat
    let match=matchstr(getline('.'), npat)
    if match == "" |return |endif
    let indent=matchstr(getline('.'), '^\s*')
    let nline=matchstr(getline('.'), npat.'\zs.*')
    exe "norm! 0Di".indent.nline."\<esc>"
endf

fu! AutoNumber(key)
    let key=a:key
    if key == "return"
        let cr1=col('.') != col('$')-1 && col('$') != 1
        let cr2=getline(line(".")) !~ s:ind_pat.s:num_pat.s:delim_pat
        let cr3=getline(line(".")) !~ '^\s*$'
        if cr1 || (cr2 && cr3)
            "Middle of line, Not a numbered line OR blank line
            let ins=(col('.') == col('$')-1) ? 0 : 1
            let ncmd=(col('.') == 1) ? 'i' : 'a'
            exe "norm! ".ncmd."\<cr>.\<bs>\<right>"
            if cr2 == 0
                "Prev line is a numbered list, so indent cur-line
                let plen=strlen(matchstr(getline(line('.')-1),
                \                '^\zs\s*'.s:num_pat.s:delim_pat.'\ze'))
                let clen=plen-strlen(matchstr(getline(line('.')),'^\zs\s*'))
                exe "norm! i".repeat(' ', clen)."\<esc>l"
            endif
            "When hitting newline we want to be at end of line
            return (ins ? 0 : 1)
        endif
        exe "norm! A\<cr>.\<esc>"
        sil! exe '-|s/^\s*$//|+'
    elseif key == "ind-more"
        call DelNum()
        let ncmd=(getline('.') =~ '.*\S') ? 'I' : 'a'
        exe "norm! ".ncmd."\<c-t>.\<esc>"
        let str=GetStr()
        if str == ""
            let str=CreateNum()
        endif
        call PutStr(str)
        return 1
    elseif key == "ind-less"
        call DelNum()
        let ncmd=(getline('.') =~ '.*\S') ? 'I' : 'a'
        exe "norm! ".ncmd."\<c-d>.\<esc>"
        let str=GetStr()
        if str == ""
            let str=CreateNum()
        endif
        call PutStr(str)
        return 1
    elseif key == "auto-num"
        call DelNum()
        exe "norm! I.\<esc>"
    elseif key == "rm-auto-num"
        let l=strlen(getline('.'))
        call DelNum()
        let nl=strlen(getline('.'))
        exe "norm!I".repeat(' ', l-nl)."\<esc>"
        return 1
    endif
    let str=GetStr()
    call PutStr(str)
    return 1
endf

fu! AN_Map(op)
    if version < 700
        echo "!Error: autonum.vim is supported only with vim version >= 7.0"
        return
    endif
    if (!exists("s:an_mapped"))
        let s:an_mapped = 0
    endif

    if (s:an_mapped == 0)
        let s:an_mapped = 1
        ino <cr> <esc>:exe AutoNumber("return") ? 'star!' : 'star'<cr>
        ino <c-g> <esc>:exe AutoNumber("rm-auto-num") ? 'star!' : 'star'<cr>
        ino <c-t> <esc>:exe AutoNumber("ind-more") ? 'star!' : 'star'<cr>
        ino <c-d> <esc>:exe AutoNumber("ind-less") ? 'star!' : 'star'<cr>
        ino <c-l> <esc>:exe AutoNumber("auto-num") ? 'star!' : 'star'<cr>

        if a:op != "load" | echo "auto numbering ON" | endif
    else
        let s:an_mapped = 0
        sil! iunmap <cr>
        sil! iunmap <c-d>
        sil! iunmap <c-t>
        sil! iunmap <c-l>
        if a:op != "load" | echo "auto numbering OFF" | endif
    endif
endf

noremap <Leader>as  :call AN_Map("")<cr>

if exists("g:an_map_enabled_start") && g:an_map_enabled_start == 1
    let s:an_mapped=0
    call AN_Map("load")
endif
