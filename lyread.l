# lilypond syntax for picolisp
#
#  : (ly1)
#  ly1 -- the lilypond repl
#  : { a'4 b'4 c''2 }^
#  -> (lyWrap "a'4" "b'4" "c''2")

(de lyload (File)
   (transform
      (lyread File) ) )

(def 'LYREADSTRING "_-=!?<>$*',:/")
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


# NOTE - time signatures must still be transient symbols (e.g. "4/4", not 4/4)
# BUG - misses "basic" notes (e.g. a8 b16 cis8)
(de lySym? (Sym)
   (let C (cdr (chop Sym))
      (and
         (or
            (member "'" C)    # notes
            (member "," C)
            (member "." C)
            (member ":" C)    # chords
            (member "/" C) )  # time signatures
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
