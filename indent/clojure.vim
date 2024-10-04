" Vim indent file
" Language:            Clojure
" Maintainer:          Alex Vear <alex@vear.uk>
" Former Maintainers:  Sung Pae <self@sungpae.com>
"                      Meikel Brandmeyer <mb@kotka.de>
" Last Change:         %%RELEASE_DATE%%
" License:             Vim (see :h license)
" Repository:          https://github.com/clojure-vim/clojure.vim

" NOTE: To debug this code, make sure to "set debug+=msg" otherwise errors
" will occur silently.

if exists("b:did_indent") | finish | endif
let b:did_indent = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

let b:undo_indent = 'setlocal autoindent< smartindent< expandtab< softtabstop< shiftwidth< indentexpr< indentkeys< lisp<'

setlocal noautoindent nosmartindent nolisp
setlocal softtabstop=2 shiftwidth=2 expandtab
setlocal indentkeys=!,o,O

" Set a new configuration option with a default value.  Assigns a script-local
" version too, which is the default fallback in case the global was "unlet".
function! s:SConf(name, default) abort
	exec 'let' 's:' . a:name '=' string(a:default)
	let n = 'g:' . a:name
	if ! exists(n) | exec 'let' n '=' string(a:default) | endif
endfunction

" Get the value of a configuration option with a possible fallback.  If no
" fallback is given, uses the original config option value.
function! s:Conf(opt, fallback = v:null) abort
	return a:fallback ==# v:null
		\ ? get(b:, a:opt, get(g:, a:opt, get(s:, a:opt)))
		\ : get(b:, a:opt, get(g:, a:opt, a:fallback))
endfunction

" Available options:
"   - standard    (Emacs equiv: always-align)
"   - traditional (Emacs equiv: align-arguments)
"   - uniform     (Emacs equiv: always-indent)
call s:SConf('clojure_indent_style', 'standard')

call s:SConf('clojure_align_multiline_strings', 0)

call s:SConf('clojure_fuzzy_indent_patterns', [
\   '^with-\%(meta\|in-str\|out-str\|loading-context\)\@!',
\   '^def',
\   '^let'
\ ])

" Defaults copied from: https://github.com/clojure-emacs/clojure-mode/blob/0e62583b5198f71856e4d7b80e1099789d47f2ed/clojure-mode.el#L1800-L1875
if !exists('g:clojure_indent_rules')
	let g:clojure_indent_rules = {
	\   'ns': 1,
	\   'fn': 1, 'def': 1, 'defn': 1, 'bound-fn': 1, 'fdef': 1,
	\   'let': 1, 'binding': 1, 'defmethod': 1,
	\   'if': 1, 'if-not': 1, 'if-some': 1, 'if-let': 1,
	\   'when': 1, 'when-not': 1, 'when-some': 1, 'when-let': 1, 'when-first': 1,
	\   'case': 1, 'cond': 0, 'cond->': 1, 'cond->>': 1, 'condp': 2,
	\   'while': 1, 'loop': 1, 'for': 1, 'doseq': 1, 'dotimes': 1,
	\   'do': 0, 'doto': 1, 'comment': 0, 'as->': 2,
	\   'delay': 0, 'future': 0, 'locking': 1,
	\   'try': 0, 'catch': 2, 'finally': 0,
        \   'reify': 1, 'proxy': 2, 'defrecord': 2, 'defprotocol': 1, 'definterface': 1,
	\   'extend': 1, 'extend-protocol': 1, 'extend-type': 1
	\ }
	" (letfn) (1 ((:defn)) nil)
	" (reify) (:defn (1))
	" (deftype defrecord proxy) (2 nil nil (:defn))
	" (defprotocol definterface extend-protocol extend-type) (1 (:defn))

	" ClojureScript
	call extend(g:clojure_indent_rules, {
	\   'this-as': 1, 'specify': 1, 'specify!': 1
	\ })
	" (specify specify!) (1 :defn)

	" clojure.test
	call extend(g:clojure_indent_rules, {
	\   'deftest': 1, 'testing': 1, 'use-fixtures': 1, 'are': 2
	\ })

	" core.async
	call extend(g:clojure_indent_rules, {
	\   'alt!': 0, 'alt!!': 0, 'go': 0, 'go-loop': 1, 'thread': 0
	\ })

	" core.logic
	call extend(g:clojure_indent_rules, {
	\   'run': 1, 'run*': 1, 'fresh': 1
	\ })
endif

