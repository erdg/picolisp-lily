(de test-utils ()

(test (2 3 4)
   (let X 2
      (macro! (let Y (1 _ X 3) (mapcar inc Y))) ) )

(test 25
   (macro! (let X _(+ 2 3) (* X X))) )

(test '(let Y 2 (* Y Y))
   (let @X 1
      (macro!% '(let Y !(inc '@X) @X (* Y Y))) ) )

(test 16
   (let X 1
      (macro!%
         (let Y !(setq X 2) _ (* X 2) (* Y Y))) ) )

(test "This is 17"
   (macro$ $(X 17) $(Y 'This) (let Z "is" (glue " " (list Y Z X)))) )

(test '(NIL NIL) (list X Y))


(test '(b c d) (before 'b 'd '(a b c d)))
(test      NIL (before 'b 'a '(a b c d)))

(test 4 ((lrec (lit '((X F) (inc (F)))) 0) '(A B C D)))


(test 3 (find-if-lrec odd? (2 3 4)))
(test 5 (find-if-lrec (fand odd? (> @ 4)) (2 3 4 5 6)))

(test 3 (some-lrec odd? (2 3 4)))

(test 5 (find-if-on-cdrs odd? (2 4 5 6)))


(test T
   ((fand odd? (> It 5)) 7) )

(test T
   ((fand pair (odd? (car @)) (> @ 5) (not (cdr It))) '(9)) )

(test (72 80 88 96 104)
   (filter num?
      (mapcar (fand odd? (+ 17 @) (* @ 4)) (range 1 9)) ) )


(test '((A 1) (B 2) (C 3))
   (mapcar (sbq '(@1 @2)) '(A B C) '(1 2 3)) )

(test '((A 1) (B 2) (C 3))
   (mapcar '`(sbq '(@1 @2)) '(A B C) '(1 2 3)) )

(test 2 (=@ 2 2 2))
(test NIL (=@ 2 3))

(test '(let Y 7 (* Y 2 3 4 5))
   (let (N 7 L (2 3 4 5))
      (cl-macro
         "`"(let Y ","N
               (* Y ",@"L) ) ) ) )

(t (prinl "utils.l -- passed all tests"))

)
