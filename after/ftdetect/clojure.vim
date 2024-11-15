if get(g:, 'clojure_detect_unofficial_exts', 1)
    autocmd BufNewFile,BufRead {build,profile}.boot,*.bb,*.clj_kondo setlocal filetype=clojure
endif
