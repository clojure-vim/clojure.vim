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

if !exists('g:clojure_fuzzy_indent_patterns')
	let g:clojure_fuzzy_indent_patterns = [
	\   '^with-\%(meta\|in-str\|out-str\|loading-context\)\@!',
	\   '^def',
	\   '^let'
	\ ]
endif

if !exists('g:clojure_indent_rules')
	" Defaults copied from: https://github.com/clojure-emacs/clojure-mode/blob/0e62583b5198f71856e4d7b80e1099789d47f2ed/clojure-mode.el#L1800-L1875
	let g:clojure_indent_rules = {
	\   'ns': 1,
	\   'fn': 1, 'def': 1, 'defn': 1, 'bound-fn': 1,
	\   'if': 1, 'if-not': 1, 'if-some': 1, 'if-let': 1,
	\   'when': 1, 'when-not': 1, 'when-some': 1, 'when-let': 1, 'when-first': 1,
	\   'case': 1, 'cond': 0, 'cond->': 1, 'cond->>': 1, 'condp': 2,
	\   'while': 1, 'loop': 1, 'for': 1, 'doseq': 1, 'dotimes': 1,
	\   'do': 0, 'doto': 1, 'comment': 0, 'as->': 2,
	\   'delay': 0, 'future': 0, 'locking': 1,
	\   'fdef': 1,
	\   'extend': 1,
	\   'try': 0, 'catch': 2, 'finally': 0,
	\   'let': 1, 'binding': 1,
	\   'defmethod': 1,
	\   'this-as': 1,
	\   'deftest': 1, 'testing': 1, 'use-fixtures': 1, 'are': 2,
	\   'alt!': 0, 'alt!!': 0, 'go': 0, 'go-loop': 1, 'thread': 0,
	\   'run': 1, 'run*': 1, 'fresh': 1
	\ }

	" (letfn '(1 ((:defn)) nil))
	" (proxy '(2 nil nil (:defn)))
	" (reify '(:defn (1)))
	" (deftype '(2 nil nil (:defn)))
	" (defrecord '(2 nil nil (:defn)))
	" (defprotocol '(1 (:defn)))
	" (definterface '(1 (:defn)))
	" (extend-protocol '(1 :defn))
	" (extend-type '(1 :defn))
	" (specify '(1 :defn))  ; ClojureScript
	" (specify! '(1 :defn))  ; ClojureScript
	" (this-as 1) ; ClojureScript
	" clojure.test, core.async, core.logic
endif

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

" TODO: better comment and function name.
" Used to check if in the current form for list function indentation.
let s:in_form_current_form = [0, 0]
function! s:InForm()
	let pos = searchpairpos('[([{"]', '', '[)\]}"]', 'b')
	return pos != [0, 0] && pos != s:in_form_current_form
endfunction

function! s:PosToCharPos(pos)
	call cursor(a:pos)
	return getcursorcharpos()[1:2]
endfunction

