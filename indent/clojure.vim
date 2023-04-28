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
	return s:SyntaxMatch('\%(string\|regex\|comment\|character\)', line('.'), col('.'))
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

function! s:EqualsOperatorInEffect()
	" Returns 1 when the previous operator used is "=" and is currently in
	" effect (i.e. "state" includes "o").
	return v:operator ==# '=' && state('o') ==# 'o'
endfunction

function! s:GetStringIndent(delim_pos, regex)
	" Mimic multi-line string indentation behaviour in VS Code and Emacs.
	let m = mode()
	if m ==# 'i' || (m ==# 'n' && ! s:EqualsOperatorInEffect())
		" If in insert mode, or normal mode but "=" is not in effect.
		let rule = s:Conf('clojure_align_multiline_strings', 0)
		if rule == -1
			" Indent along left edge, like traditional Lisps.
			return 0
		elseif rule == 1
			" Indent in alignment with end of the string start delimiter.
			return a:delim_pos[1]
		else
			" Indent in alignment with string start delimiter.
			return a:delim_pos[1] - (a:regex ? 2 : 1)
		endif
	else
		return -1  " Keep existing indent.
	endif
endfunction

function! s:GetListIndent(delim_pos)
	" TODO Begin analysis and apply rules!
	let ln1 = getline(delim_pos[0])
	let sym = get(split(ln1[delim_pos[1]:], '[[:space:],;()\[\]{}@\\"^~`]', 1), 0, -1)
	if sym != -1 && ! empty(sym) && match(sym, '^[0-9:]') == -1
		" TODO: align indentation.
		return delim_pos[1] + 1  " 2 space indentation
	endif

	" TODO: switch between 1 vs 2 space indentation.
	return delim_pos[1]  " 1 space indentation
endfunction

" Wrapper around "searchpairpos" that will automatically set "s:best_match" to
" the closest pair match and optimises the "stopline" value for later
" searches.  This results in a significant performance gain by reducing the
" search distance and number of syntax lookups that need to take place.
function! s:CheckPair(name, start, end, SkipFn)
	let prevln = s:best_match[1][0]
	let pos = searchpairpos(a:start, '', a:end, 'bznW', a:SkipFn, prevln)
	if prevln < pos[0] || (prevln == pos[0] && s:best_match[1][1] < pos[1])
		let s:best_match = [a:name, pos]
	endif
endfunction

function! s:GetCurrentSynName(lnum)
	if empty(getline(a:lnum))
		" Improves the accuracy of string detection when a newline is
		" entered while in insert mode.
		let strline = a:lnum - 1
		return s:GetSynIdName(strline, strlen(getline(strline)))
	else
		return s:GetSynIdName(a:lnum, 1)
	endif
endfunction

function! s:GetClojureIndent()
	" Move cursor to the first column of the line we want to indent.
	call cursor(v:lnum, 1)

	let s:best_match = ['top', [0, 0]]

	let synname = s:GetCurrentSynName(v:lnum)
	if synname =~? 'string'
		call s:CheckPair('str', '"', '"', function('<SID>NotStringDelimiter'))
		" Sometimes, string highlighting does not kick in correctly,
		" until after this first "s:CheckPair" call, so we have to
		" detect and attempt an automatic correction.
		let new_synname = s:GetCurrentSynName(v:lnum)
		if new_synname !=# synname
			echoerr 'Misdetected string!  Retrying...'
			let s:best_match = ['top', [0, 0]]
			let synname = new_synname
		endif
	endif

	if synname =~? 'string'
		" We already checked this above, so pass through this block.
	elseif synname =~? 'regex'
		call s:CheckPair('reg', '#\zs"', '"', function('<SID>NotRegexpDelimiter'))
	else
		let IgnoredRegionFn = function('<SID>IgnoredRegion')
		if bufname() ==? '\.edn$'
			" If EDN file, check list pair last.
			call s:CheckPair('map',  '{',  '}', IgnoredRegionFn)
			call s:CheckPair('vec', '\[', '\]', IgnoredRegionFn)
			call s:CheckPair('lst',  '(',  ')', IgnoredRegionFn)
		else
			" If CLJ file, check list pair first.
			call s:CheckPair('lst',  '(',  ')', IgnoredRegionFn)
			call s:CheckPair('map',  '{',  '}', IgnoredRegionFn)
			call s:CheckPair('vec', '\[', '\]', IgnoredRegionFn)
		endif
	endif

	" Find closest matching higher form.
	let [formtype, coord] = s:best_match

	if formtype ==# 'top'
		" At the top level, no indent.
		return 0
	elseif formtype ==# 'lst'
		" Inside a list.
		return s:GetListIndent(coord)
	elseif formtype ==# 'vec' || formtype ==# 'map'
		" Inside a vector, map or set.
		return coord[1]
	elseif formtype ==# 'str'
		" Inside a string.
		return s:GetStringIndent(coord, 0)
	elseif formtype ==# 'reg'
		" Inside a regular expression.
		return s:GetStringIndent(coord, 1)
	else
		" Keep existing indent.
		return -1
	endif
endfunction

if exists("*searchpairpos")
	setlocal indentexpr=s:GetClojureIndent()
else
	" If "searchpairpos" is not available, fallback to Lisp indenting.
	setlocal lisp
endif

let &cpoptions = s:save_cpo
unlet! s:save_cpo

" vim:sts=8:sw=8:ts=8:noet
