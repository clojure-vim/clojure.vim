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

" Returns true if char_idx is preceded by an odd number of backslashes.
function! s:IsEscaped(line_str, char_idx)
	let ln = a:line_str[: a:char_idx - 1]
	return (strlen(ln) - strlen(trim(ln, '\', 2))) % 2
endfunction

let s:pairs = {'(': ')', '[': ']', '{': '}'}

" TODO: Maybe write a Vim9script version of this?
" Repeatedly search for tokens on the given line in reverse order building up
" a list of tokens and their positions.  Ignores escaped tokens.
function! s:AnalyseLine(line_num)
	let tokens = []
	let ln = getline(a:line_num)

	while 1
		" Due to legacy Vimscript being painfully slow, we literally
		" have to move the cursor and perform searches which is
		" ironically faster than for looping by character.
		let token = searchpos('[()\[\]{};"]', 'bW', a:line_num)

		if token == [0, 0] | break | endif
		let t_idx = token[1] - 1
		if s:IsEscaped(ln, t_idx) | continue | endif
		let t_char = ln[t_idx]

		if t_char ==# ';'
			" Comment found, reset the token list for this line.
			tokens = []
		elseif t_char =~# '[()\[\]{}"]'
			" Add token to the list.
			call add(tokens, [t_char, token])
		endif
	endwhile

	return tokens
endfunction

" This should also be capable of figuring out if we're in a multi-line string
" or regex.
function! s:InverseRead(lnum)
	let lnum = a:lnum - 1
	let tokens = []

	while lnum > 0
		call cursor(lnum + 1, 1)
		let line_tokens = s:AnalyseLine(lnum)

		" let should_ignore = empty(a:tokens) ? 0 : (a:tokens[-1][0] ==# '"')

		" Reduce "tokens" and "line_tokens".
		for t in line_tokens
			" TODO: attempt early termination.
			if empty(tokens)
				call add(tokens, t)
			elseif t[0] ==# '"' && tokens[-1][0] ==# '"'
				" TODO: track original start and ignore values
				" inside strings.
				call remove(tokens, -1)
			elseif get(s:pairs, t[0], '') ==# tokens[-1][0]
				" Matching pair: drop the last item in tokens.
				call remove(tokens, -1)
			else
				" No match: append to token list.
				call add(tokens, t)
			endif
		endfor

		" echom 'Pass' lnum tokens

		if ! empty(tokens) && has_key(s:pairs, tokens[0][0])
			" TODO: on string match, check if string or regex.
			" echom 'Match!' tokens[0]
			return tokens[0]
		endif

		let lnum -= 1
	endwhile

	return ['^', [0, 0]]  " Default to top-level.
endfunction

function! s:Conf(opt, default)
	return get(b:, a:opt, get(g:, a:opt, a:default))
endfunction

function! s:EqualsOperatorInEffect()
	" Returns 1 when the previous operator used is "=" and is currently in
	" effect (i.e. "state" includes "o").
	return v:operator ==# '=' && state('o') ==# 'o'
endfunction

function! s:GetStringIndent(delim_pos, is_regex)
	" Mimic multi-line string indentation behaviour in VS Code and Emacs.
	let m = mode()
	if m ==# 'i' || (m ==# 'n' && ! s:EqualsOperatorInEffect())
		" If in insert mode, or normal mode but "=" is not in effect.
		let alignment = s:Conf('clojure_align_multiline_strings', 0)
		" -1: Indent along left edge, like traditional Lisps.
		"  0: Indent in alignment with end of the string start delimiter.
		"  1: Indent in alignment with string start delimiter.
		if     alignment == -1 | return 0
		elseif alignment ==  1 | return a:delim_pos[1]
		else                   | return a:delim_pos[1] - (a:is_regex ? 2 : 1)
		endif
	else
		return -1  " Keep existing indent.
	endif
endfunction

function! s:GetListIndent(delim_pos)
	" TODO Begin analysis and apply rules!
	" let lns = getline(delim_pos[0], v:lnum - 1)
	let ln1 = getline(delim_pos[0])
	let sym = get(split(ln1[delim_pos[1]:], '[[:space:],;()\[\]{}@\\"^~`]', 1), 0, -1)
	if sym != -1 && ! empty(sym) && match(sym, '^[0-9:]') == -1
		" TODO: align indentation.
		" TODO: lookup rules.
		return delim_pos[1] + 1  " 2 space indentation
	endif

	" TODO: switch between 1 vs 2 space indentation.
	return delim_pos[1]  " 1 space indentation
endfunction

function! s:GetClojureIndent()
	" Calculate and return indent to use based on the matching form.
	let [formtype, coord] = s:InverseRead(v:lnum)
	if     formtype ==# '^'  | return 0  " At top-level, no indent.
	elseif formtype ==# '('  | return s:GetListIndent(coord)
	elseif formtype ==# '['  | return coord[1]  " Vector
	elseif formtype ==# '{'  | return coord[1]  " Map/set
	elseif formtype ==# '"'  | return s:GetStringIndent(coord, 0)
	elseif formtype ==# '#"' | return s:GetStringIndent(coord, 1)
	else                     | return -1  " Keep existing indent.
	endif
endfunction

" TODO: lispoptions if exists.
setlocal indentexpr=s:GetClojureIndent()

let &cpoptions = s:save_cpo
unlet! s:save_cpo

" vim:sts=8:sw=8:ts=8:noet
