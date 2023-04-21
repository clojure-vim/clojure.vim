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

" TODO: Optional Vim9script implementations of hotspot/bottleneck functions.
" FIXME: fallback case when syntax highlighting is disabled.

" Function to get the indentation of a line.
" function! s:GetIndent(lnum)
" 	let l = getline(a:lnum)
" 	return len(l) - len(trim(l, " \t", 1))
" endfunction

function! s:GetSynIdName(line, col)
	return synIDattr(synID(a:line, a:col, 0), 'name')
endfunction

function! s:SyntaxMatch(pattern, line, col)
	return s:GetSynIdName(a:line, a:col) =~? a:pattern
endfunction

function! s:IgnoredRegion()
	return s:SyntaxMatch('\vstring|regex|comment|character', line('.'), col('.'))
endfunction

function! s:NotAStringDelimiter()
	return ! s:SyntaxMatch('stringdelimiter', line('.'), col('.'))
endfunction

function! s:IsInString()
	return s:SyntaxMatch('string', line('.'), col('.'))
endfunction

function! s:NotARegexpDelimiter()
	return ! s:SyntaxMatch('regexpdelimiter', line('.'), col('.'))
endfunction

function! s:IsInRegex()
	return s:SyntaxMatch('regex', line('.'), col('.'))
endfunction

function! s:Conf(opt, default)
	return get(b:, a:opt, get(g:, a:opt, a:default))
endfunction

function! s:ShouldAlignMultiLineStrings()
	return s:Conf('clojure_align_multiline_strings', 0)
endfunction

function! s:ClosestMatch(match1, match2)
	let [_, coord1] = a:match1
	let [_, coord2] = a:match2
	if coord1[0] < coord2[0]
		return a:match2
	elseif coord1[0] == coord2[0] && coord1[1] < coord2[1]
		return a:match2
	else
		return a:match1
	endif
endfunction

" Only need to search up.  Never down.
function! s:GetClojureIndent()
	let lnum = v:lnum

	" Move cursor to the first column of the line we want to indent.
	cursor(lnum, 0)

	let matches = [
		\  ['lst', searchpairpos( '(', '',  ')', 'bznW', function('<SID>IgnoredRegion'))],
		\  ['vec', searchpairpos('\[', '', '\]', 'bznW', function('<SID>IgnoredRegion'))],
		\  ['map', searchpairpos( '{', '',  '}', 'bznW', function('<SID>IgnoredRegion'))],
		\  ['reg', s:IsInRegex() ? searchpairpos('#\zs"', '', '"', 'bznW', function('<SID>NotARegexpDelimiter')) : [0, 0]],
		\  ['str', s:IsInString() ? searchpairpos('"', '', '"', 'bznW', function('<SID>NotAStringDelimiter')) : [0, 0]]
		\ ]
	echom 'Matches' matches

	" Find closest matching higher form.
	let [formtype, coord] = reduce(matches, function('<SID>ClosestMatch'), ['top', [0, 0]])
	echom 'Match' formtype coord

	if formtype == 'top'
		" At the top level, no indent.
		echom 'At the top level!'
		return 0
	elseif formtype == 'lst'
		echom 'Special format rules!'
		" TODO
		" Grab text!
		echom getline(coord[0], lnum - 1)
		" Begin lexing!
		return coord[1] + 1
	elseif formtype == 'vec' || formtype == 'map'
		" Inside a vector, map or set.
		return coord[1]
	elseif formtype == 'reg'
		" Inside a regex.
		echom 'Inside a regex!'
		return coord[1] - (s:ShouldAlignMultiLineStrings() ? 0 : 2)
	elseif formtype == 'str'
		" Inside a string.
		echom 'Inside a string!'
		return coord[1] - (s:ShouldAlignMultiLineStrings() ? 0 : 1)
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
