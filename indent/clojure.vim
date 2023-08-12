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

" NOTE: To debug this code, make sure to "set debug+=msg" otherwise errors
" will occur silently.

" Get the value of a configuration option.
function! s:Conf(opt, default)
	return get(b:, a:opt, get(g:, a:opt, a:default))
endfunction

" Returns "1" if position "i_char" in "line_str" is preceded by an odd number
" of backslash characters (i.e. escaped).
function! s:IsEscaped(line_str, i_char)
	let ln = a:line_str[: a:i_char - 1]
	return (strlen(ln) - strlen(trim(ln, '\', 2))) % 2
endfunction

" Repeatedly search for indentation significant Clojure tokens on a given line
" (in reverse order) building up a list of tokens and their positions.
" Ignores escaped tokens.  Does not care about strings, which is handled by
" "s:InsideForm".
function! s:TokeniseLine(line_num)
	let tokens = []
	let ln = getline(a:line_num)

	while 1
		" We perform searches within the buffer (and move the cusor)
		" for better performance than looping char by char in a line.
		let token = searchpos('[()[\]{};"]', 'bW', a:line_num)

		" No more matches, exit loop.
		if token == [0, 0] | break | endif

		let t_idx = token[1] - 1

		" Escaped character, ignore.
		if s:IsEscaped(ln, t_idx) | continue | endif

		let t_char = ln[t_idx]
		if t_char ==# ';'
			" Comment found, reset the token list for this line.
			let tokens = []
		elseif t_char =~# '[()\[\]{}"]'
			" Add token to the list.
			call add(tokens, [t_char, token])
		endif
	endwhile

	return tokens
endfunction

let s:pairs = {'(': ')', '[': ']', '{': '}'}

" This procedure is kind of like a really lightweight Clojure reader that
" analyses from the inside out.  It looks at the lines above the current line,
" tokenises them (from right to left), and performs reductions to find the
" parent form and where it is.
function! s:InsideForm(lnum)
	" Reset cursor to first column of the line we wish to indent.
	call cursor(a:lnum, 1)

	" Token list looks like this: "[[delim, [line, col]], ...]".
	let tokens = []
	let first_string_pos = []
	let in_string = 0

	let lnum = a:lnum - 1
	while lnum > 0
		" Reduce tokens from line "lnum" into "tokens".
		for tk in s:TokeniseLine(lnum)
			if tk[0] ==# '"'
				if in_string
					let in_string = 0
					call remove(tokens, -1)
				else
					let in_string = 1
					call add(tokens, tk)

					" Track the first string delimiter we
					" see, as we may need it later for
					" multi-line strings/regexps.
					if first_string_pos == []
						let first_string_pos = tk
					endif
				endif
			elseif in_string
				" In string: ignore other tokens.
			elseif ! empty(tokens) && get(s:pairs, tk[0], '') ==# tokens[-1][0]
				" Matching pair: drop the last item in tokens.
				call remove(tokens, -1)
			else
				" No match: append to token list.
				call add(tokens, tk)
			endif
		endfor

		if ! empty(tokens) && has_key(s:pairs, tokens[0][0])
			" Match found!
			return tokens[0]
		endif

		let lnum -= 1
	endwhile

	if ! empty(tokens) && tokens[0][0] ==# '"'
		" Must have been in a multi-line string or regular expression
		" as the string was never closed.
		return first_string_pos
	endif

	return ['^', [0, 0]]  " Default to top-level.
endfunction

" Returns "1" when the "=" operator is currently active.
function! s:EqualsOperatorInEffect()
	if has('nvim')
		" Neovim has no `state()` function so fallback to indenting
		" strings.
		return 0
	else
		return v:operator ==# '=' && state('o') ==# 'o'
	endif
endfunction

function! s:StringIndent(delim_pos)
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
		else
			let col = a:delim_pos[1]
			let is_regex = col > 1 && getline(a:delim_pos[0])[col - 2] ==# '#'
			return col - (is_regex ? 2 : 1)
		endif
	else
		return -1  " Keep existing indent.
	endif
endfunction

function! s:ListIndent(delim_pos)
	" TODO: attempt to extend "s:InsideForm" to provide information about
	" the subforms being formatted to avoid second parsing step.

	call cursor(a:delim_pos)
	let ln = getline(a:delim_pos[0])
	let base_indent = a:delim_pos[1]

	" 1. TODO: Macro/rule indentation
	"    if starts with a symbol or keyword: extract it.
	"      - Look up in rules table.
	"        - See number for forms forward to lookup.
	"        - Start parsing forwards "x" forms.  (Skip metadata)
	"        - Apply indentation.
	"    else, not found, go to 2.
	" TODO: complex indentation (e.g. letfn)
	" TODO: namespaces.
	" let syms = split(ln[base_indent:], '[[:space:],;()\[\]{}@\\"^~`]', 1)

	" 2. Function indentation
	"    if first operand is on the same line?  (Treat metadata as args.)
	"      - Indent subsequent lines to align with first operand.
	"    else
	"      - Indent 1 or 2 spaces.
	let indent_style = s:Conf('clojure_indent_style', 'always-align')
	if indent_style !=# 'always-indent'
		let init_col = a:delim_pos[1] + 1
		call cursor(a:delim_pos[0], init_col)

		" TODO: replace cursor translation with searching?
		let ch = ln[base_indent]
		if ch ==# '(' || ch ==# '[' || ch ==# '{'
			normal! %w
		elseif ch !=# ';' && ch !=# '"'
			normal! w
		endif

		let cur_pos = getcursorcharpos()[1:2]
		if a:delim_pos[0] == cur_pos[0] && init_col != cur_pos[1]
			" Align operands.
			return cur_pos[1] - 1
		endif
	endif

	" Fallback indentation for operands.  When "clojure_indent_style" is
	" "always-align", use 1 space indentation, else 2 space indentation.
	return base_indent + (indent_style !=# 'always-align')
endfunction

function! s:ClojureIndent()
	" Calculate and return indent to use based on the matching form.
	let [form, pos] = s:InsideForm(v:lnum)
	if     form ==# '^' | return 0  " At top-level, no indent.
	elseif form ==# '(' | return s:ListIndent(pos)
	elseif form ==# '[' | return pos[1]
	elseif form ==# '{' | return pos[1]
	elseif form ==# '"' | return s:StringIndent(pos)
	else                | return -1  " Keep existing indent.
	endif
endfunction

" TODO: setl lisp lispoptions=expr:1 if exists.  "has('patch-9.0.0761')"
setlocal indentexpr=s:ClojureIndent()

let &cpoptions = s:save_cpo
unlet! s:save_cpo

" vim:sts=8:sw=8:ts=8:noet
