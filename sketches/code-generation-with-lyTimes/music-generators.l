(de random-element (Lst)
   (car (nth Lst (rand 1 (length Lst)))) )

(de random-duration ()
   (random-element (1 2 4 8 16 32 64 128)) )

(de random-note ()
   (pack
      (random-element '(a b c d e f g))
      (random-element '("" "is" "es")) ) )

# a,,, to c'''''
(de random-octave ()
   (random-element '(",,," ",," "," "" "'" "''" "'''" "''''" "'''''")) )

# (random-octave-from-range 0 2) -> NIL | "'" | "''"
#
# (random-octave-from-range -3 5) -> ",,," ",," ... NIL "'" "''" ...  "'''''"
#
# (random-octave-from-range 2 -2) -> undefined
#
(de random-octave-from-range (Lo Hi)
   (random-element
      (make
         (for N (range Lo Hi)
            (link
               (cond
                  ((lt0 N) (pack (need N ",")))
                  ((=0 N) "")
                  ((gt0 N) (pack (need N "'"))) ) ) ) ) ) )

(de octave-ring ()
   (circ ",,," ",," "," "" "'" "''" "'''" "''''" "'''''") )

(de octave-ring-from-range (Lo Hi)
   (circ
      (make
         (for N (range Lo Hi)
            (link
               (cond
                  ((lt0 N) (pack (need N ",")))
                  ((=0 N) "")
                  ((gt0 N) (pack (need N "'"))) ) ) ) ) ) )

# note + octave
(de random-pitch ()
   (case (random-octave)
      (",,," (pack (random-element '("a" "ais" "bes" "b")) @)) # lowest 3 notes on piano
      ("'''''" (pack "c" @)) # highest c
      (T (pack (random-note) @)) ) ) # the rest

(de random-pitch-from-octave-range (Lo Hi)
   (case (random-octave-from-range Lo Hi)
      (",,," (pack (random-element '("a" "ais" "bes" "b")) @)) # lowest 3 notes on piano
      ("'''''" (pack "c" @)) # highest c
      (T (pack (random-note) @)) ) ) # the rest

(de random-pitch-from-list (Lst)
   (case (random-element Lst)
      ('("a" "ais" "bes" "b") (pack @ (random-element '(",,," ",," "," "" "'" "''" "'''" "''''"))))
      ("c" (pack @ (random-element '(",," "," "" "'" "''" "'''" "''''" "'''''"))))
      (T (pack @ (random-element '(",," "," "" "'" "''" "'''" "''''")))) ) )

(de random-dot ()
   (random-element '("." ".." "..." "....")) )

(de dotted-duration-complement (Dur) # in 4/4
   (case Dur
      ("2." 4)
      ("2.." 8)
      ("2..." 16)
      ("2...." 32)
      ("4." 8)
      ("4.." 16)
      ("4..." 32)
      ("4...." 64)
      ("8." 16)
      ("8.." 32)
      ("8..." 64)
      ("16." 32)
      ("16.." 64)
      ("32." 64) ) )

# scales n stuff
(de chromatic-scale-ascending-sharps ()
   (list "c" "cis" "d" "dis" "e" "f" "fis" "g" "gis" "a" "ais" "b") )

(de chromatic-scale-descending-sharps ()
   (rot (reverse (chromatic-scale-ascending-sharps)) ) )

(de chromatic-scale-ascending-flats ()
   (list "c" "des" "d" "ees" "e" "f" "ges" "g" "aes" "a" "bes" "b") )

(de chromatic-scale-descending-flats ()
   (rot (reverse (chromatic-scale-ascending-flats)) ) )

# first attempt
#
# (de c-major-scale ()
#    (make
#       (for N '(1 3 5 6 8 10 12)
#          (link
#             (nthcar N (chromatic-scale-ascending-sharps)) ) ) ) )
#
# many scales to generate, write a function
#
# first draft
# (de make-major-scale (Base)
#    (make
#       (for N '(1 3 5 6 8 10 12)
#          (link
#             (nthcar N Base) ) ) ) )
#
# now can write
#
# (de c-major-scale () (make-major-scale 1 (chromatic-scale-ascending-sharps)))
#
# that's better, how about the next few scales?
#
# (de des-major-scale ()
#    (make-major-scale
#       (nth
#          (ring-from-list (chromatic-scale-ascending-flats))  NOTE - flats
#          2 ) ) )
#
# (de d-major-scale ()
#    (make-major-scale
#       (nth
#          (ring-from-list (chromatic-scale-ascending-sharps)) NOTE - sharps
#          3 ) ) )
#
# (de ees-major-scale ()
#    (make-major-scale
#       (nth
#          (ring-from-list (chromatic-scale-ascending-flats))  NOTE - flats
#          4 ) ) )
#
# another pattern, another function

# final draft
(de make-major-scale (Offset Base)
   (make
      (for N '(1 3 5 6 8 10 12)
         (link
            (nthcar N (nth (ring-from-list Base) Offset)) ) ) ) )

# (de des-major-scale ()
#    (make-major-scale 2 (chromatic-scale-ascending-flats)) )  NOTE - flats
#
# (de ees-major-scale ()
#    (make-major-scale 4 (chromatic-scale-ascending-flats)) )  NOTE - sharps
#
# (de e-major-scale ()
#    (make-major-scale 5 (chromatic-scale-ascending-sharps)) ) NOTE - flats
#
# ...
#
# another pattern, another function

# first draft
#
# (de make-all-major-scales ()
#    (for @N 12
#       (let
#          @Base
#          (case (% @N 2)
#             (0 'chromatic-scale-ascending-flats)
#             (T 'chromatic-scale-ascending-sharps) )
#          (macro
#             (de ^(list (any (pack (nthcar @N (@Base)) "-major-scale"))) NIL
#                (make-major-scale @N (@Base)) ) ) ) ) )
#
# this is technically correct but some scales have "incorrect" note names - like
# b-flat-major as a-sharp-major, e.g. ("ais" "c" "d" "dis" "f" "g" "a"). no one
# can write/read music like that.

# solution is to swap the base scales halfway (i.e. at f-sharp, halfway around the circle of 5ths)

# final draft
(de make-all-major-scales ()
   (for @N 12
      (let
         @Base
         (case (% @N 2)
            # swap scales
            (0 (if (< @N 7) 'chromatic-scale-ascending-flats 'chromatic-scale-ascending-sharps))
            (T (if (< @N 7) 'chromatic-scale-ascending-sharps 'chromatic-scale-ascending-flats)) )
         (macro
            (de ^(list (any (pack (nthcar @N (@Base)) "-major-scale"))) NIL
               (make-major-scale @N (@Base)) ) ) ) ) )

# utils
(de nthcar (N Lst)
   (car (nth Lst N)) )

(de ring-from-list (Lst)
   (macro (circ ^ Lst)) )
