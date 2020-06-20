### d! tests
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
###


### @p! tests
(test 33
   (let P! (@p! (N) ((X . 2)) (inc 'X N))
      (P! 2)                  # -> 4
      (with-p! (X) P!
         (setp X (+ X 26)) )  # -> 30
      (P! 3)                  # -> 33
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
###

### pd! tests
(de pd!-test @
   `(pd! () ((X . 0) (Y . 0))
      ("incX" () (inc 'X))
      ("incY" () (inc 'Y))
      (T () (list X Y)) ) )

(pd!-test "incX")
(pd!-test "incY")
(pd!-test "incY")

(test (1 2) (pd!-test))

# call fn from anywhere
(test 5
   (prog
      (with-p! (This X) pd!-test
         (do 4 (setp X (This "incX"))) )
      (pd!-test "get" 'X) ) )

(de pd!-env-test @
   `(let X 0
      (let Y 0
         (pd! () (X Y)
            ("incX" () (inc 'X))
            ("incY" () (inc 'Y))
            (T () (list X Y)) ) ) ) )

(test 1 (pd!-env-test "incX"))
(test 1 (pd!-env-test "incY"))
(test 2 (pd!-env-test "incX"))
(test (2 1) (pd!-env-test))
###

### p! tests
(de p!-test @ `(p! (N) ((X . 0)) (inc 'X N)))

(test 3 (p!-test 3))
# : (p!-test 3)
# -> 3

(test 13 (p!-test 10))
# : (p!-test 10)
# -> 13

(prog
   (with-p! (X) p!-test  # p! over anonymous d!
      ((d!
         ("inc" () (setp X (inc 'X)))
         ("dec" () (setp X (dec 'X))) )
       "dec" ) )
   (p!-test "get" 'X) )

# : (p!-test "get" 'X)
# -> 12
(test 12 (p!-test "get" 'X))

(with-p! (This) p!-test (setp This '((N) (inc 'X (* 2 N)))))
# -> ((N) (inc 'X (* 2 N)))

# : (p!-test 10)
# -> 32
(p!-test 10)
(test 32 (p!-test "get" 'X))

# : (p!-test "get" 'This)
# -> ((N) (inc 'X (* 2 N)))
(test '((N) (inc 'X (* 2 N))) (p!-test "get" 'This))

(recode-p! p!-test
   '((N) (inc 'X (* 3 N))) )

(p!-test 7)  # -> 53
(test 53 (p!-test "get" 'X))
###

### X taken from env
(de p!-with-env-test @
   `(let X 2
      (p! (N) (X)
         (inc 'X N) ) ) )

(test 2 (p!-with-env-test "get" 'X))
# (p!-with-env-test "get" 'X)
# -> 2
###

### X overwritten in p! args
(de p!-with-env-test2 @
   `(let X 2
      (p! (N) ((X . 3))
         (inc 'X N) ) ) )

# (p!-with-env-test "get" 'X)
# -> 3
(test 3 (p!-with-env-test2 "get" 'X))
###

###
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
###



###
(de p!-over-d!-test @
   (job '((Self . `(list '@ (p! () ((X . 0))))))  # this was the first '@p!'
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
###
###
(def '@p!-test
   (let X 2
      (@p! (N) (X) (inc 'X N)) ) )

(@p!-test 2)

(test 4 (@p!-test "get" 'X))

(test 13
   (with-p! (X) @p!-test
      (setp X (+ X 9)) ) )
# : (with-p! (X) p!-env-test
#      (setp X (+ X 9)) )
# -> 13
###
