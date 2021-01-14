# lilypond syntax for picolisp
#
#  : (ly1)
#  ly1 -- the lilypond repl
#  : { a'4 b'4 c''2 }^
#  -> (lyWrap "a'4" "b'4" "c''2")

(de lyload (File)
   (lytransform
      (lyread File) ) )

(def 'LYREADSTRING "_-+=!?<>$*',:/\|.~[]")

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
   (let [Chop (chop Sym)  (Car . Cdr) Chop]
      (and
         # no functions
         (not (pre? "ly" Sym))
         (not (pre? "\\\\" Sym))
         (or
            # basics
            (member Sym '(aes a ais bes b bis ces c cis des d dis ees e eis fes f fis ges g gis | r))
            (= (last Cdr) "~")               # tied notes
            (member (last Cdr) '("(" ")"))   # slurs
            (member "[" Cdr)
            (member "]" Cdr)
            (and                             # notes
               (member Car '(a b c d e f g r))
               (not  # because e.g. 'des/major' or 'c|maj7' generator fns
                  (or
                     (member "|" Cdr)
                     (member "/" Cdr)))
               (num? (any (last Cdr))) )
            (member "'" Cdr)
            (member "," Cdr)
            (member "." Cdr)
            (and                             # time signatures
               (member "/" Cdr)
               (format (pack (split Chop "/"))) )
            (member ":" Cdr)                 # chord names
            (member "\\" Cdr)                # dynamics / markup
            (and (= Car "<") (member (car Cdr) '(a b c d e f g)))
            (member ">" Cdr) )               # chords
         T ) ) )

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

(lytest "{ a'2( b'2 c''1) }"
   '(lyWrap "a'2(" "b'2" "c''1)") )