" Repeatedly search for indentation significant Clojure tokens on a given line
" (in reverse order) building up a list of tokens and their positions.
" Ignores escaped tokens.  Does not care about strings, which is handled by
" "s:InsideForm".
function! s:TokeniseLine(line_num)
	let tokens = []
	let ln = getline(a:line_num)
	let possible_comment = 0

	while 1
		" We perform searches within the buffer (and move the cusor)
		" for better performance than looping char by char in a line.
		let token_pos = searchpos('[()[\]{};"]', 'bW', a:line_num)

		" No more matches, exit loop.
		if token_pos == [0, 0] | break | endif

		let t_idx = token_pos[1] - 1

		" Escaped character, ignore.
		if s:IsEscaped(ln, t_idx) | continue | endif

		" Add token to the list.
		let token = ln[t_idx]
		call add(tokens, [token, token_pos])

		" Early "possible comment" detection to reduce copying later.
		if token ==# ';' | let possible_comment = 1 | endif
	endwhile

	return [tokens, possible_comment]
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
		let [line_tokens, possible_comment] = s:TokeniseLine(lnum)

		" In case of comments, copy "tokens" so we can undo alterations.
		if possible_comment
			let prev_tokens = copy(tokens)
		endif

		" Reduce tokens from line "lnum" into "tokens".
		for tk in line_tokens
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
			elseif possible_comment && tk[0] ==# ';'
				" Comment: undo previous token applications on
				" this line.
				let tokens = copy(prev_tokens)
			elseif ! empty(tokens) && get(s:pairs, tk[0], '') ==# tokens[-1][0]
				" Matching pair: drop the last item in tokens.
				call remove(tokens, -1)
			else
				" No match: append to token list.
				call add(tokens, tk)
			endif
		endfor

		if ! empty(tokens) && has_key(s:pairs, tokens[0][0]) && ! in_string
			" Match found!
			return tokens[0]
		endif

		let lnum -= 1
	endwhile

	" TODO: can this conditional be simplified?
	if (in_string && first_string_pos != []) || (! empty(tokens) && tokens[0][0] ==# '"')
		" Must have been in a multi-line string or regular expression
		" as the string was never closed.
		return first_string_pos
	endif

	return ['^', [0, 0]]  " Default to top-level.
endfunction

" Returns "1" when the "=" operator is currently active.
function! s:EqualsOperatorInEffect()
	return exists('*state')
		\ ? v:operator ==# '=' && state('o') ==# 'o'
		\ : 0
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
		elseif alignment ==  1 | return s:PosToCharPos(a:delim_pos)[1]
		else
			let col = a:delim_pos[1]
			let is_regex = col > 1 && getline(a:delim_pos[0])[col - 2] ==# '#'
			return s:PosToCharPos(a:delim_pos)[1] - (is_regex ? 2 : 1)
		endif
	else
		return -1  " Keep existing indent.
	endif
endfunction

function! s:ListIndent(delim_pos)
	" TODO: extend "s:InsideForm" to provide information about the
	" subforms being formatted to avoid second parsing step.

	let base_indent = s:PosToCharPos(a:delim_pos)[1]
	let ln = getline(a:delim_pos[0])
	let delim_col = a:delim_pos[1]

	" 1. Macro/rule indentation
	"    if starts with a symbol, extract it.
	"      - Split namespace off symbol and #'/' syntax.
	"      - Check against pattern rules and apply indent on match.
	"      - Look up in rules table and apply indent on match.
	"    else, not found, go to 2.

	" TODO: handle complex indentation (e.g. letfn) and introduce
	" indentation config similar to Emacs' clojure-mode and cljfmt.
	" This new config option `clojure_indent_rules` should replace most
	" other indentation options.

	" TODO: simplify this.
	let syms = split(ln[delim_col:], '[[:space:],;()\[\]{}@\\"^~`]', 1)

	if !empty(syms)
		let sym = syms[0]
		" TODO: if prefixed with "#'" or "'" fallback to func indent.
		if sym =~# '\v^%([a-zA-Z!$&*_+=|<>?-]|[^\x00-\x7F])'

			" TODO: handle namespaced and non-namespaced variants.
			if sym =~# './.'
				let [_namespace, name] = split(sym, '/')
			endif

			" TODO: replace `clojure_fuzzy_indent_patterns` with `clojure_indent_patterns`
			for pat in s:Conf('clojure_fuzzy_indent_patterns', [])
				if sym =~# pat
					return base_indent + 1
				endif
			endfor

			let rules = s:Conf('clojure_indent_rules', {})
			let sym_match = get(rules, sym, -1)
			" TODO: handle 2+ differently?
			if sym_match >= 0 | return base_indent + 1 | endif
		endif
	endif

	" 2. Function indentation
	"    if first operand is on the same line?  (Treat metadata as args.)
	"      - Indent subsequent lines to align with first operand.
	"    else
	"      - Indent 1 or 2 spaces.

	let indent_style = s:Conf('clojure_indent_style', 'always-align')
	if indent_style !=# 'always-indent'
		let lnr = a:delim_pos[0]
		call cursor(lnr, delim_col + 1)

		" TODO: ignore comments.
		" TODO: handle escaped characters!
		let s:in_form_current_form = a:delim_pos
		let ln_s = searchpos('[ ,]\+\zs', 'z', lnr, 0, function('<SID>InForm'))

		if ln_s != [0, 0] | return s:PosToCharPos(ln_s)[1] - 1 | endif
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
	elseif form ==# '[' | return s:PosToCharPos(pos)[1]
	elseif form ==# '{' | return s:PosToCharPos(pos)[1]
	elseif form ==# '"' | return s:StringIndent(pos)
	else                | return -1  " Keep existing indent.
	endif
endfunction

" TODO: setl lisp lispoptions=expr:1 if exists.  "has('patch-9.0.0761')"
setlocal indentexpr=s:ClojureIndent()

let &cpoptions = s:save_cpo
unlet! s:save_cpo

" vim:sts=8:sw=8:ts=8:noet
