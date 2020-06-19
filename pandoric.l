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

(def 'd!-test
   (d!
      ("this" () 'this-thing)
      ("that" () 'that-thang)
      (T () 'default) ) )

(test 'this-thing (d!-test "this"))
(test 'that-thang (d!-test "that"))
(test 'default (d!-test))

(test 9
   (let X 3
      ((d! ("doubleX" () (* X 2)) ("squareX" () (* X X)))
         "squareX") ) )

(test 6
   (let X 3
      ((d! ("doubleX" () (* X 2)) ("squareX" () (* X X)))
         "doubleX") ) )

(test 15
   (let [X 3 D! (d! ("doubleX" () (* X 2)) ("squareX" () (* X X)))]
      (+ (D! "doubleX") (D! "squareX")) ) )

# this is essentially a 'p!' form
(de d!-with-state @
   (job '((State . NIL) (Cnt . 0))
      (macro
         ((d!
            ("get" (Sym) (val Sym))
            ("set" (Sym Val) (set Sym Val)) )
         ^(rest) ) ) ) )

(d!-with-state "set" 'Cnt 3)
(test 3 (d!-with-state "get" 'Cnt))
(d!-with-state "set" 'State "ON")
(test "ON" (d!-with-state "get" 'State))


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
# the definition
(de p! Lst
   (let ((@Args @Pargs . @Body) Lst)
      (macro
         '(job (^(lit (macro '(^(p!-env->job (cons 'This @Pargs))))))
            (ifn This (setq This ^(list (lit (macro '((^(p!-args->fn @Args)) ^ @Body))))))
            (macro
               ((d!
                  ("get" (Sym) (val Sym))
                  ("set" (Sym Val) (set Sym Val))
                  # hack
                  (T ()  (This ^(list '^ '(rest)))) )
                ^(list '^ '(rest))) ) ) ) ) )

# anonymous p!
(de @p! Lst
   (let ((@Args @Pargs . @Body) Lst)
      (list
         '@
         (macro
            '(job (^(lit (macro '(^(p!-env->job (cons 'This @Pargs))))))
               (ifn This (setq This ^(list (lit (macro '((^(p!-args->fn @Args)) ^ @Body))))))
               (macro
                  ((d!
                     ("get" (Sym) (val Sym))
                     ("set" (Sym Val) (set Sym Val))
                     # hack
                     (T ()  (This ^(list '^ '(rest)))) )
                   ^(list '^ '(rest))) ) ) ) ) ) )

###
(de p/d! Lst
   (let ((@Args @Pargs . @Body) Lst)
      (macro
         '(job (^(lit (macro '(^(p!-env->job (cons 'This @Pargs))))))
            (ifn This (setq This ^(list (lit (macro '((^(p!-args->fn @Args)) ^ @Body))))))
            (macro
               ((d!
                  ("get" (Sym) (val Sym))
                  ("set" (Sym Val) (set Sym Val))
                  ^ @Body )
                  # hack
                ^(list '^ '(rest))) ) ) ) ) )

(de p/d!-test @
   `(p/d! () ((X . 0) (Y . 0))
      ("incX" () (inc 'X))
      ("incY" () (inc 'Y))
      (T () (list X Y)) ) )

(test 1 (p/d!-test "incX"))
(test 1 (p/d!-test "incY"))
(test 2 (p/d!-test "incX"))
(test (2 1) (p/d!-test))

(de p/d!-env-test @
   `(let X 0
      (let Y 0
         (p/d! () (X Y)
            ("incX" () (inc 'X))
            ("incY" () (inc 'Y))
            (T () (list X Y)) ) ) ) )

(test 1 (p/d!-env-test "incX"))
(test 1 (p/d!-env-test "incY"))
(test 2 (p/d!-env-test "incX"))
(test (2 1) (p/d!-env-test))

###


###

###
# with-p! - access pandoric variables from anywhere
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

(test 30
   (let P! (@p! (N) ((X . 2)) (inc 'X N))
      (P! 2)  # -> 4
      (with-p! (X) P!
         (setp X (+ X 26)) ) # -> 30
      (P! "get" 'X) ) )

(test 30
   (let (X 2 P! (@p! (N) (X) (inc 'X N)))
      (P! 2)  # -> 4
      (with-p! (X) P!
         (setp X (+ X 26)) ) # -> 30
      (P! "get" 'X) ) )

(test 30
   (let X 2
      (let P! (@p! (N) (X) (inc 'X N))
         (P! 2)  # -> 4
         (with-p! (X) P!
            (setp X (+ X 26)) ) # -> 30
         (P! "get" 'X) ) ) )

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
(de p!-test @ `(p! (N) ((X . 0)) (inc 'X N)))

(test 3 (p!-test 3))
# : (p!-test 3)
# -> 3

(test 13 (p!-test 10))
# : (p!-test 10)
# -> 13

(test 12
   (with-p! (X) p!-test  # p! over anonymous d!
      ('`(d!
            ("inc" () (setp X (inc 'X)))
            ("dec" () (setp X (dec 'X))) )
       "dec" ) ) )

# : (with-p! (X) p!-test
#       ('`(d!
#          ("inc" () (setp X (inc 'X)))
#          ("dec" () (setp X (dec 'X))) )
#     "dec" ) )
# -> 12
# : (p!-test "get" 'X)
# -> 12

# : (with-p! (This) p!-test (setp This '((N) (inc 'X (* 2 N)))))
# -> ((N) (inc 'X (* 2 N)))
# : (p!-test "get" 'This)
# -> ((N) (inc 'X (* 2 N)))
# : (p!-test 10)
# -> 27


# it would be cool if this code could generate something that functions
# like the following
#
# (p/d! ((X . 0))
#    ("inc"   () (setp X (inc 'X)))
#    ("dec"   () (setp X (dec 'X)))
#    ("reset" () (setp X 0)) )
#

(de p!-over-d!-test @
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

(test 1 (p!-over-d!-test "inc"))
# : (p!-over-d!-test "inc")
# -> 1

(test 6 (do 5 (p!-over-d!-test "inc")))
# : (do 5 (p!-over-d!-test "inc"))
# -> 6

(test 5 (p!-over-d!-test "dec"))
# : (p!-over-d!-test "dec")
# -> 5

(test 17 (p!-over-d!-test "set" 'X 17))
# : (p!-over-d!-test "set" 'X 17)
# -> 17

(test 16 (p!-over-d!-test "dec"))
# : (p!-over-d!-test "dec")
# -> 16

(de p!-with-env-test @
   `(let X 2
      (p! (N) (X)
         (inc 'X N) ) ) )

(test 2 (p!-with-env-test "get" 'X))
# (p!-with-env-test "get" 'X)
# -> 2

(de p!-with-env-test2 @
   `(let X 2
      (p! (N) ((X . 3))
         (inc 'X N) ) ) )

# (p!-with-env-test "get" 'X)
# -> 3
(test 3 (p!-with-env-test2 "get" 'X))


# NEAT - code can be run during a 'macro' expansion
#
# : (let Val 2
#      (macro
#         ^(prog1 NIL  # return NIL
#            (setq Val 3) )
#         # this will be included in expansion
#         '(let X ^(list Val) ) ) )
# -> (let X 3)

  (de p!-env-test @
     `(let X 2
        (p! (N) (X)
           (inc 'X N)) ) )
#
# just make sure the variables are also within the '`' read-macro

(test 4 (p!-env-test 2))
# : (p!-env-test 2)
# -> 4


(test 13
   (with-p! (X) p!-env-test
      (setp X (+ X 9)) ) )
# : (with-p! (X) p!-env-test
#      (setp X (+ X 9)) )
# -> 13

(test 13 (p!-env-test "get" 'X))
# : (p!-env-test "get" 'X)
# -> 13
