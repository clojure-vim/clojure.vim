let g:clojure_indent_multiline_strings = 'traditional'
normal! gg=G
normal! G
exec "normal! o\<CR>test \"hello\<CR>world\""
exec "normal! o\<CR>regex #\"asdf\<CR>bar\""
