"Author: Arun Easi
"email : arunke@yahoo.com
"date  : Fri Nov 22 16:15:02 PST 2002
"Description: To do autonumbering of a list.
"
" NOTE: VIM 6.0 or greater is required for this to work
"
" Key Mappings
"  \as   : To start AutoNumbering
"  \as   : To stop AutoNumbering (yeah, it toggles :)
"  ENTER : start with next number (add 1 to previous)
"  ctrl-d: indent one level back and try to autonumber
"  ctrl-t: indent one level forward and try to autonumber
"  ctrl-l: autonumber. if this sees any number in any of the lines above
"          this line at the same column, it will try to autonumber
" Known limitations:
"  1. <c-t>/<c-d> does not work well inside comments (try to make use of
"     <c-l>, if something screws up
"
" TIPS:
"  if this does not seem to work, put the following line in your vimrc
"       se nocp cpo-=<
"
"===============================================================================
" Version   Description                                             Date
"-------------------------------------------------------------------------------
"   1.00    First submit :)                                         Mar 09, '03
"===============================================================================

fu! AutoNumber(key)
    let key=a:key
    let t1col=virtcol(".")
    let lcol=virtcol("$")
    if key == "cr"
        exe "norm! a\<cr>1\<esc>"
        let t2col=t1col
    elseif key == "cd"
        exe "norm! I11\<esc>h"
        sil! exe 'norm! ld/\%#\d\+\W\=\s*/e'."\<cr>"
        call histdel("search", -1)
        exe "norm! I\<c-d>\<esc>"
        let t2col=t1col-(virtcol("$")-lcol)
        if virtcol(".") != 1
            norm! l
        endif
    elseif key == "ct"
        exe "norm! I11\<esc>h"
        sil! exe 'norm! ld/\%#\d\+\W\=\s*/e'."\<cr>"
        call histdel("search", -1)
        exe "norm! I\<c-t>\<esc>l"
        let t2col=t1col+(virtcol("$")-lcol)
    elseif key == "nu"
        let t2col=t1col
        exe "norm! a1\<esc>"
    endif
    let ccol=virtcol(".")
    sil! exe '?\%'.ccol.'v\<\d? mark k'
    call histdel("search", -1)
    if line("'k") >= line(".")
        exe "norm! s\<esc>".t2col.'|'
        return
    endif
    let cl = getline("'k")
    let cn = substitute(cl, '.*\(\d*\%'.ccol.'v\d*\).*', '\1', 'g')
    if cn !~ '^\d\+$'
        exe "norm! s\<esc>".t2col.'|'
        return
    endif
    let cnf = substitute(cl, '^.*\d*\%'.ccol.'v\d*\(\W\=\s*\).*', '\1', 'g')
    let num_z = substitute(cn, '^\(0*\)\(\d*\)', '\1', 'g')
    let act_n = substitute(cn, '^\(0*\)\(\d*\)', '\2', 'g')
    let cn = act_n + 1
    let num_z_len = strlen(num_z)
    if (num_z_len)
        if (strlen(act_n) != strlen(cn))
            let num_z = substitute(num_z, '.\(.*\)', '\1', 'g')
        endif
        let cn=num_z.cn
    endif
    exe "norm! s\<c-r>=cn.cnf\<cr>\<esc>"
    let t2col=t1col+(virtcol("$")-lcol)
    exe "norm! ".t2col."|"
endf

"1<bs> is a kludge to avoid vim placing cursor to start
"of line, if it has just auto-indented
fu! AN_Map(op)
    if (!exists("b:an_mapped"))
        let b:an_mapped = 1
    endif

    if (b:an_mapped == 1)
        let b:an_mapped = 0
        inoremap <cr>  <esc>:call AutoNumber("cr")<cr>a
        inoremap <c-d> 1<bs><esc>:call AutoNumber("cd")<cr>a
        inoremap <c-t> 1<bs><esc>:call AutoNumber("ct")<cr>a
        inoremap <c-l> 1<bs><esc>:call AutoNumber("nu")<cr>a
        echo "auto numbering ON"
    else
        let b:an_mapped = 1
        iunmap <cr>
        iunmap <c-d>
        iunmap <c-t>
        iunmap <c-l>
        echo "auto numbering OFF"
    endif
endf

noremap <Leader>as  :call AN_Map("")<cr>
