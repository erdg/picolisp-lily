# lilypond syntax for picolisp
#
#  : (ly1)
#  ly1 -- the lilypond repl
#  : { a'4 b'4 c''2 }^
#  -> (lyWrap "a'4" "b'4" "c''2")
#
# KNOWN GOTCHA - no way to map single "octave ticks" to notes
# in lilypond syntax
#
#  (map-octave ' ...)
#  (map-octave , ...)
#  (map-octave "'" ...)
#  (map-octave "," ...)
#
# are all broken (with lilypond syntax).
# Use 'map-octave-1up' / 'map-octave-1dn' instead, or just
# use normal PicoLisp.

(de lyload (File)
   (lytransform
      (lyread File) ) )

(def 'LYREADSTRING "_-+=!?<>$%*',:/\|.~[]")

(de lyread (File)
   (in File
      (make
         (while (read LYREADSTRING)
            (link @) ) ) ) )

(de lytransform (Lst)
   (and
      (_lytransform Lst)
      (mapcar pack @)
      (compileSlurs @)
      (mapcar convertLySym @)
      (mapcar autoBarLines @)
      (glue " " @)
      (any @) ) )


# preprocess picolisp lilypond code, get all symbols ready for 'pack'ing
(de _lytransform (X)
   (recur (X Acc)
      (ifn X
         (flip Acc)
         (case (car X)
            # { ... } = (lyWrap ...)
            ("{" (recurse (cdr X) (cons 'lyWrap (char 40) Acc)))
            ("}" (recurse (cdr X) (cons (char 41) Acc)))
            ("+"
               (cond
                  # special rule for '++'
                  ((= (cadr X) "+")
                     (recurse (cddr X) (cons "++" Acc)) )
                  # e.g. +ii:dim7
                  ((member (car (chop (cadr X))) '(i I v V))
                     (recurse (cddr X) (cons (pack "+" (cadr X)) Acc)) )
                  (T (recurse (cdr X) (cons (car X) Acc))) ) )
            # e.g. -III
            ("-"
               (cond
                  ((member (car (chop (cadr X))) '(i I v V))
                     (recurse (cddr X) (cons (pack "-" (cadr X)) Acc)) )
                  (T (recurse (cdr X) (cons (car X) Acc))) ) )
            (T
               (cond
                  # time signatures
                  ((and (num? (car X)) (pre? "/" (cadr X)))
                     (recurse (cddr X) (cons (pack (car X) (cadr X)) Acc)) )
                  # \\functions (because lilypond uses e.g \relative)
                  ((pre? "\\" (car X))
                     (recurse (cdr X) (cons (sym (car X)) Acc)) )
                  # "pass through" transient symbols
                  ((pair (car X))
                     (recurse (cdr X) (cons (sym (pack (car X))) Acc)) )
                  (T
                     (recurse (cdr X) (cons (car X) Acc)) ) ) ) ) ) ) )


# hacks to allow lilypond slur notation
#
#  { a'2(  b'2  |  c''1) } -> (lyWrap "a'2(" "b'2" "|" "c''1)")
#
# this is likely the source of "EOF" errors when using lilypond syntax
# and can be turned off by commenting out the '(mapcar compileSlurs @)
# in the definition of 'lytransform' above.

(de compileSlurs (X)
   (use Slur
      (recur (X Acc)
         (ifn X
            (flip Acc)
            (cond
               ((and (not Slur) (lySym? (car X)) (= (cadr X) (char 40)) (lySym? (caddr X)))
                  (prog
                     (on Slur)
                     (recurse (cddr X) (cons (pack (car X) (cadr X)) Acc)) ) )
               ((and Slur (lySym? (car X)) (= (cadr X) (char 41)))
                  (prog
                     (off Slur)
                     (recurse (cddr X) (cons (pack (car X) (cadr X)) Acc)) ) )
               (T (recurse (cdr X) (cons (car X) Acc))) ) ) ) ) )


# applies 'sym' to any 'lySym?'s and converts forward slashes to backslashes
# for slightly less noisy (picolisp) lilypond code
(de convertLySym (Sym)
   (ifn (lySym? Sym)
      Sym
      (let Chop (chop Sym)
         (ifn (member "/" Chop)
            (sym Sym)
            (ifn (and (not (sub? ":" Sym)) (not (format (split Chop "/"))))
               (sym Sym)
               # "a'2->/fp/<"  ->  "a'2->\\fp\\<"
               (sym (pack (replace Chop "/" "\\"))) ) ) ) ) )

(de lySym? (Sym)
   (if (= Sym "|")  # bar checks
      T
      (let [Chop (chop Sym)  (Car . Cdr) Chop]
         (and
            # rest of bar lines handled separately (see 'autoBarLines')
            (not (pre? "|" Sym))
            (not (pre? "." Sym))
            (not (pre? ":" Sym))
            (not (pre? "[" Sym))
            # no functions
            (not (pre? "ly" Sym))
            (not (pre? "\\\\" Sym))
            (or
               # basics
               (member Sym '(aes a ais bes b bis ces c cis des d dis ees e eis fes f fis ges g gis | r))
               (= (last Cdr) "~")               # tied notes
               (member (last Cdr) '("(" ")"))   # slurs
               (member "[" Cdr)                 # manual beaming
               (member "]" Cdr)
               (and                             # notes
                  (member Car '(a b c d e f g r))
                  (not  # because e.g. 'des/major' or 'c|maj7' chordscale generator fns
                     (or
                        (member "|" Cdr)
                        (member "/" Cdr)))
                  (num? (any (last Cdr))) )
               (member "'" Cdr)
               (member "," Cdr)
               (member "." Cdr)
               (and
                  (member "/" Cdr)
                  (or
                     (format (pack (split Chop "/")))    # time signatures
                     (not (val (any Sym))) ) )           # abbreviated backslashes, e.g. "c/pp/<"
               (member ":" Cdr)                 # chord names
               (member "\\" Cdr)                # dynamics / markup
               (and (= Car "<") (member (car Cdr) '(a b c d e f g)))
               (member ">" Cdr) )               # chords
            T ) ) ) )


(de autoBarLines (Sym)
   (cond
      ((member Sym '("[:" "|:" ":|" ":]"))   # convenience
         (pack
            "(bar "
               (sym
                  (case (car @)
                     ("[:" "[|:")
                     ("|:" ".|:")
                     (":|" ":|.")
                     (":]" ":|]") ) )
            ")") )
      ((member Sym '("||" ".|" "|." "|.|" ";" "!" ".|:" ":|." ":..:" ":.|.:" ":|.|:" "[|:" ":|]" ":|][|:") )
         (pack "(bar " (sym Sym) ")") )
      (T Sym) ) )

(de barLine? (Sym)
   (member Sym
      '("||" ".|" "|."
         "|.|" ";" "!" ".|:"
         ":|." ":..:" ":.|.:"
         ":|.|:" "[|:" ":|]"
         ":|][|:" "[:" "|:" ":|" ":]") ) )

# repls
(de ly1 ()
   (prinl "ly1 -- the lilypond repl")
   (prin  ": ")
   (let M (till '^)  # '^' to end
      (prog
         (out (tmp "lyrepl") (prin M))
         (lytransform (lyread (tmp "lyrepl"))) ) ) )

# repl with pdf output
(de ly1* ()
   (prinl "ly1* -- the lilypond repl (with pdf output)")
   (prin  ": ")
   (let M (till '^)  # '^' to end
      (and
         (out (tmp "lyrepl") (prin M))
         (out (tmp "repl.ly") (eval (lytransform (lyread (tmp "lyrepl")))))
         (call 'lilypond (pack "--output=" (tmp)) (tmp "repl.ly"))
         (call 'evince (tmp "repl.pdf")) ) ) )


*Dbg
# TESTING
(out (tmp "lyrepl") (prin "{ a'4 b'4 c''2 }"))
(test '(lyWrap "a'4" "b'4" "c''2") (lytransform (lyread (tmp "lyrepl"))))

# NOTE - "\\\\" is used below because 'lytest' 'prin's a string to a temporary
# file (backquotes must be escaped again). "\\" is used in actual code.
(de lytest (Str Result)
   (prog
      (out (tmp "lyrepl") (prin Str))
      (test Result (lytransform (lyread (tmp "lyrepl")))) ) )

# basic sharps / flats
(lytest "{ aes'2 bes'2 cis''1 }"
   '(lyWrap "aes'2" "bes'2" "cis''1") )

# function calls with transient symbols
(lytest "{ (lyClef \"bass\") a2 b2 c1 }"
   '(lyWrap (lyClef "bass") "a2" "b2" "c1") )

# function calls with internal symbols
(lytest "{ (lyClef 'bass) a2 b2 c1 }"
   '(lyWrap (lyClef 'bass) "a2" "b2" "c1") )

# \\function calls
(lytest "{ (\\\\clef 'bass) a2 b2 c1 }"
   '(lyWrap (\\clef 'bass) "a2" "b2" "c1") )

# chords
(lytest "{ <c e g>2 <d f a>2 }"
   '(lyWrap "<c" "e" "g>2" "<d" "f" "a>2") )

# test that read-macros and quoted lists still work as normal
(lytest "{ ~(make (do 4 (link '(ly<> 4 c' e' g')))) }"
   '(lyWrap
      (ly<> 4 "c'" "e'" "g'")
      (ly<> 4 "c'" "e'" "g'")
      (ly<> 4 "c'" "e'" "g'")
      (ly<> 4 "c'" "e'" "g'") ) )

(lytest "{ aes1:maj9 }"
   '(lyWrap "aes1:maj9") )

(lytest "{ bes'1~ bes'1 }"
   '(lyWrap "bes'1~" "bes'1") )

# test read-macros and ties together
(lytest "{ ~(need 4 bes'1~) bes'1 }"
   '(lyWrap "bes'1~" "bes'1~" "bes'1~" "bes'1~" "bes'1") )

(lytest "{ (lyTime 7/8) a'8 b' a' b' a' b' c'' cis'' }"
   '(lyWrap (lyTime "7/8") "a'8" "b'" "a'" "b'" "a'" "b'" "c''" "cis''") )

# test bar checks
(lytest "{ (lyTime 2/4) f'4 g'4 | a'2 }"
   '(lyWrap (lyTime "2/4") "f'4" "g'4" "|" "a'2") )

# test dynamics - must use "\\" (e.g. c1\\ff) instead of "\" (as in normal lilypond)
(lytest "{ c'1\\\\pp }"
   '(lyWrap "c'1\\pp") )

# test forward slash conversion
(lytest "{ c'1/pp }"
   '(lyWrap "c'1\\pp") )

# slurs
(lytest "{ a'2( b'2 c''1) }"
   '(lyWrap "a'2(" "b'2" "c''1)") )

# test automatic bar lines
(lytest "{ a'2 b'2 || c''1 |. }"
   '(lyWrap "a'2" "b'2" (bar "||") "c''1" (bar "|.")) )

(test T (lySym? "c/pp/<"))
(test T (lySym? "bes2/f/!"))
(test T (lySym? "bes2\\f\\!"))
(test T (lySym? "a'2"))
(test T (lySym? "g,2("))
(test T (lySym? "<e'"))
(test T (lySym? "gis'"))
(test T (lySym? "b>"))
(test T (lySym? "d4."))
(test T (lySym? "3/4"))
(test T (lySym? "des1:maj9"))
(test T (lySym? "d:min7"))

(test NIL (lySym? "aes/min7"))
(test NIL (lySym? "g|maj7"))
