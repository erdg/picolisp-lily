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

(def 'dlambda-test4
   (dlambda
      ("this" () (prinl "did this"))
      ("that" () (prinl "did that")) ) )

# this is essentially a plambda... kinda, not really
(de dlambda-with-state @
   (job '((State . NIL) (Cnt . 0))
      (macro
         ((dlambda
            ("get" (Sym) (val Sym))
            ("set" (Sym Val) (set Sym Val)) )
         ^(rest) ) ) ) )

# # first draft
# (de plambda% Lst
#    (let ((@Pargs . @Body) Lst)
#       (macro 
#          '(job '@Pargs
#             (macro
#                ((dlambda
#                   ("get" (Sym) (val Sym))
#                   ("set" (Sym Val) (set Sym Val))
#                   ^ @Body )
#                   ^(list '^ '(rest))) ) ) ) ) )

# # second draft
# (de plambda%% Lst
#    (let ((@Pargs . @Body) Lst)
#       (macro 
#          '(job ^(list (lit (macro '(^(plambda-vars->job-vars @Pargs)))))
#             (macro
#                ((dlambda
#                   ("get" (Sym) (val Sym))
#                   ("set" (Sym Val) (set Sym Val))
#                   ^ @Body )
#                   ^(list '^ '(rest))) ) ) ) ) )

# latest, closest to book version
# no 'Self' reference, only 'This'
#
# BUG - after defining a 'plambda' form (ie, with '`' read-macro, see below)
# 'This' cannot be redefined in the source code without re-reading (and not
# just re'load'ing) the file. 'This' can be dynamically changed with e.g.
#
#    (<plambda> "set" 'This ...)
#
# eventually 'with-pandoric' will work too.
#
# NOTE - 'plambda' is meant to be used-as a read macro within a var-args (@) 'de' form, e.g.
#
#   (de plambda-test @
#      `(plambda (N) ((A . 0))
#          (inc 'A N) ) )
#
# NOTE - this 'plambda' differs from the original in that the pandoric arguments
# are defined (with optional init values) with in the 'plambda' form, not taken from the
# surrounding lexical environment. Oh well, this works for a proof-of-concept.
(de plambda Lst
   (let ((@Args @Pargs . @Body) Lst)
      (macro 
         '(job ^(list (lit (macro '(^(plambda-vars->job-vars (cons 'This @Pargs))))))
            (once (setq This ^(list (lit (macro '((^(plambda-vars->lambda-vars @Args)) ^ @Body))))))
            (macro
               ((dlambda
                  ("get" (Sym) (val Sym))
                  ("set" (Sym Val) (set Sym Val))
                  # hack
                  (T ()  (This ^(list '^ '(rest)))) )
                ^(list '^ '(rest))) ) ) ) ) )

# (A B (C . 0)) -> ((A) (B) (C . 0))
(de plambda-vars->job-vars (Lst)
   (make
      (for "L" Lst
         (if (pair "L")
            (link @)
            (link (cons "L" NIL)) ) ) ) )

# (A B (C . 0)) -> (A B C)
(de plambda-vars->lambda-vars (Vars)
   (make
      (for "V" Vars
         (if (pair "V")
            (link (car @))
            (link "V") ) ) ) )

# with-pandoric - access pandoric variables from anywhere
# binds 'This' so 'setp' can set pandoric vars
(de with-pandoric Lst
   (let ((@Syms "Box" . @Body) Lst)
      (macro
         (let ^(list
                  (make 
                     (chain (list 'This "Box"))
                     (for "S" @Syms (chain (list "S" ("Box" "get" "S")))) ) )
            ^ @Body ) ) ) )

# setp - used to modify pandoric vars inside 'with-pandoric'
#
#    (with-pandoric (A B) some-plambda-form
#       (setp A 4)
#       (setp B "string") )
#
# NOTE - not a general as CL's 'setf', but this is more picolispy
# NOTE - fancy macro definition so we don't have to 'quote' var. gotta use 'macro'
# as much as possible to make code super cool and mind-bending like Common Lisp
(de setp "Lst"
   (macro (This "set" ^(list (cons 'quote (car "Lst"))) ^(cdr "Lst"))) )

(de pandoric-hotpatch Lst
   (let ((@Box @New) Lst)
      (macro
         (with-pandoric () @Box
            (setp This @New) ) ) ) )

(de pandoric-recode Lst
   (let ((@Vars @Box @New) Lst)
      (macro
         (with-pandoric @Vars @Box
            (setp This @New) ) ) ) )

# (de plambda-test @
#    `(plambda% ((A . 0) (B . 1)) 
#       ("incA" (N) (inc 'A N)) ) )

# (de plambda-test2 @
#    `(plambda%% ((State . NIL))) )

# (de plambda-test3 @
#    `(plambda%% (A B (C . "this") (D . "that") (E . 1))))

(de plambda-test4 @
   `(plambda (N) ((A . 0))
      (inc 'A (* N 2))) )

(de plambda-test5 @
   `(plambda (N) ((A . 2) (B . 4))
      (* (inc 'A N) (inc 'B (* 2 N))) ) )
