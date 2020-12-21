(load "../../pond.l")

[de code-gen-2 ()
   (do 4
      (let @N (rand 5 9)
         (macro
            (lyTimes (pack "4/" @N)
               ^(make
                  (do @N
                     (link
                        (pack
                           (random-pitch-from-list '("f" "g" "aes" "bes" "c" "ees"))
                           8 ) ) ) ) ) ) ) ) ]


(de render-code-gen-2 () 
   (lilypond "code-gen-2" 
      (lyWrap 
         (do 8 (code-gen-2)) ) ) )

# (de random-duration% () 
#    (car (nth (1 2 4 8 16 32) (rand 1 6))))

# (de random-note% ()
#    (pack 
#       (car (nth '(a b c d e f g) (rand 1 7)))
#       (car (nth '("" "is" "es") (rand 1 2))) ) )

# (de random-octave% () (car (nth '(",," "," "" "'" "''" "'''") (range 1 6))))

(de random-element (Lst)
   (car (nth Lst (rand 1 (length Lst)))) )

(de random-duration ()
   (random-element (1 2 4 8 16 32 64 128)) )

(de random-note-name ()
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


# need to decide on notation

# # chords [root]:[type]
# (de  f:min|notes () (list "f" "aes" "c"))
# (de f:min7|notes () (list "f" "aes" "c" "ees"))
# (de  f:dim|notes () (list "f" "aes" "b"))
# (de f:dim7|notes () (list "f" "aes" "b" "d"))
# (de    f:7|notes () (list "f" "a" "c" "ees"))

# (de f:maj13.+11 ())

# (de c:maj ())
# (de c:maj7 ())
# (de c:maj+ ())
# (de c:maj7.+ ())

# (de c:min () (list "c" "ees" "g"))
# (de c:min7 () (list "c" "ees" "g" "bes"))
# (de c:min13 () (list "c" "ees" "g" "bes" "d" "f" "a"))
# (de c:min11.-13 ())

# # scales [root]-[type]
# (de  f-min|notes () (list "f" "g" "aes" "bes" "c" "des" "ees")) # natural minor
# (de f-min7|notes () (list "f" "g" "aes" "bes" "c" "d" "ees")) # dorian

# (de  f:min|ring () (circ "f" "aes" "c") )
# (de  f:min|ring () (circ "f" "aes" "c") )
# (de  f:maj|ring () (circ "f" "a" "c") )
# (de f:maj7|ring () (circ "f" "a" "c" "e") )
