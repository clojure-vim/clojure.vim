;; Authors: Sung Pae <self@sungpae.com>
;;          Joel Holdbrooks <cjholdbrooks@gmail.com>

(ns vim.syntax-test
  (:require [vim.test :refer [defpredicates defsyntaxtest def-eq-predicates]]))

;; defpredicates also register not-equal vars, this is just for clj-kondo
(declare !number !regexp-escape !regexp-posix-char-class !regexp-quantifier)

(defpredicates number :clojureNumber)
(def-eq-predicates kw [:clojureKeywordNsColon :clojureKeyword])
(def-eq-predicates kwCurrentNs [:clojureKeywordNsColon :clojureKeywordNsColon :clojureKeyword])
(def-eq-predicates kwWithNs [:clojureKeywordNsColon :clojureKeywordNs :clojureKeywordNsSeparator :clojureKeyword])
(def-eq-predicates kwWithNs3_4 [:clojureKeywordNsColon
                                :clojureKeywordNs
                                :clojureKeywordNs
                                :clojureKeywordNs
                                :clojureKeywordNsSeparator
                                :clojureKeyword
                                :clojureKeyword
                                :clojureKeyword
                                :clojureKeyword])
(def-eq-predicates sym [:clojureSymbol])
(def-eq-predicates symWithNs [:clojureSymbol])
(def-eq-predicates symWithNs_tripleBody [:clojureKeywordNsColon
                                         :clojureKeywordNs :clojureKeywordNsSeparator
                                         :clojureKeywordNs :clojureKeywordNsSeparator
                                         :clojureKeywordNs :clojureKeywordNsSeparator
                                         :clojureKeyword])
(def-eq-predicates kwWithNamedNs [:clojureKeywordNsColon :clojureKeywordNsColon
                                  :clojureKeywordNs :clojureKeywordNsSeparator :clojureKeyword])
(def-eq-predicates dispatchWithSymbolInside [:clojureDispatch
                                             :clojureSymbol
                                             :clojureSymbol
                                             :clojureSymbol
                                             :clojureSymbol
                                             :clojureSymbol
                                             :clojureSymbol
                                             :clojureSymbol
                                             :clojureSymbol
                                             :clojureParen
                                             :clojureSymbolNs
                                             :clojureSymbolNs
                                             :clojureSymbolNs
                                             :clojureSymbolNs
                                             :clojureSymbolNsSeparator
                                             :clojureSymbol
                                             :clojureSymbol
                                             :clojureSymbol
                                             :clojureSymbol
                                             :clojureSymbol
                                             :clojureParen])
(defpredicates character :clojureCharacter)
(defpredicates regexp :clojureRegexp)
(defpredicates regexp-delimiter :clojureRegexpDelimiter)
(defpredicates regexp-escape :clojureRegexpEscape)
(defpredicates regexp-char-class :clojureRegexpCharClass)
(defpredicates regexp-predefined-char-class :clojureRegexpPredefinedCharClass)
(defpredicates regexp-posix-char-class :clojureRegexpPosixCharClass)
(defpredicates regexp-java-char-class :clojureRegexpJavaCharClass)
(defpredicates regexp-unicode-char-class :clojureRegexpUnicodeCharClass)
(defpredicates regexp-boundary :clojureRegexpBoundary)
(defpredicates regexp-quantifier :clojureRegexpQuantifier)
(defpredicates regexp-back-ref :clojureRegexpBackRef)
(defpredicates regexp-or :clojureRegexpOr)
(defpredicates regexp-group :clojureRegexpGroup)
(defn regexp-mod [xs] (= (second xs) :clojureRegexpMod))
(def !regexp-mod (complement regexp-mod))

