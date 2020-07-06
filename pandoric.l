(load "utils.l")

### d! - a dispatching fn
#
(de d! "Ds"
   (macro
      '("Args"
         (case (car "Args")
            ^(make
               (for "D" "Ds"
                  (link
                     (list (car "D")
                        (macro
                           '(apply '(^(cdr "D")) (cdr "Args")) ) ) ) ) ) ) ) ) )

(de d!% "Ds"
   (macro
      '(@
         (case (next)
            ^(make
               (for "D" "Ds"
                  (link
                     (list (car "D")
                        (macro
                           '(apply '(^(cdr "D")) (rest)) ) ) ) ) ) ) ) ) )
###

### p! - a read macro used within a "@-args" 'de' form, e.g.
#
#  (de ptest @
#     `(let X 2
#        (p! (N) (X)
#           (inc 'X N)) ) )
#
# that defines pandoric environments/functions.
#
# NOTE - make sure pandoric vars are also within the '`' read-macro
#
# variables in the 'cadr' of a 'p!' form ("Pargs" below) are gathered from the
# surrounding lexical environment and exported to the world, accessible via
# 'with-p!(s)'.
#
(de p! Lst
   (let [("Args" "Pargs" . Body) Lst]
      (macro!
         '(job '[^(p!-env->job "Pargs") _(cons 'This "Args" Body)]
            (macro
               ('`(d! ("get" (Sym) (val Sym))
                      ("set" (Sym Val) (set Sym Val))
                      (T ()  (This _'^ (rest))) )
                  _'^ (rest) ) ) ) ) ) )

(de p!-env->job (Lst)
   (make
      (for "L" Lst
         (link
            (or
               (assoc "L" (env))
               (list  "L") ) ) ) ) )
###

### @p! - anonymous p!
#
(de @p! Lst
   (let [("Args" "Pargs" . Body) Lst]
      (macro!
         (list '@
            (p! _ "Args" _ "Pargs" ^ Body) ) ) ) )
###

### with-p! - access pandoric variables from anywhere
#
#  (with-p! (X Y) p!-form
#     (setp X 4)
#     (setp Y (do-something)) )
#
(de with-p! Lst
   (let [("Syms" "Box" . Body) Lst]
      (macro
         (let [^(with-p!-env "Syms")]
            ^ Body ) ) ) )

(de with-p!-env (Syms)
   (make
      (link 'Self "Box")
      (link 'setp (lit set-with-p!))
      (for "S" Syms
         (if (= "S" 'This)
            (link "S" (cons 'quote ("Box" "get" "S")))
            (link "S" ("Box" "get" "S")) ) ) ) )
###

### with-p!s - combine p! environments
#
(de with-p!s Lst
   (let [("Pargs" . Body) Lst]
      (macro
         (let [^(with-p!s-env "Pargs")]
            ^ Body ) ) ) )

# first draft - dense syntax, but easiest to process
#
#  (with-p!s [((A B) p!-1) ((X Y) p!-2)]
#     (list A B X Y) )
#
(de with-p!s-env% (P!s)
   (make
      (link 'setp (lit set-with-p!s))  # define 'setp' in 'with-p!s'
      (for (N . P) P!s
         (let P! (cadr P)
            # P1 p!-form-1, PN p!-form-n
            (link (any (pack "P" N)) P!)
            (for "S" (car P)
               (if (= "S" 'This)
                (link (any (pack 'This N)) (cons 'quote (P! "get" "S")))
                (link "S" (P! "get" "S"))) ) ) ) ) )

# second draft - close, but doesn't do [Var]$[N] anaphors
#
#  : (with-p!s [p!-1 (This X) p!-2 (This Y)]
#       ... )
#
#  -> (let [P1 p!-1  This1 _  X _  P2 p!-2  This2 _  Y _]
#        ... )
#
# NOTE - in 'Pargs' the p!-env comes first, followed by imported vars.
#        this is opposite of 'with-p!s-env%' and Doug Hoyte's original
#        "vars first" syntax for 'with-pandoric'.
#
(de with-p!s-env%% (P!s)
   (make
      (link 'setp (lit set-with-p!s))  # define 'setp' in 'with-p!s'
      (use P! # current P
         (for (I . P) P!s
            (if (odd? I)
               # process p! ->  P1 p!-form-1 PN p!-form-n
               (prog
                  (setq P! P)
                  (link (any (pack "P" (inc 'N))) P) )
               # process p! vars
               (for "S" P
                  (if (= "S" 'This)
                     (link (any (pack 'This N)) (cons 'quote (P! "get" "S")))
                     (link "S" (P! "get" "S"))) ) ) ) ) ) )

# final draft
#
#  : (with-p!s [p!-1 (This X Y)
#               p!-2 (This Y Z)]
#       ... )
#
#  -> (let [P!1 p!-1  This1 _  X _  Y$1 _  P!2 p!-2  This2 _  Y$2 _  Z _ ]
#        ... )
#
(de with-p!s-env (P!s)
   (make
      (link 'setp (lit set-with-p!s))  # define 'setp' in 'with-p!s'
      (use P!        # current p!-env
         (let [N 0   # current p!-env number for 'P![N]','This[N]' and '[Var]$[N]' anaphors
               Dups  # vars referenced from multiple p!-envs
                  (delete 'This  # 'This' processed separately (not 100% on this yet)
                     (uniq
                        (fish atom
                           (filter '((L) (>= (length L) 2))
                              (by name group (fish atom P!s))))))
               P!Tab '() ]  # 'P!Table' used by 'setp' to look up parent 'p!' for a (possibly anaphoric) symbol
            (for (I . P) P!s
               (use P!T  # P!Tab entry
                  (if (odd? I)
                     # do p!-form -> P![N]
                     (prog
                        (setq P! P)
                        (link (any (pack "P!" (inc 'N))) P) )  # -> e.g. '(P!1 first-p!-arg)
                     # else do p! vars
                     (for "S" P
                        (if (= "S" 'This)
                           # This -> This[N]
                           (prog
                              (link (any (pack 'This N)) (cons 'quote (P! "get" "S")))
                              (queue 'P!T (cons (any (pack "P!" N)) (any (pack 'This N)))) )  # e.g. (P!1 . This1) -> P!Tab
                           (if (member "S" Dups)
                              # Var -> Var$[N]
                              (prog
                                 (link (any (pack "S" "$" N)) (P! "get" "S"))
                                 (queue 'P!T (cons (any (pack "P!" N)) (any (pack "S" "$" N)))) )  # (P!1 . Y$1) -> P!Tab
                              # Var
                              (prog
                                 (link "S" (P! "get" "S"))
                                 (queue 'P!T (cons (any (pack "P!" N)) "S")) ) ) ) ) )  # (P!1 . X) -> P!Tab
                  (setq P!Tab (append P!T P!Tab)) ) )  # -> '((P!1 . X) (P!1 . Y-1) (P!2 . Y-2) (P!2 . Z))
            (link 'P!Table (cons 'quote (group P!Tab))) ) ) ) )  # -> '((P!1 X Y-1) (P!2 Y-2 Z))
###

### setp - modify p!-vars in 'with-p!(s)' forms
#
# bound to 'setp' in 'with-p!' forms
(de set-with-p! Lst
   (macro (Self "set" ^(list (cons 'quote (car Lst))) ^(cdr Lst))) )
#
# bound to 'setp' in 'with-p!s' forms
(de set-with-p!s Lst
   (let [(@Sym . @Rest) Lst]
      (macro
         (^(list
              (car
                 (find
                    '((L) (member @Sym L))
                    P!Table) ) )
          "set"
          ^(list (cons 'quote (any (caar (split (chop (pack @Sym)) "$")))))
          ^ @Rest) ) ) )
#
# NOTE - fancy macro definitions so we don't have to 'quote' var.
# It's important to use 'macro' as much as possible to make code super cool
# and mind-bending like Common Lisp ;P
###

###
(de recode-p! Lst
   (let [(Box New) Lst]
      (macro!
         (with-p! (This) _ Box
            (setp This _ New) ) ) ) )
###

### pd! - pandoric dispatchers!
#
# (let X 2
#    (pd! (X)
#       ("inc"   () (inc 'X))
#       ("dec"   () (dec 'X))
#       ("reset" () (setp X 0)) ) )
#
# NOTE - 'recode-p!' does not work (as expected) with 'pd!' forms because 'd!'
# cannot be 'apply'ed. would need to wrap the new 'd!' with similar macro
# madness as below.  if recoding to a "normal" function, it should work. but
# let's be real - 'recode-p!' is cool, but how often will the need to
# dynamically redefine a closure's 'This' fn arise? seems more likely to just
# redefine it at the source.
#
(de pd! Lst
   (let [("Pargs" . Body) Lst]
      (macro!
         '(job '[^(p!-env->job "Pargs")
                 _(cons 'This
                    (macro!
                       '(@
                          (macro
                             ((d! ("get" (Sym) (val Sym))
                                  ("set" (Sym Val) (set Sym Val))
                                  ^ Body )
                              _'^ (rest) ) ) ) ) ) ]
            (apply This (rest)) ) ) ) )
###

(load "pandoric-tests.l")
(pandoric-tests)
