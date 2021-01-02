# lilypond syntax for picolisp
#
#  : (ly1)
#  ly1 -- the lilypond repl
#  : { a'4 b'4 c''2 }^
#  -> (lyWrap "a'4" "b'4" "c''2")

(de lyload (File)
   (transform
      (lyread File) ) )

(def 'LYREADSTRING "_-=!?<>$*',:/\|.~")
# read a macro file ("File.m.l" by convention)
(de lyread (File)
   (in File
      (make
         (while (read LYREADSTRING)
            (link @) ) ) ) )

(de transform (Lst)
   (and
      (_transform Lst)
      (mapcar pack @)
      (mapcar '((S) (if (lySym? S) (sym S) S)) @)
      (glue " " @)
      (any @) ) )


# BUG - time signatures must still be transient symbols (e.g. "4/4", not 4/4)
(de lySym? (Sym)
   (let [(Car . Cdr) (chop Sym)]
      (and
         (or
            # basics
            (member Sym '(aes a ais bes b bis ces c cis des d dis ees e eis fes f fis ges g gis))
            (and
               (member Car '(a b c d e f))
               (num? (any (last Cdr))) )
            (member "'" Cdr)    # notes
            (member "," Cdr)
            (member "." Cdr)
            (member ":" Cdr)    # chords
            (member "/" Cdr) )  # time signatures
         T ) ) )

(de _transform (X)
   (recur (X Acc)
      (ifn X
         (flip Acc)
         (case (car X)
            ("{" (recurse (cdr X) (cons 'lyWrap (char 40) Acc)))  # { ... } = (lyWrap ...)
            ("}" (recurse (cdr X) (cons (char 41) Acc)))
            (T   (recurse (cdr X) (cons (car X) Acc))) ) ) ) )

(de ly1 ()
   (prinl "ly1 -- the lilypond repl")
   (prin  ": ")
   (let M (till '^)  # '^' to end
      (prog
         (out (tmp "lyrepl") (prin M))
         (transform (lyread (tmp "lyrepl"))) ) ) )

(de ly1* ()
   (prinl "ly1* -- the lilypond repl (with pdf output)")
   (prin  ": ")
   (let M (till '^)  # '^' to end
      (and
         (out (tmp "lyrepl") (prin M))
         (out (tmp "repl.ly") (eval (transform (lyread (tmp "lyrepl")))))
         (call 'lilypond (pack "--output=" (tmp)) (tmp "repl.ly"))
         (call 'evince (tmp "repl.pdf")) ) ) )