(defsyntaxtest test-number-literals
  ["%s"
   ["1234567890" number "+1"    number "-1"    number ; Integer
    "0"          number "+0"    number "-0"    number ; Integer zero
    "0.12"       number "+0.12" number "-0.12" number ; Float
    "1."         number "+1."   number "-1."   number ; Float
    "0.0"        number "+0.0"  number "-0.0"  number ; Float zero
    "01234567"   number "+07"   number "-07"   number ; Octal
    "00"         number "+00"   number "-00"   number ; Octal zero
    "0x09abcdef" number "+0xf"  number "-0xf"  number ; Hexadecimal
    "0x0"        number "+0x0"  number "-0x0"  number ; Hexadecimal zero
    "3/2"        number "+3/2"  number "-3/2"  number ; Rational
    "0/0"        number "+0/0"  number "-0/0"  number ; Rational (not a syntax error)
    "36r0XYZ"    number "16rFF" number "8r077" number ; Radix
    "2r1"        number "+2r1"  number "-2r1"  number ; Radix
    "36R1"       number "+36R1" number "-36R1" number ; Radix

    ;; Illegal literals (some are accepted by the reader, but are bad style)

    ".1" !number
    "01.2" !number
    "089" !number
    "0xfg" !number
    "1.0/1" !number
    "01/2" !number
    "1/02" !number
    ; "2r2" !number ;; Removed for performance
    "1r0" !number
    "37r36" !number

    ;; BigInt

    "0N" number
    "+0.1N" !number
    "-07N" number
    "08N" !number
    "+0x0fN" number
    "1/2N" !number

    ;; BigDecimal

    "0M" number
    "+0.1M" number
    "08M" !number
    "08.9M" !number
    "0x1fM" !number
    "3/4M" !number
    ; "2r1M" !number ;; Removed for performance

    ;; Exponential notation

    "0e0" number
    "+0.1e-1" number
    "-1e-1" number
    "08e1" !number
    "07e1" !number
    "0xfe-1" !number
    "2r1e-1" !number]])

