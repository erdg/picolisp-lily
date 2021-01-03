# lilypond syntax for picolisp
#
#  : (ly1)
#  ly1 -- the lilypond repl
#  : { a'4 b'4 c''2 }^
#  -> (lyWrap "a'4" "b'4" "c''2")

(de lyload (File)
   (lytransform
      (lyread File) ) )

(def 'LYREADSTRING "_-=!?<>$*',:/\|.~")

(de lyread (File)
   (in File
      (make
         (while (read LYREADSTRING)
            (link @) ) ) ) )

(de lytransform (Lst)
   (and
      (_lytransform Lst)
      (mapcar pack @)
      (mapcar '((S) (if (lySym? S) (sym S) S)) @)
      (glue " " @)
      (any @) ) )

(de _lytransform (X)
   (recur (X Acc)
      (ifn X
         (flip Acc)
         (case (car X)
            ("{" (recurse (cdr X) (cons 'lyWrap (char 40) Acc)))  # { ... } = (lyWrap ...)
            ("}" (recurse (cdr X) (cons (char 41) Acc)))
            (T
               (cond
                  # time signatures
                  ((and (num? (car X)) (pre? "/" (cadr X)))
                     (recurse (cddr X) (cons (pack (car X) (cadr X)) Acc)) )
                  # \\functions (because lilypond uses e.g \relative)
                  ((pre? "\\" (car X))
                     (recurse (cdr X) (cons (sym (car X)) Acc)) )
                  # don't mess with transient symbols
                  ((pair (car X))
                     (recurse (cdr X) (cons (sym (pack (car X))) Acc)) )
                  (T
                     (recurse (cdr X) (cons (car X) Acc)) ) ) ) ) ) ) )

(de lySym? (Sym)
   (let [(Car . Cdr) (chop Sym)]
      (and
         (or
            # basics
            (member Sym '(aes a ais bes b bis ces c cis des d dis ees e eis fes f fis ges g gis |))
            (= (last Cdr) "~")   # tied notes
            (and
               (member Car '(a b c d e f))
               (num? (any (last Cdr))) )
            (member "'" Cdr)     # notes
            (member "," Cdr)
            (member "." Cdr)
            (member "/" Cdr)     # time signatures
            (member ":" Cdr)     # chord names
            (member "\\" Cdr)    # dynamics
            (and (= Car "<") (member ">" Cdr)) )   # chords
         T ) ) )

(de ly1 ()
   (prinl "ly1 -- the lilypond repl")
   (prin  ": ")
   (let M (till '^)  # '^' to end
      (prog
         (out (tmp "lyrepl") (prin M))
         (lytransform (lyread (tmp "lyrepl"))) ) ) )

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
# testing
(out (tmp "lyrepl") (prin "{ a'4 b'4 c''2 }"))
(test '(lyWrap "a'4" "b'4" "c''2") (lytransform (lyread (tmp "lyrepl"))))

(de lytest (Str Result)
   (prog
      (out (tmp "lyrepl") (prin Str))
      (test Result (lytransform (lyread (tmp "lyrepl")))) ) )

# test basic sharps / flats
(lytest "{ aes'2 bes'2 cis''1 }"
   '(lyWrap "aes'2" "bes'2" "cis''1") )

(lytest "{ (lyClef \"bass\") a2 b2 c1 }"
   '(lyWrap (lyClef "bass") "a2" "b2" "c1") )

(lytest "{ (lyClef 'bass) a2 b2 c1 }"
   '(lyWrap (lyClef 'bass) "a2" "b2" "c1") )

# # hmm, this test fails even though it works with 'ly1' / 'ly1*'.
# # strange things happen when printing, piping and reading backslashes.
# (lytest "{ (\\clef 'bass) a2 b2 c1 }"
#    '(lyWrap (\\clef 'bass) "a2" "b2" "c1") )

# # works in repl, but test fails
# # recommended to use 'ly<>' for chords (see below)
# (lytest "{ <c e g>2 <d f a>2 }"
#    '(lyWrap "<c e g>2" "<d f a>2") )

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

# # test dynamics - must use "\\" (e.g. c1\\ff) instead of "\" (as in normal lilypond)
# # works in repl, test fails
# (lytest "{ c'1\\pp }"
#    '(lyWrap "c'1\\pp") )
