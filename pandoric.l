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

# can be applied, but breaks 'p!'
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
# surrounding lexical environment and exported, accessible via 'with-p!(s)'.
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

### *p! - anonymous p!
#
(de *p! Lst
   (let [("Args" "Pargs" . Body) Lst]
      (macro!
         (list '@
            (p! _"Args" _"Pargs" ^ Body) ) ) ) )
###

### with-p! - access pandoric variables from anywhere
#
#  (with-p! (X Y) p!-form
#     (setp X 4)
#     (setp Y (do-something)) )
#
(de with-p! Lst
   (let [("Syms" "P!" . Body) Lst]
      (macro
         (let [^(with-p!-env)]
            ^ Body ) ) ) )

(de with-p!-env ()
   (make
      (link 'Self "P!")
      (link 'setp (lit set-with-p!))
      (for "S" "Syms"
         (ifn (= "S" 'This)
            (link "S" ("P!" "get" "S"))
            (link 'This (cons 'quote ("P!" "get" 'This))) ) ) ) )
###

### with-p!s - combine p! environments
#
#  : (with-p!s [(This X Y) p!-1
#               (This Y Z) p!-2 ]
#       ... )
#
#  -> (let [P!1 p!-1  This1 _  X _  Y$1 _  P!2 p!-2  This2 _  Y$2 _  Z _ ]
#         ... )
#
(de with-p!s Lst
   (let [("P!s" . Body) Lst]
      (macro
         (let [^(with-p!s-env "P!s")]
            ^ Body ) ) ) )

(de with-p!s-env (P!s)
   (make
      (link 'setp (lit set-with-p!s))  # define 'setp' in 'with-p!s'
      (use P!        # current p!
         (let [N 0   # current p! number for 'P![N]','This[N]' and '[Var]$[N]' anaphors
               Boxes (groups-of 2 P!s)
               Dups  # vars referenced from multiple p!s
                  (delete 'This  # 'This' processed separately (not 100% on this yet)
                     (uniq
                        (fish atom
                           (filter '((L) (>= (length L) 2))
                              (by name group (fish atom P!s))))))
               P!Tab '() ]  # 'P!Table' used by 'setp' to look up parent 'p!' for a (possibly anaphoric) symbol
            (for Box Boxes
               (let [(Pargs P) Box]
                  (use P!T  # P!Tab entry
                     (prog
                        # do p!-form -> P![N]
                        (setq P! P)
                        (link (any (pack "P!" (inc 'N))) P)  # -> e.g. '(P!1 first-p!-arg)
                        # do p! vars
                        (for "Sym" Pargs
                           (if (= "Sym" 'This)
                              # This -> This[N]
                              (prog
                                 (link (any (pack 'This N)) (cons 'quote (P! "get" "Sym")))
                                 (queue 'P!T (cons (any (pack "P!" N)) (any (pack 'This N)))) )  # e.g. (P!1 . This1) -> P!Tab
                              (if (member "Sym" Dups)
                                 # Var -> Var$[N]
                                 (prog
                                    (link (any (pack "Sym" "$" N)) (P! "get" "Sym"))
                                    (queue 'P!T (cons (any (pack "P!" N)) (any (pack "Sym" "$" N)))) )  # (P!1 . Y$1) -> P!Tab
                                 # Var
                                 (prog
                                    (link "Sym" (P! "get" "Sym"))
                                    (queue 'P!T (cons (any (pack "P!" N)) "Sym")) ) ) ) ) )  # (P!1 . X) -> P!Tab
                     (setq P!Tab (append P!T P!Tab)) ) ) )  # -> '((P!1 . X) (P!1 . Y-1) (P!2 . Y-2) (P!2 . Z))
            (link 'P!Table (cons 'quote (group P!Tab))) ) ) ) )  # -> '((P!1 X Y-1) (P!2 Y-2 Z))
###

### setp - modify p!-vars in 'with-p!(s)' forms

# bound to 'setp' in 'with-p!' forms
(de set-with-p! Lst
   (let [(@Sym . Rest) Lst]
      (macro
         (Self "set" '@Sym ^ Rest) ) ) )

# bound to 'setp' in 'with-p!s' forms
(de set-with-p!s Lst
   (let [(@Sym . Rest) Lst]
      (macro!
         ( _(car
               (find
                  '((P) (member @Sym P))
                  P!Table ) )
          "set"
          _(Var$N->Var @Sym)
          ^ Rest) ) ) )

(de Var$N->Var (Sym)
   (cons 'quote
      (any
         (caar
            (split (chop (pack Sym)) "$") ) ) ) )

# NOTE - fancy macro definitions so we don't have to 'quote' var.
# It's important to use 'macro' as much as possible to make code super cool
# and mind-bending like Common Lisp ;P
###

### pd! - pandoric dispatchers!
#
# (let X 2
#    (pd! (X)
#       ("inc"   () (inc 'X))
#       ("dec"   () (dec 'X))
#       ("reset" () (setq X 0)) ) )
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

### *pd! - anonymous pd!
#
(de *pd! Lst
   (let [("Pargs" . Body) Lst]
      (macro!
         (list '@
            (pd! _"Pargs" ^ Body) ) ) ) )
###

### dp - define pandoric method
#
(de dp Lst
   (let [("Nm" "Args" "Pargs" . Body) Lst]
      (macro!
         (de _"Nm" (Self ^ "Args")
            _(if "Pargs"
               (macro!
                  '(with-p! _"Pargs" Self
                     ^ Body ) )
               (macro '(prog ^ Body) ) ) ) ) ) )

### pbj - pandoric obj
(de pbj% Args
   (macro!
      '(macro!
         (let [^(mapcan (\\ (@1 _'_ @1)) Args)]
            (*p! () (^ Args)) ) ) ) )

# : (de panrectangle (X Y DX DY) `(pbj% X Y DX DY))
# -> panrectangle
# : (def 'pr1 (panrectangle 1 1 20 30))
# -> pr1

(de pbj Lst
   (let [("Nm" . Args) Lst]
      (macro!
         (de _ "Nm" (^ Args)
            (macro!
               (let [^(mapcan (\\ (@1 _'_ @1)) Args)]
                  (*p! () (^ Args)) ) ) ) ) ) )

(de pbj%% Lst
   (let [("Nm" Args) Lst]
      (macro!
         (de _ "Nm" (^ Args)
            (macro!
               (let [^(mapcan (\\ (@1 _'_ @1)) Args)]
                  (*p! () (^ Args)) ) ) ) ) ) )

# : (pbj panrectangle X Y DX DY)
# -> panrectangle
# : (def 'pr1 (panrectangle 1 1 20 30))
# -> pr1
###

# misc abstractions
(de recode-p! (Box New)
   (with-p! (This) Box
      (setp This New) ) )

### tests
(load "pandoric-tests.l")
(pandoric-tests)
