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
	" Possible Values: (default is 0)
	"   -1: Indent of 0, along left edge, like traditional Lisps.
	"    0: Indent in alignment with string start delimiter.
	"    1: Indent in alignment with end of the string start delimiter.
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

	if formtype ==# 'top'
		" At the top level, no indent.
		return 0
	elseif formtype ==# 'lst'
		" Inside a list.
		" TODO Begin analysis and apply rules!
		" echom getline(coord[0], v:lnum - 1)
		return coord[1] + 1
	elseif formtype ==# 'vec' || formtype ==# 'map'
		" Inside a vector, map or set.
		return coord[1]
	elseif formtype ==# 'str' || formtype ==# 'reg'
		" Mimic multi-line string indentation behaviour in VS Code and
		" Emacs.
		"
		" Scenarios:
		"   - "=" operator should NOT alter indentation within
		"     multi-line strings.
		"   - Changes made while in insert mode (e.g. "<CR>"), should
		"     use standard string indent.
		"   - All other commands from normal mode (e.g. "o" and "O")
		"     should trigger normal string indent.

		let m = mode()
		if m ==# 'i' || (m ==# 'n' && ! (v:operator ==# '=' && state() =~# 'o'))
			" If in insert mode, or (in normal mode and last
			" operator is not "=" and is not currently active.
			let rule = s:ShouldAlignMultiLineStrings()
			if rule == -1
				" No indent.
				return 0
			elseif rule == 1
				" Align with start of delimiter.
				return coord[1]
			else
				" Align with end of delimiter.
				return coord[1] - (formtype ==# 'reg' ? 2 : 1)
			endif
		endif
	endif

	" Keep existing indent.
	return -1
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
