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

let b:undo_indent = 'setlocal autoindent< smartindent< expandtab< softtabstop< shiftwidth< indentexpr< indentkeys<'

setlocal noautoindent nosmartindent
setlocal softtabstop=2 shiftwidth=2 expandtab
setlocal indentkeys=!,o,O

" TODO: ignore 'lisp' and 'lispwords' options (actually, turn them off?)
" TODO: Optional Vim9script implementations of hotspot/bottleneck functions?
" FIXME: fallback case when syntax highlighting is disabled.

function! s:GetSynIdName(line, col)
	return synIDattr(synID(a:line, a:col, 0), 'name')
endfunction

function! s:SyntaxMatch(pattern, line, col)
	return s:GetSynIdName(a:line, a:col) =~? a:pattern
endfunction

function! s:IgnoredRegion()
	return s:SyntaxMatch('\(string\|regex\|comment\|character\)', line('.'), col('.'))
endfunction

function! s:NotAStringDelimiter()
	return ! s:SyntaxMatch('stringdelimiter', line('.'), col('.'))
endfunction

function! s:NotARegexpDelimiter()
	return ! s:SyntaxMatch('regexpdelimiter', line('.'), col('.'))
endfunction

function! s:Conf(opt, default)
	return get(b:, a:opt, get(g:, a:opt, a:default))
endfunction

function! s:ShouldAlignMultiLineStrings()
	return s:Conf('clojure_align_multiline_strings', 0)
endfunction

" Wrapper around "searchpairpos" that will automatically set "s:best_match" to
" the closest pair match and continuously optimise the "stopline" value for
" later searches.  This results in a significant performance gain by reducing
" the number of syntax lookups that need to take place.
function! s:CheckPair(name, start, end, skipfn)
	let prevln = s:best_match[1][0]
	let pos = searchpairpos(a:start, '', a:end, 'bznW', a:skipfn, prevln)
	if prevln < pos[0] || (prevln == pos[0] && s:best_match[1][1] < pos[1])
		let s:best_match = [a:name, pos]
	endif
endfunction

function! s:GetClojureIndent()
	let lnum = v:lnum

	" Move cursor to the first column of the line we want to indent.
	cursor(lnum, 0)

	let s:best_match = ['top', [0, 0]]

	call s:CheckPair('lst',  '(',  ')', function('<SID>IgnoredRegion'))
	call s:CheckPair('map',  '{',  '}', function('<SID>IgnoredRegion'))
	call s:CheckPair('vec', '\[', '\]', function('<SID>IgnoredRegion'))

	let synname = s:GetSynIdName(lnum, col('.'))
	if synname =~? 'string'
		call s:CheckPair('str', '"', '"', function('<SID>NotAStringDelimiter'))
	elseif synname =~? 'regex'
		call s:CheckPair('reg', '#\zs"', '"', function('<SID>NotARegexpDelimiter'))
	endif

	" Find closest matching higher form.
	let [formtype, coord] = s:best_match
	" echom 'Match' formtype coord

	if formtype == 'top'
		" At the top level, no indent.
		return 0
	elseif formtype == 'lst'
		" Inside a list.
		" TODO Begin analysis and apply rules!
		" echom getline(coord[0], lnum - 1)
		return coord[1] + 1
	elseif formtype == 'vec' || formtype == 'map'
		" Inside a vector, map or set.
		return coord[1]
	elseif formtype == 'str'
		" Inside a string.
		return coord[1] - (s:ShouldAlignMultiLineStrings() ? 0 : 1)
	elseif formtype == 'reg'
		" Inside a regex.
		return coord[1] - (s:ShouldAlignMultiLineStrings() ? 0 : 2)
	endif

	return 2
endfunction


setlocal indentexpr=s:GetClojureIndent()


" TODO: if exists("*searchpairpos")
" In case we have searchpairpos not available we fall back to normal lisp
" indenting.
"setlocal indentexpr=
"setlocal lisp
"let b:undo_indent .= '| setlocal lisp<'

let &cpoptions = s:save_cpo
unlet! s:save_cpo

" vim:sts=8:sw=8:ts=8:noet
