# d! - a dispatching 'quote fn
(de d! "Ds"
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

### helper fns for 'p!'

### p! - a read macro used within a "@-args" 'de' form, e.g.
#
#   (de p!-test @
#      `(p! (N) ((X . 0))
#          (inc 'X N) ) )
#
# that defines pandoric environments/functions.
#
# p!' can also grab vars from its surrounding lexical environment and
# export them to the world, e.g.
#
#  (de p!-env-test @
#     `(let X 2
#        (p! (N) (X)
#           (inc 'X N)) ) )
#
# just make sure the variables are also within the '`' read-macro
#
(de p! Lst
   (let ((@Args @Pargs . @Body) Lst)
      (macro
         '(job '(^(p!-env->job (cons 'This @Pargs)))
            (ifn This (setq This '((^(p!-args->fn @Args)) ^ @Body)))
            (macro
               ((d!
                  ("get" (Sym) (val Sym))
                  ("set" (Sym Val) (set Sym Val))
                  (T ()  (apply This (rest))) )
                ^(list '^ '(rest))) ) ) ) ) )  # don't ask... no idea why this works

# p! args initialized from surrounding lexical environment,
# possibly expanded or overwritten by '@Pargs' (see 'p!').
# (p!-env-job '(A B (C . 0))) -> ((A) (B) (C . 0))
(de p!-env->job (Lst)
   (make
      (for "L" Lst
         (if (pair "L")
            (link @)
            (link
               (or
                  (assoc "L" (env))
                  (cons "L" NIL) ) ) ) ) ) )

# p! args to 'quote' fn args
# (p!-args->fn '(A B (C . 0))) -> (A B C)
(de p!-args->fn (Vars)
   (make
      (for "V" Vars
         (if (pair "V")
            (link (car @))
            (link "V") ) ) ) )
###



###
# anonymous p!
(de @p! Lst
   (let ((@Args @Pargs . @Body) Lst)
      (macro
         (list '@
            (p! @Args @Pargs ^ @Body) ) ) ) )
###

###
# with-p! - access pandoric variables from anywhere
#
#  (with-p! (X Y) p!-form
#     (setp X 4)
#     (setp Y (do-something)) )
#
(de with-p! Lst
   (let ((@Syms "Box" . @Body) Lst)
      (macro
         (let (^(with-p!-env @Syms))
            ^ @Body ) ) ) )

(de with-p!-env (Syms)
   (make
      (chain (list 'Self "Box"))  # binds 'Self' so 'setp' can set pandoric vars
      (for "S" Syms
         (if (= "S" 'This)
            (chain (list "S" (cons 'quote ("Box" "get" "S"))))
            (chain (list "S" ("Box" "get" "S"))) ) ) ) )
###

### with-p!s - combine p! environments
#
#  (with-p!s
#     [((A B) p!-1)    # too dense, but easiest for 'with-p!s-env'
#      ((X Y) p!-2)    # ideally ((A B) p!-1 (X Y) p!-2)
#     ]
#     (list A B X Y) )
#
(de with-p!s Lst
   (let ((@Pargs . @Body) Lst)
      (macro
         (let (^(with-p!s-env% @Pargs))
            ^ @Body ) ) ) )

(de with-p!s-env (Lst)
   (make
      (for (N . W) Lst
         (let P! (cadr W)
            # P1 p!-form-1, PN p!-form-n
            (chain (list (any (pack "P" N)) P!))
            (for "S" (car W)
               (if (= "S" 'This)
                (chain (list (any (pack 'This N)) (cons 'quote ((cadr W) "get" "S"))))
                (chain (list "S" ((cadr W) "get" "S"))) ) ) ) ) ) )

# close, doesn't do X1 ... XN properly yet
# (p!1 (X Y) p!2 (Y Z)) -> (let (P1 p!1 X _ Y1 _ P2 p!2 Y2 _ Z _) ...)
(de with-p!s-env% (P!s)
   (make
      (use P! # current P
         # (let Dups (uniq (fish atom (filter '((L) (>= (length L) 2)) (by name group (delete 'This (fish atom P!s) T)))))
         #    (println Dups)
            (for (I . P) P!s
               (if (odd? I)
                  # process p! ->  P1 p!-form-1 PN p!-form-n
                  (prog
                     (setq P! P)
                     (chain (list (any (pack "P" (inc 'N))) P)) )
                  # process p! vars
                  (for "S" P
                     (if (= "S" 'This)
                        (chain (list (any (pack 'This N)) (cons 'quote (P! "get" "S"))))
                        (chain (list "S" (P! "get" "S"))) ) ) ) ) ) ) )

# # (p!1 (X Y) p!2 (Y Z)) -> (let (P1 p!1 X _ Y1 _ P2 p!2 Y2 _ Z _) ...)
# (de with-p!s-env%% (P!s)
#    (make
#       (use P! # current P
#          (let Dups (uniq (fish atom (filter '((L) (>= (length L) 2)) (by name group (delete 'This (fish atom P!s) T)))))
#             # (println Dups)
#             (for (I . P) P!s
#                (if (odd? I)
#                   # process p! ->  P1 p!-form-1 PN p!-form-n
#                   (prog
#                      (setq P! P)
#                      (chain (list (any (pack "P" (inc 'N))) P)) )
#                   # process p! vars
#                   (for "S" P
#                      (if (= "S" 'This)
#                         (chain (list (any (pack 'This N)) (cons 'quote (P! "get" "S"))))
#                         (if (member "S" Dups)
#                            (chain (list (any (pack "S" N))))
#                            (chain (list "S" (P! "get" "S"))) ) ) ) ) ) ) ) ) )

(de odd? (N) (n0 (% N 2)))
###

###

###
# setp - modify p!-vars within 'with-p!'
(de setp "Lst"
   (macro (Self "set" ^(list (cons 'quote (car "Lst"))) ^(cdr "Lst"))) )
#
# NOTE - fancy macro definition so we don't have to 'quote' var.
# It's important to use 'macro' as much as possible to make code super cool
# and mind-bending like Common Lisp ;P
###

###
(de recode-p! Lst
   (let ((@Box @New) Lst)
      (macro
         (with-p! (This) @Box
            (setp This @New) ) ) ) )
###

### pandoric dispatchers!
#
# (let X 2
#    (pd! () (X)
#       ("inc"   () (setp X (inc 'X)))
#       ("dec"   () (setp X (dec 'X)))
#       ("reset" () (setp X 0)) ) )
#
# BUG - 'recode-p!' does not work with 'pd!' forms
#
(de pd! Lst
   (let ((@Args @Pargs . @Body) Lst)
      (macro
         '(job '(^(p!-env->job (cons 'This @Pargs)))
            (ifn This
               (setq This
                  '(@
                     (macro
                        ((d!
                           ("get" (Sym) (val Sym))
                           ("set" (Sym Val) (set Sym Val))
                           ^ @Body )
                           # hack
                         ^(list '^ '(rest)) ) ) ) ) )
            ###
            (apply This (rest)) ) ) ) )
            # (macro
            #    ((d!
            #       ("get" (Sym) (val Sym))
            #       ("set" (Sym Val) (set Sym Val))
            #       ^ @Body )
            #       # hack
            #     ^(list '^ '(rest))) ) ) ) ) )
            ###
###

(load "pandoric-tests.l")
(pandoric-tests)