" Returns "1" if position "i_char" in "line_str" is preceded by an odd number
" of backslash characters (i.e. escaped).
function! s:IsEscaped(line_str, i_char)
	let ln = a:line_str[: a:i_char - 1]
	return ! strlen(trim(ln, '\', 2)) % 2
endfunction

" Used during list function indentation.  Returns the position of the first
" operand in the list on the first line of the form at "pos".
function! s:FirstFnArgPos(pos)
	" TODO: ignore comments.
	" TODO: handle escaped characters!
	let lnr = a:pos[0]
	let s:in_form_current_form = a:pos
	call cursor(lnr, a:pos[1] + 1)
	return searchpos('[ ,]\+\zs', 'z', lnr, 0, function('<SID>IsSubForm'))
endfunction

" Used by "s:FirstFnArgPos" function to skip over subforms as the first value
" in a list form.
function! s:IsSubForm()
	let pos = searchpairpos('[([{"]', '', '[)\]}"]', 'b')
	return pos != [0, 0] && pos != s:in_form_current_form
endfunction

" Converts a cursor position into a characterwise cursor column position (to
" handle multibyte characters).
function! s:PosToCharCol(pos)
	call cursor(a:pos)
	return getcursorcharpos()[2]
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
		let alignment = s:Conf('clojure_align_multiline_strings')
		" -1: Indent along left edge, like traditional Lisps.
		"  0: Indent in alignment with end of the string start delimiter.
		"  1: Indent in alignment with string start delimiter.
		if     alignment == -1 | return 0
		elseif alignment ==  1 | return s:PosToCharCol(a:delim_pos)
		else
			let col = a:delim_pos[1]
			let is_regex = col > 1 && getline(a:delim_pos[0])[col - 2] ==# '#'
			return s:PosToCharCol(a:delim_pos) - (is_regex ? 2 : 1)
		endif
	else
		return -1  " Keep existing indent.
	endif
endfunction

function! s:ListIndent(delim_pos)
	" TODO: extend "s:InsideForm" to provide information about the
	" subforms being formatted to avoid second parsing step.

	let base_indent = s:PosToCharCol(a:delim_pos)
	let ln = getline(a:delim_pos[0])
	let ln_content = ln[a:delim_pos[1]:]

	let sym_match = -1

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
	let syms = split(ln_content, '[[:space:],;()\[\]{}@\\"^~`]', 1)

	if !empty(syms)
		let sym = syms[0]
		if sym =~# '\v^%([a-zA-Z!$&*_+=|<>?-]|[^\x00-\x7F])'

			" TODO: handle namespaced and non-namespaced variants.
			if sym =~# './.'
				let [_namespace, name] = split(sym, '/')
			endif

			" TODO: replace `clojure_fuzzy_indent_patterns` with `clojure_indent_patterns`
			for pat in s:Conf('clojure_fuzzy_indent_patterns', [])
				if sym =~# pat | return base_indent + 1 | endif
			endfor

			let rules = s:Conf('clojure_indent_rules', {})
			let sym_match = get(rules, sym, -1)
			" TODO: handle 2+ differently?
			if sym_match > 0 | return base_indent + 1 | endif
		endif
	endif

	" 2. Function indentation
	"    if first operand is on the same line? (and not a keyword)
	"      - Indent subsequent lines to align with first operand.
	"    else
	"      - Indent 1 or 2 spaces.
	let indent_style = s:Conf('clojure_indent_style')
	if indent_style !=# 'uniform' && ln_content[0] !=# ':'
		let pos = s:FirstFnArgPos(a:delim_pos)
		if pos != [0, 0] | return s:PosToCharCol(pos) - 1 | endif
	endif

	" Fallback indentation for operands.  When "clojure_indent_style" is
	" "standard", use 1 space indentation, else 2 space indentation.
	" The "sym_match" check handles the case when "clojure_indent_rules"
	" specified a value of "0".
	return base_indent + (indent_style !=# 'standard' || sym_match == 0)
endfunction

function! s:ClojureIndent()
	" Calculate and return indent to use based on the matching form.
	let [form, pos] = s:InsideForm(v:lnum)
	if     form ==# '^' | return 0  " At top-level, no indent.
	elseif form ==# '(' | return s:ListIndent(pos)
	elseif form ==# '[' | return s:PosToCharCol(pos)
	elseif form ==# '{' | return s:PosToCharCol(pos)
	elseif form ==# '"' | return s:StringIndent(pos)
	else                | return -1  " Keep existing indent.
	endif
endfunction

" Connect indentation function.
if exists('&lispoptions')
	setlocal lisp lispoptions=expr:1
	let b:undo_indent .= ' lispoptions<'
endif
setlocal indentexpr=s:ClojureIndent()

let &cpoptions = s:save_cpo
unlet! s:save_cpo

" vim:sts=8:sw=8:ts=8:noet