(comment (test #'test-number-literals))

(defsyntaxtest test-character-literals
  ["[%s]"
   ["\\0"  character  "\\a"    character  "\\Z"     character
    "\\."  character  "\\\\"   character  "\\❤"     character
    "\\o7" character  "\\o07"  character  "\\o307"  character
    "\\o8" !character "\\o477" !character "\\o0007" !character

    "\\u09af" character

    "\\u0"     !character "\\u01"    !character "\\u012" !character
    "\\u01234" !character "\\u0123g" !character

    "\\newline"   character "\\new" !character
    "\\tab"       character "\\ta"  !character
    "\\space"     character "\\sp"  !character
    "\\return"    character "\\ret" !character
    "\\backspace" character "\\bs"  !character
    "\\formfeed"  character "\\ff"  !character]])

(comment (test #'test-character-literals))

(def emptyKeyword (keyword ""))

(defsyntaxtest keywords-test
  ["%s"
   [":1" kw
    ":A" kw
    ":a" kw
    ":αβγ" (partial = [:clojureKeywordNsColon :clojureKeyword :clojureKeyword :clojureKeyword])
    "::a" kwCurrentNs
    ":a/b" kwWithNs
    ":a:b/:c:b" kwWithNs3_4
    ":a/b/c/d" symWithNs_tripleBody
    "::a/b" kwWithNamedNs
    "::" (partial = [emptyKeyword emptyKeyword])
    ":a:" (partial = [emptyKeyword :clojureSymbol emptyKeyword])
    ":a/" (partial = [:clojureKeywordNsColon :clojureKeywordNs :clojureKeywordNsSeparator])
    ":/" (partial =  [:clojureKeywordNsColon :clojureKeywordNsSeparator])
    ":" (partial = [emptyKeyword])
    "a[:b/c]" (partial = [:clojureSymbol
                          :clojureParen
                          :clojureKeywordNsColon
                          :clojureKeywordNs
                          :clojureKeywordNsSeparator
                          :clojureKeyword
                          :clojureParen])
    ":a[:b/c]" (partial = [:clojureKeywordNsColon
                           :clojureKeyword
                           :clojureParen
                           :clojureKeywordNsColon
                           :clojureKeywordNs
                           :clojureKeywordNsSeparator
                           :clojureKeyword
                           :clojureParen])]])

(defsyntaxtest symbols-test
  ["%s"
   ["1" !sym
    "1" !symWithNs
    "A" sym
    "a" sym
    "αβγ" (partial = [:clojureSymbol :clojureSymbol :clojureSymbol])
    "a/b" (partial = [:clojureSymbolNs :clojureSymbolNsSeparator :clojureSymbol])
    "a:b" (partial = [:clojureSymbol :clojureSymbol :clojureSymbol])
    "a:b/:c:b" (partial = [:clojureSymbolNs
                           :clojureSymbolNs
                           :clojureSymbolNs
                           :clojureSymbolNsSeparator
                           :clojureSymbol
                           :clojureSymbol
                           :clojureSymbol
                           :clojureSymbol])
    "a/b/c/d" (partial = [:clojureSymbolNs :clojureSymbolNsSeparator
                          :clojureSymbolNs :clojureSymbolNsSeparator
                          :clojureSymbolNs :clojureSymbolNsSeparator
                          :clojureSymbol])
    "a:" !sym
    "a:" !symWithNs
    "a/" !sym
    "a/" !symWithNs
    "/" !sym
    "#function[test/hello]" dispatchWithSymbolInside
    "a[b/c]" (partial = [:clojureSymbol
                         :clojureParen
                         :clojureSymbolNs
                         :clojureSymbolNsSeparator
                         :clojureSymbol
                         :clojureParen])
    "#'a/b" (partial = [:clojureDispatch
                        :clojureDispatch
                        :clojureSymbolNs
                        :clojureSymbolNsSeparator
                        :clojureSymbol])]])

(comment (test #'keywords-test))

(defsyntaxtest test-java-regexp-literals
  ["#\"%s\""
   [;; http://docs.oracle.com/javase/7/docs/api/java/util/regex/Pattern.html
    ;;
    ;; Characters
    ;; x          The character x
    " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" regexp
    "λ❤" regexp
    ;; \\         The backslash character
    "\\\\" regexp-escape
    ;; \0n        The character with octal value 0n (0 <= n <= 7)
    "\\07" regexp-escape
    "\\08" !regexp-escape
    ;; \0nn       The character with octal value 0nn (0 <= n <= 7)
    "\\077" regexp-escape
    "\\078" !regexp-escape
    ;; \0mnn      The character with octal value 0mnn (0 <= m <= 3, 0 <= n <= 7)
    "\\0377" regexp-escape
    "\\0378" !regexp-escape
    "\\0400" !regexp-escape
    ;; \xhh       The character with hexadecimal value 0xhh
    "\\xff" regexp-escape
    "\\xfg" !regexp-escape
    "\\xfff" !regexp-escape
    ;; \uhhhh     The character with hexadecimal value 0xhhhh
    "\\uffff" regexp-escape
    "\\ufff" !regexp-escape
    "\\ufffff" !regexp-escape
    ;; \x{h...h}  The character with hexadecimal value 0xh...h (Character.MIN_CODE_POINT  <= 0xh...h <=  Character.MAX_CODE_POINT)
    ;; \t         The tab character ('\u0009')
    "\\t" regexp-escape
    "\\T" !regexp-escape
    ;; \n         The newline (line feed) character ('\u000A')
    "\\n" regexp-escape
    "\\N" !regexp-escape
    ;; \r         The carriage-return character ('\u000D')
    "\\r" regexp-escape
    "\\R" !regexp-escape
    ;; \f         The form-feed character ('\u000C')
    "\\f" regexp-escape
    "\\F" !regexp-escape
    ;; \a         The alert (bell) character ('\u0007')
    "\\a" regexp-escape
    "\\A" !regexp-escape
    ;; \e         The escape character ('\u001B')
    "\\e" regexp-escape
    "\\E" !regexp-escape
    ;; \cx        The control character corresponding to x
    "\\cA" regexp-escape
    "\\c1" !regexp-escape
    "\\c" !regexp-escape
    ;; Special character escapes
    "\\(\\)\\[\\]\\{\\}\\^\\$\\*\\?\\+\\." regexp-escape

    ;;;; Character classes

    ;; [abc]            a, b, or c (simple class)
    "[abc]" regexp-char-class
    ;; [^abc]           Any character except a, b, or c (negation)
    "[^abc]" regexp-char-class
    ;; [a-zA-Z]         a through z or A through Z, inclusive (range)
    ;; [a-d[m-p]]       a through d, or m through p: [a-dm-p] (union)
    ;; [a-z&&[def]]     d, e, or f (intersection)
    ;; [a-z&&[^bc]]     a through z, except for b and c: [ad-z] (subtraction)
    ;; [a-z&&[^m-p]]    a through z, and not m through p: [a-lq-z](subtraction)

    ;;;; Predefined character classes

    ;; .        Any character (may or may not match line terminators)
    "." regexp-predefined-char-class
    ;; \d       A digit: [0-9]
    "\\d" regexp-predefined-char-class
    ;; \D       A non-digit: [^0-9]
    "\\D" regexp-predefined-char-class
    ;; \s       A whitespace character: [ \t\n\x0B\f\r]
    "\\s" regexp-predefined-char-class
    ;; \S       A non-whitespace character: [^\s]
    "\\S" regexp-predefined-char-class
    ;; \w       A word character: [a-zA-Z_0-9]
    "\\w" regexp-predefined-char-class
    ;; \W       A non-word character: [^\w]
    "\\W" regexp-predefined-char-class

    ;;;; POSIX character classes (US-ASCII only)

    ;; \p{Lower}        A lower-case alphabetic character: [a-z]
    "\\p{Lower}" regexp-posix-char-class
    ;; \p{Upper}        An upper-case alphabetic character:[A-Z]
    "\\p{Upper}" regexp-posix-char-class
    ;; \p{ASCII}        All ASCII:[\x00-\x7F]
    "\\p{ASCII}" regexp-posix-char-class
    ;; \p{Alpha}        An alphabetic character:[\p{Lower}\p{Upper}]
    "\\p{Alpha}" regexp-posix-char-class
    ;; \p{Digit}        A decimal digit: [0-9]
    "\\p{Digit}" regexp-posix-char-class
    ;; \p{Alnum}        An alphanumeric character:[\p{Alpha}\p{Digit}]
    "\\p{Alnum}" regexp-posix-char-class
    ;; \p{Punct}        Punctuation: One of !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~
    "\\p{Punct}" regexp-posix-char-class
    ;; \p{Graph}        A visible character: [\p{Alnum}\p{Punct}]
    "\\p{Graph}" regexp-posix-char-class
    ;; \p{Print}        A printable character: [\p{Graph}\x20]
    "\\p{Print}" regexp-posix-char-class
    ;; \p{Blank}        A space or a tab: [ \t]
    "\\p{Blank}" regexp-posix-char-class
    ;; \p{Cntrl}        A control character: [\x00-\x1F\x7F]
    "\\p{Cntrl}" regexp-posix-char-class
    ;; \p{XDigit}       A hexadecimal digit: [0-9a-fA-F]
    "\\p{XDigit}" regexp-posix-char-class
    ;; \p{Space}        A whitespace character: [ \t\n\x0B\f\r]
    "\\p{Space}" regexp-posix-char-class

    ;;;; java.lang.Character classes (simple java character type)

    ;; \p{javaLowerCase}        Equivalent to java.lang.Character.isLowerCase()
    "\\p{javaLowerCase}" regexp-java-char-class
    ;; \p{javaUpperCase}        Equivalent to java.lang.Character.isUpperCase()
    "\\p{javaUpperCase}" regexp-java-char-class
    ;; \p{javaWhitespace}       Equivalent to java.lang.Character.isWhitespace()
    "\\p{javaWhitespace}" regexp-java-char-class
    ;; \p{javaMirrored}         Equivalent to java.lang.Character.isMirrored()
    "\\p{javaMirrored}" regexp-java-char-class

    ;;;; Classes for Unicode scripts, blocks, categories and binary properties

    ;; \p{IsLatin}        A Latin script character (script)
    "\\p{IsLatin}" regexp-unicode-char-class
    ;; \p{InGreek}        A character in the Greek block (block)
    "\\p{InGreek}" regexp-unicode-char-class
    ;; \p{IsAlphabetic}   An alphabetic character (binary property)
    "\\p{IsAlphabetic}" regexp-unicode-char-class
    ;; \p{Sc}             A currency symbol
    "\\p{Sc}" regexp-unicode-char-class
    ;; \P{InGreek}        Any character except one in the Greek block (negation)
    "\\P{InGreek}" regexp-unicode-char-class
    ;; [\p{L}&&[^\p{Lu}]] Any letter except an uppercase letter (subtraction)

    ;; Abbreviated categories
    "\\pL" regexp-unicode-char-class
    "\\p{L}" regexp-unicode-char-class
    "\\p{Lu}" regexp-unicode-char-class
    "\\p{gc=L}" regexp-unicode-char-class
    "\\p{IsLu}" regexp-unicode-char-class

    ;;;; Invalid classes

    "\\P{Xzibit}" !regexp-posix-char-class
    "\\p{YoDawg}" !regexp-posix-char-class

    ;;;; Boundary matchers

    ;; ^        The beginning of a line
    "^" regexp-boundary
    ;; $        The end of a line
    "$" regexp-boundary
    ;; \b       A word boundary
    "\\b" regexp-boundary
    ;; \B       A non-word boundary
    "\\B" regexp-boundary
    ;; \A       The beginning of the input
    "\\A" regexp-boundary
    ;; \G       The end of the previous match
    "\\G" regexp-boundary
    ;; \Z       The end of the input but for the final terminator, if any
    "\\Z" regexp-boundary
    ;; \z       The end of the input
    "\\z" regexp-boundary

    ;;;; Greedy quantifiers

    ;; X?       X, once or not at all
    "?" regexp-quantifier
    ;; X*       X, zero or more times
    "*" regexp-quantifier
    ;; X+       X, one or more times
    "+" regexp-quantifier
    ;; X{n}     X, exactly n times
    "{0}" regexp-quantifier
    ;; X{n,}    X, at least n times
    "{0,}" regexp-quantifier
    ;; X{n,m}   X, at least n but not more than m times
    "{0,1}" regexp-quantifier

    ;;;; Reluctant quantifiers

    ;; X??      X, once or not at all
    "??" regexp-quantifier
    ;; X*?      X, zero or more times
    "*?" regexp-quantifier
    ;; X+?      X, one or more times
    "+?" regexp-quantifier
    ;; X{n}?    X, exactly n times
    "{0}?" regexp-quantifier
    ;; X{n,}?   X, at least n times
    "{0,}?" regexp-quantifier
    ;; X{n,m}?  X, at least n but not more than m times
    "{0,1}?" regexp-quantifier

    ;;;; Possessive quantifiers

    ;; X?+      X, once or not at all
    "?+" regexp-quantifier
    ;; X*+      X, zero or more times
    "*+" regexp-quantifier
    ;; X++      X, one or more times
    "++" regexp-quantifier
    ;; X{n}+    X, exactly n times
    "{0}+" regexp-quantifier
    ;; X{n,}+   X, at least n times
    "{0,}+" regexp-quantifier
    ;; X{n,m}+  X, at least n but not more than m times
    "{0,1}+" regexp-quantifier

    "{-1}"      !regexp-quantifier
    "{-1,}"     !regexp-quantifier
    "{-1,-2}"   !regexp-quantifier
    "{-1}?"     !regexp-quantifier
    "{-1,}?"    !regexp-quantifier
    "{-1,-2}?"  !regexp-quantifier
    "{-1}?"     !regexp-quantifier
    "{-1,}?"    !regexp-quantifier
    "{-1,-2}?"  !regexp-quantifier

    ;;;; Logical operators
    ;; XY       X followed by Y
    ;; XXX: Tested above (regexp)

    ;; X|Y      Either X or Y
    "|" regexp-or

    ;; (X)      X, as a capturing group
    "(X)" regexp-group

    ;;;; Back references

    ;; \n       Whatever the nth capturing group matched
    "\\1" regexp-back-ref
    ;; \k<name> Whatever the named-capturing group "name" matched
    "\\k<name>" regexp-back-ref

    ;;;; Quotation

    ;; \        Nothing, but quotes the following character
    ;; XXX: Tested above

    ;; \Q       Nothing, but quotes all characters until \E
    ;; \E       Nothing, but ends quoting started by \Q
    "\\Qa\\E"  (partial = [:clojureRegexpQuote :clojureRegexpQuote :clojureRegexpQuoted :clojureRegexpQuote :clojureRegexpQuote])
    "\\Qa\\\"" (partial = [:clojureRegexpQuote :clojureRegexpQuote :clojureRegexpQuoted :clojureRegexpQuoted :clojureRegexpQuoted])
    "\\qa\\E"  (partial not-any? #{:clojureRegexpQuote :clojureRegexpQuoted})

    ;;;; Special constructs (named-capturing and non-capturing)
    ;; (?<name>X)         X, as a named-capturing group
    "(?<name>X)" regexp-mod
    ;; (?:X)              X, as a non-capturing group
    "(?:X)" regexp-mod
    ;; (?idmsuxU-idmsuxU) Nothing, but turns match flags i d m s u x U on - off
    "(?idmsuxU-idmsuxU)" regexp-mod
    "(?idmsuxU)"         regexp-mod
    "(?-idmsuxU)"        regexp-mod
    ;; (?idmsux-idmsux:X) X, as a non-capturing group with the given flags i d m s u x on - off
    "(?idmsuxU-idmsuxU:X)" regexp-mod
    "(?idmsuxU:)"          regexp-mod
    "(?-idmsuxU:)"         regexp-mod
    ;; (?=X)              X, via zero-width positive lookahead
    "(?=X)" regexp-mod
    ;; (?!X)              X, via zero-width negative lookahead
    "(?!X)" regexp-mod
    ;; (?<=X)             X, via zero-width positive lookbehind
    "(?<=X)" regexp-mod
    ;; (?<!X)             X, via zero-width negative lookbehind
    "(?<!X)" regexp-mod
    ;; (?>X)              X, as an independent, non-capturing group
    "(?>X)" regexp-mod

    "(?X)" !regexp-mod]]
  ["#%s"
   [;; Backslashes with character classes
    "\"[\\\\]\"" (partial = [:clojureRegexpDelimiter :clojureRegexpCharClass :clojureRegexpCharClass :clojureRegexpCharClass :clojureRegexpCharClass :clojureRegexpDelimiter])
    "\"\\[]\"" (partial = [:clojureRegexpDelimiter :clojureRegexpEscape :clojureRegexpEscape :clojureRegexp :clojureRegexpDelimiter])
    "\"\\\\[]\"" (partial = [:clojureRegexpDelimiter :clojureRegexpEscape :clojureRegexpEscape :clojureRegexpCharClass :clojureRegexpCharClass :clojureRegexpDelimiter])]])

(comment (test #'test-java-regexp-literals))
