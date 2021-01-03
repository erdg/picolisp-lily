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
            (member Sym '(aes a ais bes b bis ces c cis des d dis ees e eis fes f fis ges g gis))
            (= (last Cdr) "~")   # tied notes
            (and
               (member Car '(a b c d e f))
               (num? (any (last Cdr))) )
            (member "'" Cdr)     # notes
            (member "," Cdr)
            (member "." Cdr)
            (member ":" Cdr)     # chord names
            (member "/" Cdr)     # time signatures
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
