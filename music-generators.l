### utils
(de nthcar (N Lst)
   (car (nth Lst N)) )

(de ring-from-list (Lst)
   (macro (circ ^ Lst)) )
###

(de random-element (Lst)
   (car (nth Lst (rand 1 (length Lst)))) )

(de random-duration ()
   (random-element (1 2 4 8 16 32 64 128)) )

# shortest duration
(de random-duration-min (Min)
   (let Ds (reverse (1 2 4 8 16 32 64 128))
      (random-element
         (nth Ds (index Min Ds)) ) ) )

# longest duration
(de random-duration-max (Max)
   (let Ds (1 2 4 8 16 32 64 128)
      (random-element
         (nth Ds (index Max Ds)) ) ) )

(de random-duration-range (X Y)
   (let Ds (1 2 4 8 16 32 64 128)
      (random-element
         (sect
            (nth Ds (index X Ds))
            (head (index Y Ds) Ds) ) ) ) )

(de random-duration-from (Lst)
   (random-element Lst) )

# (random-measure-of-durations)
# (random-measure-of-durations "17/16")
(de random-measure-of-durations (Time)
   (default Time "4/4")
   (let [Lst  (mapcar '((L) (any (pack L))) (split (chop Time) "/"))  # e.g. "17/16" -> (17 16)
         Full (* (car Lst) (duration-as-128th-notes (cadr Lst)))      # length of measure as 128th notes
         Curr 0 ]  # current count of 128th notes as measure is built
      (make
         (loop
            (T (= Curr Full))
            (let
               [Dur  # pick random duration from duration table
                  (random-element
                     (filter
                        '((D) (<= (cdr D) (- Full Curr)))
                        *duration-as-128th-notes-table*)) ]
               (link (car Dur))
               # increment the current count
               (inc 'Curr (cdr Dur)) ) ) ) ) )

(de duration-as-128th-notes (D)
   (let [C    (chop D)
         Ds (1 2 4 8 16 32 64 128)
         Dur  (any (pack (filter '((N) (num? (any N))) C)))
         Dots (filter '((X) (= X ".")) C) ]
      (macro  # gotta be a simpler way to do this
         (apply +
            (list
               # 128th-note value of base duration (e.g. "2" in "2..")
               (nthcar (index Dur Ds) (reverse Ds))
               # 128th-note value of dots
               ^(make
                  (for Dot (length Dots)
                     (link
                        (nthcar (+ (index Dur Ds) Dot) (reverse Ds)) ) ) ) ) ) ) ) )

(setq *duration-as-128th-notes-table*
   (filter fin
      (make
         (for Dur (1 2 4 8 16 32 64 128)
            (for Dot '("" "." ".." "..." "...." "....." "......" ".......")
               (let It (pack Dur Dot)
                  (link (cons It (duration-as-128th-notes It))) ) ) ) ) ) )
###

###
# (map-random-notes-from-list-to-durations
#    (with-flats (des-lydian-scale))
#    (make (do 8 (chain (random-measure-of-durations "7/8")))) )
#
(de map-random-notes-from-list-to-durations (Notes Durations)
   (mapcar
      '((D) (pack (random-element Notes) D))
      Durations ) )
###

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
   (random-element '("." ".." "..." "...." "....." "......" ".......")) )

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
#
# first draft
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
#
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

# expanding on this idea...

# make-all-scales-of-type
#
# technically correct again, but weird strange scale names/notes, e.g.
#
#   (des-dorian-scale) -> ("des" "ees" "e" "ges" "aes" "bes" "b")
#
# which should be 'cis-dorian-scale', with sharps instead of flats.
# probably will need to rewrite based on circle of fifths...
(de make-all-scales-of-type (Name @Pattern)
   (for @N 12
      (let
         @Base
         (case (% @N 2)
            # swap scales
            (0 (if (< @N 7) 'chromatic-scale-ascending-flats 'chromatic-scale-ascending-sharps))
            (T (if (< @N 7) 'chromatic-scale-ascending-sharps 'chromatic-scale-ascending-flats)) )
         (macro
            (de ^(list (any (pack (nthcar @N (@Base)) "-" Name "-scale"))) NIL
               (make-scale-from-pattern-list @Pattern @N (@Base)) ) ) ) ) )

# here we go!
(de circle-of-fifths ()
   (circ
      "c"                  # 1
      "g"                  # 2
      "d"                  # 3
      "a"                  # 4
      "e"                  # 5
      (cons "b"   "ces")   # 6
      (cons "fis" "ges")   # 7
      (cons "cis" "des")   # 8
      (cons "gis" "aes")   # 9
      (cons "dis" "ees")   # 10
      (cons "ais" "bes")   # 11
      "f" ) )              # 12

### circle of fifths patterns
# major scale -> (1 3 5 12 2 4 6)
# dorian scale -> (1 3 10 12  2 4 11)

(de make-scale-from-pattern-list (Pattern Offset Base)
   (make
      (for N Pattern
         (link
            (nthcar N (nth (ring-from-list Base) Offset)) ) ) ) )

(de make-scale-from-pattern-ring (Pattern Offset Base)
   (make
      (for N Pattern
         (link
            (nthcar N (nth Base Offset)) ) ) ) )

(de make-all-scales-of-type-from-circle-of-fifths (Name @Pattern)
   (for @N 12
      (let (@Base 'circle-of-fifths
            @Note (nthcar @N (@Base)) )
         (ifn (pair @Note)
            # e.g. (de c-major-scale ...)
            (macro
               (de ^(list (any (pack @Note "-" Name "-scale"))) NIL
                  (make-scale-from-pattern-ring @Pattern @N (@Base)) ) )
               # else make scale for sharp/flat, e.g. (de fis-major-scale ...)/(de ges-major-scale)
            (macro
               (de ^(list (any (pack (car @Note) "-" Name "-scale"))) NIL
                  (make-scale-from-pattern-ring @Pattern @N (@Base)) ) )
            (macro
               (de ^(list (any (pack (cdr @Note) "-" Name "-scale"))) NIL
                  (make-scale-from-pattern-ring @Pattern @N (@Base)) ) ) ) ) ) )

# (de circle-of-fifths ()
#    (circ
#       "c"                  # 1
#       "g"                  # 2
#       "d"                  # 3
#       "a"                  # 4
#       "e"                  # 5
#       (cons "b"   "ces")   # 6
#       (cons "fis" "ges")   # 7
#       (cons "cis" "des")   # 8
#       (cons "gis" "aes")   # 9
#       (cons "dis" "ees")   # 10
#       (cons "ais" "bes")   # 11
#       "f" ) )              # 12

(de make-all-scales ()
   (let Lyd (1 3 5 7 2 4 6) # lydian prototype
      (for Scale
         [list
            (cons "lydian" Lyd)
            (cons "major" (1 3 5 12 2 4 6))
            (cons "minor" (1 3 10 12 2 9 11))
            (cons "wholetone" (1 3 5 7 9 11))
            # FIXME - need to generate all scales variants for a certain pitch
            # instead of all pitch variants for a certain scale
            # (cons "phrygian"   (rot Lyd))
            # (cons "dorian"     (rot Lyd))
            # (cons "major"      (rot Lyd))
            # (cons "locrian"    (rot Lyd))
            # (cons "minor"      (rot Lyd))
            # (cons "mixolydian" (rot Lyd))
         ]
         (make-all-scales-of-type-from-circle-of-fifths (car Scale) (cdr Scale)) ) ) )

# scale helpers
(de with-sharps (Scale)
   (mapcar
      '((Note) (if (pair Note) (car @) Note))
      Scale ) )

(de with-flats (Scale)
   (mapcar
      '((Note) (if (pair Note) (cdr @) Note))
      Scale ) )

