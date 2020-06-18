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

# (def 'd!test
#    (d!
#       ("this" () (prinl "this"))
#       ("that" () (prinl "that"))
#       (T () (prinl "the other thing")) ) )

# this is essentially a plambda... kinda, not really
(de d!state @
   (job '((State . NIL) (Cnt . 0))
      (macro
         ((d!
            ("get" (Sym) (val Sym))
            ("set" (Sym Val) (set Sym Val)) )
         ^(rest) ) ) ) )

# latest, closest to book version
# no 'Self' reference, only 'This'
#
#    (<p!> "set" 'This ...)
#
# NOTE - 'p!' is meant to be used-as a read macro within a @-args 'de' form, e.g.
#
#   (de p!-test @
#      `(p! (N) ((A . 0))
#          (inc 'A N) ) )
#
# NOTE - this 'plambda' differs from the original in that the pandoric arguments
# are defined (with optional init values) with in the 'plambda' form, not taken from the
# surrounding lexical environment. Oh well, this works for a proof-of-concept.
(de p! Lst
   (let ((@Args @Pargs . @Body) Lst)
      (macro 
         '(job ^(list (lit (macro '(^(p!-vars->job-vars (cons 'This @Pargs))))))
            (ifn This (setq This ^(list (lit (macro '((^(p!-vars->lambda-vars @Args)) ^ @Body))))))
            (macro
               ((d!
                  ("get" (Sym) (val Sym))
                  ("set" (Sym Val) (set Sym Val))
                  # hack
                  (T ()  (This ^(list '^ '(rest)))) )
                ^(list '^ '(rest))) ) ) ) ) )

# (A B (C . 0)) -> ((A) (B) (C . 0))
(de p!-vars->job-vars (Lst)
   (make
      (for "L" Lst
         (if (pair "L")
            (link @)
            (link (cons "L" NIL)) ) ) ) )

# (A B (C . 0)) -> (A B C)
(de p!-vars->lambda-vars (Vars)
   (make
      (for "V" Vars
         (if (pair "V")
            (link (car @))
            (link "V") ) ) ) )

# with-pandoric - access pandoric variables from anywhere
# binds 'Self' so 'setp' can set pandoric vars
(de with-p! Lst
   (let ((@Syms "Box" . @Body) Lst)
      (macro
         (let ^(list
                  (make 
                     (chain (list 'Self "Box"))
                     (for "S" @Syms
                        (if (= "S" 'This)
                           (chain (list "S" (cons 'quote ("Box" "get" "S"))))
                           (chain (list "S" ("Box" "get" "S"))) ) ) ) )
            ^ @Body ) ) ) )


# setp - used to modify pandoric vars inside 'with-pandoric'
#
#    (with-pandoric (A B) some-p!-form
#       (setp A 4)
#       (setp B "string") )
#
# NOTE - not a general as CL's 'setf', but this is more picolispy
# NOTE - fancy macro definition so we don't have to 'quote' var. gotta use 'macro'
# as much as possible to make code super cool and mind-bending like Common Lisp
(de setp "Lst"
   (macro (Self "set" ^(list (cons 'quote (car "Lst"))) ^(cdr "Lst"))) )

(de hotpatch-p! Lst
   (let ((@Box @New) Lst)
      (macro
         (with-p! () @Box
            (setp This @New) ) ) ) )

(de recode-p! Lst
   (let ((@Vars @Box @New) Lst)
      (macro
         (with-p! @Vars @Box
            (setp This @New) ) ) ) )

### TESTING
(de p!test @ `(p! (N) ((X . 0)) (inc 'X N)))

# : (p!test 4)
# -> 4
# : (p!test 4)
# -> 8
# : ### p! over d!
# : (with-p! (X) p!test
#       ('`(d!
#          ("inc" () (setp X (inc 'X)))
#          ("dec" () (setp X (dec 'X))) )
#     "dec" ) )
# -> 7
# : (p!test "get" 'X)
# -> 7
# : (with-p! (This) p!test (setp This '((N) (inc 'X (* 2 N)))))
# -> ((N) (inc 'X (* 2 N)))
# : (p!test "get" 'This)
# -> ((N) (inc 'X (* 2 N)))
# : (p!test 10)
# -> 27


# it would be cool if this code could generate something that functions
# like the following
#
# (pd! ((X . 0)) 
#    ("inc"   () (setp X (inc 'X)))
#    ("dec"   () (setp X (dec 'X)))
#    ("reset" () (setp X 0)) )
#
(de p!-over-d!-test @
   (job '((Self . `(list '@ (p! () ((X . 0))))))
      (if (member (car (rest)) '("get" "set"))
         (with-p! (X) Self
            (cond
               ((= (car @) "get") X)
               ((= (car @) "set") (setp X (last (rest)))) ) )
         # (macro (Self (car @) ^(cdr (rest))))
         (with-p! (X) Self
            (macro
               ('`(d!
                     ("inc"   () (setp X (inc 'X)))
                     ("dec"   () (setp X (dec 'X)))
                     ("reset" () (setp X 0)) )
                  ^(rest)) ) ) ) ) )

(de p!-over-d!-test2 @
   (job '((Self . `(list '@ (p! () ((X . 0))))))
      (with-p! (X) Self
         (if (member (car (rest)) '("get" "set"))
            (cond
               ((= (car @) "get") X)
               ((= (car @) "set") (setp X (last (rest)))) )
            (macro
               ('`(d!
                     ("inc"   () (setp X (inc 'X)))
                     ("dec"   () (setp X (dec 'X)))
                     ("reset" () (setp X 0)) )
                  ^(rest)) ) ) ) ) )


# : (p!-over-d!-test "inc")
# -> 1
# : (do 5 (p!-over-d!-test "inc"))
# -> 6
# : (p!-over-d!-test "dec")
# -> 5
# : (p!-over-d!-test "set" 'X 17)
# -> 17
# : (p!-over-d!-test "dec")
# -> 16


# NEAT - code can be run during a 'macro' expansion
#
# : (let Val 2
#      (macro
#         ^(prog1 NIL  # return NIL
#            (setq Val 3) )
#         # this will be included in expansion
#         '(let X ^(list Val) ) ) )
# -> (let X 3)
