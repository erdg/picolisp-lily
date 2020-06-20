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
# (p!-args->fn (A B (C . 0))) -> (A B C)
(de p!-args->fn (Vars)
   (make
      (for "V" Vars
         (if (pair "V")
            (link (car @))
            (link "V") ) ) ) )
###

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
### p! - the definition
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

# anonymous p!
(de @p! Lst
   (let ((@Args @Pargs . @Body) Lst)
      (macro
         (list '@
            (p! @Args @Pargs ^ @Body) ) ) ) )

# with-p! - access pandoric variables from anywhere
#
#  (with-p! (X Y) p!-form
#     (setp X 4)
#     (setp Y (do-something)) )
#
(de with-p! Lst
   (let ((@Syms "Box" . @Body) Lst)
      (macro
         (let (^(make
                   (chain (list 'Self "Box"))  # binds 'Self' so 'setp' can set pandoric vars
                   (for "S" @Syms
                      (if (= "S" 'This)
                         (chain (list "S" (cons 'quote ("Box" "get" "S"))))
                         (chain (list "S" ("Box" "get" "S"))) ) ) ) )
            ^ @Body ) ) ) )

### setp - modify p!-vars within 'with-p!'
(de setp "Lst"
   (macro (Self "set" ^(list (cons 'quote (car "Lst"))) ^(cdr "Lst"))) )
#
# NOTE - fancy macro definition so we don't have to 'quote' var.
# It's important to use 'macro' as much as possible to make code super cool
# and mind-bending like Common Lisp ;P

(de recode-p! Lst
   (let ((@Box @New) Lst)
      (macro
         (with-p! (This) @Box
            (setp This @New) ) ) ) )

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
            (apply This (rest)) ) ) ) )
            # (macro
            #    ((d!
            #       ("get" (Sym) (val Sym))
            #       ("set" (Sym Val) (set Sym Val))
            #       ^ @Body )
            #       # hack
            #     ^(list '^ '(rest))) ) ) ) ) )

(load "pandoric-tests.l")
