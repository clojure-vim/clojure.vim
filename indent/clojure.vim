" Vim indent file
" Language:            Clojure
" Maintainer:          Alex Vear <alex@vear.uk>
" Former Maintainers:  Sung Pae <self@sungpae.com>
"                      Meikel Brandmeyer <mb@kotka.de>
" Last Change:         %%RELEASE_DATE%%
" License:             Vim (see :h license)
" Repository:          https://github.com/clojure-vim/clojure.vim

if exists("b:did_indent")
	finish
endif
let b:did_indent = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

let b:undo_indent = 'setlocal autoindent< smartindent< expandtab< softtabstop< shiftwidth< indentexpr< indentkeys< lisp<'

setlocal noautoindent nosmartindent nolisp
setlocal softtabstop=2 shiftwidth=2 expandtab
setlocal indentkeys=!,o,O

function! s:GetSynIdName(line, col)
	return synIDattr(synID(a:line, a:col, 0), 'name')
endfunction

function! s:SyntaxMatch(pattern, line, col)
	return s:GetSynIdName(a:line, a:col) =~? a:pattern
endfunction

function! s:IgnoredRegion()
	return s:SyntaxMatch('\(string\|regex\|comment\|character\)', line('.'), col('.'))
endfunction

function! s:NotStringDelimiter()
	return ! s:SyntaxMatch('stringdelimiter', line('.'), col('.'))
endfunction

function! s:NotRegexpDelimiter()
	return ! s:SyntaxMatch('regexpdelimiter', line('.'), col('.'))
endfunction

function! s:Conf(opt, default)
	return get(b:, a:opt, get(g:, a:opt, a:default))
endfunction

function! s:ShouldAlignMultiLineStrings()
	return s:Conf('clojure_align_multiline_strings', 0)
endfunction

" Wrapper around "searchpairpos" that will automatically set "s:best_match" to
" the closest pair match and optimises the "stopline" value for later
" searches.  This results in a significant performance gain by reducing the
" number of syntax lookups that need to take place.
function! s:CheckPair(name, start, end, SkipFn)
	let prevln = s:best_match[1][0]
	let pos = searchpairpos(a:start, '', a:end, 'bznW', a:SkipFn, prevln)
	if prevln < pos[0] || (prevln == pos[0] && s:best_match[1][1] < pos[1])
		let s:best_match = [a:name, pos]
	endif
endfunction

function! s:GetClojureIndent()
	" Move cursor to the first column of the line we want to indent.
	call cursor(v:lnum, 1)

	" Improve accuracy of string detection when a newline is entered.
	if empty(getline(v:lnum))
		let strline = v:lnum - 1
		let synname = s:GetSynIdName(strline, len(getline(strline)))
	else
		let synname = s:GetSynIdName(v:lnum, 1)
	endif

	let s:best_match = ['top', [0, 0]]

	if synname =~? 'string'
		call s:CheckPair('str', '"', '"', function('<SID>NotStringDelimiter'))
	elseif synname =~? 'regex'
		call s:CheckPair('reg', '#\zs"', '"', function('<SID>NotRegexpDelimiter'))
	else
		let IgnoredRegionFn = function('<SID>IgnoredRegion')
		call s:CheckPair('lst',  '(',  ')', IgnoredRegionFn)
		call s:CheckPair('map',  '{',  '}', IgnoredRegionFn)
		call s:CheckPair('vec', '\[', '\]', IgnoredRegionFn)
	endif

	" Find closest matching higher form.
	let [formtype, coord] = s:best_match

	if formtype == 'top'
		" At the top level, no indent.
		return 0
	elseif formtype == 'lst'
		" Inside a list.
		" TODO Begin analysis and apply rules!
		" echom getline(coord[0], v:lnum - 1)
		return coord[1] + 1
	elseif formtype == 'vec' || formtype == 'map'
		" Inside a vector, map or set.
		return coord[1]
	elseif formtype == 'str'
		" Inside a string.
		" TODO: maintain string and regex indentation when `=` is pressed.
		return coord[1] - (s:ShouldAlignMultiLineStrings() ? 0 : 1)
	elseif formtype == 'reg'
		" Inside a regex.
		return coord[1] - (s:ShouldAlignMultiLineStrings() ? 0 : 2)
	else
		return -1
	endif
endfunction

if exists("*searchpairpos")
	setlocal indentexpr=s:GetClojureIndent()
else
	" If searchpairpos is not available, fallback to normal lisp
	" indenting.
	setlocal lisp indentexpr=
endif

let &cpoptions = s:save_cpo
unlet! s:save_cpo

" vim:sts=8:sw=8:ts=8:noet
