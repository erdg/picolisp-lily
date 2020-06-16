### utils
(de nthcar (N Lst)
   (car (nth Lst N)) )

(de nar (N Lst) (car (nth Lst N)))

(de ndr (N Lst) (nth Lst N))

(de ring-from-list (Lst)
   (macro (circ ^ Lst)) )

(de cl-butlast (Lst)
   (head -1 Lst) )

(de cl-last (Lst)
   (tail 1 Lst) )

# first draft
#
# (ring "a" "b" "c")
# -> ("a" "b" "c" .)
# (ring (with-sharps (cis|min)))
# -> ("cis" "e" "gis" .)
#
# (de ring% Lst
#    (if (pair (car Lst))
#       (apply circ (eval @))
#       (apply circ Lst) ) )

# 2nd draft
#
# (de ring%% Lst
#    (apply circ
#       (make
#          (for "L" Lst
#             (if (atom "L")
#                (link "L")
#                (chain (eval "L")) ) ) ) ) )

(de ring @
   # create a circular list from (evaluated) args
   (apply circ
      (make
         (for "L" (rest)
            (if (atom "L")
               (link "L")
               (chain "L") ) ) ) ) )

(de delete-all (Xs Lst Flg)
   (while (++ Xs)
      (setq Lst (delete @ Lst Flg)) ) )

# (de delete-all% (Xs Lst)
#    (filter
#       (list (list 'E)
#          (cons 'nor
#             (make
#                (for X Xs
#                   (link (list '= (cons 'quote X) 'E)))) ) )
#       Lst ) )

(de flatten (Lst)
   (fish atom Lst) )

(de dlambda "Ds"
   (macro
      '("Args"
         (case (car "Args")
            ^(make
               (for "D" "Ds"
                  (link
                     (cons (car "D")
                        (list
                           (macro
                              '(apply '(^(cdr "D")) (cdr "Args")) ) ) ) ) ) ) ) ) ) )

(de dlambda-test1 @
   (macro 
      ((dlambda
         ("neat" () (prinl "NEAT"))
         (T () (prinl "default")))
       ^(rest))) )

(de dlambda-test2 @
   (job '((Cnt . 0))
      (macro
         ((dlambda
            ("inc" (N) (inc 'Cnt N))
            ("dec" (N) (dec 'Cnt N))
            ("reset" () (set 'Cnt 0)) )
          ^(rest) ) ) ) )

(de dlambda-test3 @
   (job '((Cnt . 0))
      (macro
         ((dlambda
            ("inc" (N) (inc 'Cnt N))
            ("dec" (N) (dec 'Cnt N))
            ("reset" () (set Cnt 0))
            ("get" (Sym) (val Sym)) )
          ^(rest) ) ) ) )

# this is essentially a plambda... kinda, not really
(de dlambda-with-state @
   (job '((State . NIL) (Cnt . 0))
      (macro
         ((dlambda
            ("get" (Sym) (val Sym))
            ("set" (Sym Val) (set Sym Val)) )
         ^(rest) ) ) ) )

(de plambda Lst
   (let ((@Pargs . @Body) Lst)
      (macro 
         '(job '@Pargs
            (macro
               ((dlambda
                  ("get" (Sym) (val Sym))
                  ("set" (Sym Val) (set Sym Val))
                  ^ @Body )
                  ^(list '^ '(rest))) ) ) ) ) )

# latest
(de plambda% Lst
   (let ((@Pargs . @Body) Lst)
      (macro 
         '(job ^(list (lit (macro '(^(letvars->jobvars @Pargs)))))
            (macro
               ((dlambda
                  ("get" (Sym) (val Sym))
                  ("set" (Sym Val) (set Sym Val))
                  ^ @Body )
                  ^(list '^ '(rest))) ) ) ) ) )

# (A B (C . 0)) -> ((A) (B) (C . 0))
(de letvars->jobvars (Lst)
   (make
      (for "L" Lst
         (if (pair "L")
            (link @)
            (link (cons "L" NIL)) ) ) ) )

(de plambda-test @
   `(plambda ((A . 0) (B . 1)) ("incA" (N) (inc 'A N))) )

(de plambda-test2 @
   `(plambda ((State . NIL))) )

(de plambda%-test @
   `(plambda% (A B (C . "this") (D . "that") (E . 1))))
