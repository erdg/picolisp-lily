[de pandoric-tests ()

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
#


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

# pd! tests
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
   (job '((Self . `(list '@ (p! () ((X . 0))))))  # this was the first '@p!' (anonymous p!)
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

### nested 'with-p!'s - prototype for 'with-p!s'
(test (15 8)
   (let (X 2 Y 3)
      (let [P1 (@p! (N) (X) (inc 'X N))
            P2 (@p! (N) (Y) (inc 'Y N))]
         (with-p! (X) P1
            (with-p! (Y) P2
               (P1 (+ (P2 5) 5))
               (list
                  (P1 "get" 'X)
                  (P2 "get" 'Y)) ) ) ) ) )

# (test (53 1)
#    (with-p!s (((X) p!-test) ((Y) pd!-env-test))
#       (list X Y) ) )

(test (53 1)
   (with-p!s [p!-test (X)
              pd!-env-test (Y) ]
      (list X Y) ) )

# test 'This[N]' anaphors
(test '((N) (inc 'X (* 3 N)))
   (with-p!s [p!-test      (This X)
              pd!-env-test (This Y) ]
      This1 ) )

(test
   (list
      '((N)
         (+ (inc 'X N) (inc 'Y (* 2 N))))
      '((N)
         (+ (inc 'Y (* 3 N)) (inc 'Z (* 4 N)))) )
   (let X 1
      (let Y 2
         (let Z 3
            (let [some-p! (@p! (N) (X Y) (+ (inc 'X N) (inc 'Y (* 2 N))))
                  some-other-p! (@p! (N) (Y Z) (+ (inc 'Y (* 3 N)) (inc 'Z (* 4 N))))]
               (with-p!s [some-p!       (This)
                          some-other-p! (This)]
                  (list This1 This2) ) ) ) ) ) )

# test 'P[1]' anaphors
(test 62
   (prog
      (with-p!s [p!-test (This X)]
         (P!1 3) )
      (p!-test "get" 'X) ) )

(test (11 111 1111)
   (let (X 1 Y 101 Z 1101)
      (let [p!-1 (@p! (N) (X) (inc 'X N))
            p!-2 (@p! (N) (Y) (inc 'Y N))
            p!-3 (@p! (N) (Z) (inc 'Z N))]
         (with-p!s  [p!-1 (This X)  # -> P!1
                     p!-2 (This Y)  # -> P!2
                     p!-3 (This Z)] # -> P!3
            (mapc '((P) (P 10)) '(P!1 P!2 P!3))
            (mapcar '((P V) (P "get" V)) '(P!1 P!2 P!3) '(X Y Z))) ) ) )

# test '[Var]$[N]' anaphors
(test (2 12)
   (let (X 1 Y 2)
      (let p!-1 (@p! (N) (X Y) (+ (inc 'X N) (inc 'Y (* 2 N))))
         (let (Y 12 Z 13)
            (let p!-2 (@p! (N) (Y Z) (+ (inc 'Y (* 3 N)) (inc 'Z (* 4 N))))
               (with-p!s [p!-1 (X Y)
                          p!-2 (Y Z)]
                  (list Y$1 Y$2) ) ) ) ) ) )

# test 'setp' within 'with-p!s'
(test (22 1212)
   (let (X 1 Y 2)
      (let p!-1 (@p! (N) (X Y) (+ (inc 'X N) (inc 'Y (* 2 N))))
         (let (Y 12 Z 13)
            (let p!-2 (@p! (N) (Y Z) (+ (inc 'Y (* 3 N)) (inc 'Z (* 4 N))))
               (with-p!s [p!-1 (X Y)
                          p!-2 (Y Z)]
                  (setp Y$1 22)
                  (setp Y$2 1212) )
               (list (p!-1 "get" 'Y) (p!-2 "get" 'Y)) ) ) ) ) )

# make sure the global env stays clean
(test T
   (fully '((X) (= NIL X))
      (list State Cnt X Y Z Y-1 Y-2 This This1 This2 This3 D! P! P!1 P!2 P!3 p!-1 p!-2 p!-3 Self) ) )

# and it's good to go
(t (prinl "passed all tests"))

]
