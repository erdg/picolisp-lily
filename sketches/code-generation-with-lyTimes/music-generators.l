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
