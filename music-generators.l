### utils
(de nthcar (N Lst)
   (car (nth Lst N)) )

(de ring-from-list (Lst)
   (macro (circ ^ Lst)) )

### will this get used?
#
# (map-generator
#    '(random-octave-from-range 1 3)      # generator (quoted)
#     (with-flats (des-lydian-scale)) )
#
# (let L '("f" "a" "bes" "c'")
#    (map-generator
#       '(++ L)
#       (make-rhythms "2." 8 (4 . 16)) ) )
#
(de map-generator ("Gen" Lst)
   (make
      (for "L" Lst
         (link (pack (eval "Gen") "L") ) ) ) )
###

#####
#
#  (map-notes '("a" "b" "c") ...) -> apply 'random-element'
#  (map-notes (circ "a" "b" "c") ...) -> apply '++'
#
#  these seem to be the two most common patterns currently
#  used, might as well make a function
#
(de map-notes (Ns Lst)
   (map-generator
      (if (circ? Ns)
         '(++ Ns)
         '(random-element Ns) )
      Lst ) )

(de random-element (Lst)
   (car (nth Lst (rand 1 (length Lst)))) )

# no back to back repeats
(de random-element-no-repeats (Lst)
   (job '(("Last" . NIL))
      (recur ()
         (let It (random-element Lst)
            (if (= It "Last")
               (recurse)
               (setq "Last" It) ) ) ) ) )

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

###
# (random-measure-of-durations)
# (random-measure-of-durations "17/16")
(de random-measure-of-durations (Time)
   (default Time "4/4")
   (let [Lst  (mapcar '((L) (any (pack L))) (split (chop Time) "/"))  # e.g. "17/16" -> (17 16)
         Full (* (car Lst) (duration-as-128th-notes (cadr Lst)))      # length of measure as 128th notes
         Curr 0
         ]  # current count of 128th notes as measure is built
      (make
         (loop
            (T (= Curr Full))
            (let
               [Dur  # pick random duration from duration table
                  (random-element
                     (filter  # that fits in remaining space of measure
                        '((D) (<= (cdr D) (- Full Curr)))
                     *duration-as-128th-notes-table*))
                  ]
               # add it to the measure
               (link (car Dur))
               # increment count of current measure
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

(de chord-inversions (Notes)
   (fish atom
      (make
         (link Notes)
         (for N (- (length Notes) 1)
            (link (append (tail (- N) Notes) (head N Notes))) ) ) ) )

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

(de make-octaves Lst
   (make
      (for L Lst
         (do (car L) (link (cdr L))) ) ) )

#  (octave-tick-to-number "''") -> 2
#  (octave-tick-to-number ",") -> -1
(de octave-tick-to-number (Tick)
   (ifn Tick
      0
      (let Len (length Tick)
         (if (pre? "'" Tick)
            Len
            (- Len) ) ) ) )

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

(de chromatic-scale ()
   (list
      "c"
      (cons "cis" "des")
      "d"
      (cons "dis" "ees")
      "e"
      "f"
      (cons "fis" "ges")
      "g"
      (cons "gis" "aes")
      "a"
      (cons "ais" "bes")
      "b" ) )

# all pitches (on piano)
(setq *all-pitches*
   (make
      (link "a,,,")
      (link (cons "ais,,," "bes,,,"))
      (link "b,,,")
      (for Oct '(",," "," "" "'" "''" "'''" "''''")
         (mapcar
            '((Note)
               (if (pair Note)
                  (link (cons (pack (car @) Oct) (pack (cdr @) Oct)))
                  (link (pack Note Oct)) ) )
            (chromatic-scale) ) )
      (link "c'''''") ) )

(de index-of-pitch (Pitch)
   (for (I . P) *all-pitches*
      (T
         (if (atom P)
            (= Pitch P)
            (or (= Pitch (car P)) (= Pitch (cdr P))) )
         I ) ) )

# NOTE - the following two functions should probably be implemented as
# a class. That way it could be instantiated with a new starting note
# each time it is called, the 'Last' note wouldn't carry over from the
# previous set of calls, etc.

# this kinda works, but the results are rather uninspiring.
(de random-pitch-within-n-semitones (N Start)
   (job '((Last . NIL))
      (ifn Last
         (setq Last (or Start (random-pitch)))
         (let Idx (index Last *all-pitches*)
            (setq Last
               (random-element
                  (fish atom
                     (head (* 2 N)
                        (tail (+ (- Idx) N)
                           *all-pitches* ) ) ) ) ) ) ) ) )

#  (random-pitch-within-n-steps 4 (with-flats (c-dorian-scale)))
#
# this also kinda works, but "within n steps" is not always obeyed.
# works best with small values of N.
(de random-pitch-within-n-steps (N Lst Start)
   (job '((Last . NIL))
      (ifn Last
         (setq Last (or Start (random-element Lst)))
         (let Idx (index Last Lst)
            (setq Last
               (random-element
                  (uniq
                     (filter '((X) (not (= X Last)))
                        (append
                           (tail N (head N Lst))
                           (head N (nth Lst N)) ) ) ) ) ) ) ) ) )

(de random-dot ()
   (random-element '("." ".." "..." "...." "....." "......" ".......")) )

# (make-ly-times 4 7 8 random-element '("a" "b" "c"))
# (make-ly-times 4 5 4 ++ (ring-from-list (with-flats (des-lydian-scale))))
(de make-ly-times (@X @Y @D @Fn @Notes)
   # --- "in the space of @X @D-notes put @Y @D-notes, chosen by @Fn from @Notes" ---
   # @X - numerator, e.g. "4" in "4/5"
   # @Y - denominator, e.g. "5" in "4/5
   # @D - duration of notes, e.g 16th-notes
   # @Fn - function to select note from @Notes, e.g. '++' or 'random-element'
   # @Notes - notes to choose from, take care to use a list or ring appropriately,
   #          i.e. '++' rings and pick 'random-element's from a list
   (macro
      (lyTimes (pack @X "/" @Y)
         ^(make
            (do @Y
               (link
                  (pack
                     (@Fn @Notes)
                     @D ) ) ) ) ) ) )

# NOTE - this is my current favorite
# (make-ly-times-alt 4 5 (mapcar '((R) (pack (random-element '("a" "b" "c")) R)) (random-rhythms "5/4")))
# (make-ly-times-alt 2 3 (mapcar '((R) (pack (random-element '("a" "b" "c")) R)) (random-rhythms "3/2" 8 "...")))
(de make-ly-times-alt (@X @Y @Music)
   # @Music - e.g. (mapcar '((R) (pack (random-element '("a" "b" "c")) R)) (random-rhythms "4/4"))
   (macro
      (lyTimes (pack @X "/" @Y)
         (prinl "\\once \\override TupletNumber.text = #(tuplet-number::non-default-tuplet-fraction-text "@Y" "@X")")
         ^(make
            (for M @Music
               (link
                  M ) ) ) ) ) )

(de make-ly-times-random-rhythms (@X @Y @R @Fn @Notes)
   (let @Rhythms (random-rhythms (pack @Y "/" @R) @R)
      (macro
         (lyTimes (pack @X "/" @Y)
            (prinl "\\once \\override TupletNumber.text =
               #(tuplet-number::non-default-fraction-with-notes "@Y" \""@R"\" "@X" \""@R"\")")
            ^(make
               (for R @Rhythms
                  (link
                     (pack
                        (@Fn @Notes)
                        R ) ) ) ) ) ) ) )

(de make-ly-times-random-rhythms% (@X @Y @A @B @Fn @Notes)
   # --- "put @X @Y-notes in the space of @A @B-notes" ---
   #   e.g put 17 16th-notes in the space of 5 8th-notes
   (let @Rhythms (random-rhythms (pack @X "/" @Y) @Y)
      (macro
         (lyTimes (pack @A "/" @X)
            (prinl "\\once \\override TupletNumber.text =
               #(tuplet-number::non-default-fraction-with-notes "@X" \""@Y"\" "@A" \""@B"\")")
            ^(make
               (for R @Rhythms
                  (link
                     (pack
                        (@Fn @Notes)
                        R ) ) ) ) ) ) ) )

# (make-ly-tuplet 7 4 8 random-element '("a" "b" "c"))
# (make-ly-tuplet 3 2 8 ++ (ring-from-list (with-flats (des-lydian-scale))))
(de make-ly-tuplet (@X @Y @D @Fn @Notes)
   # --- "@X over @Y @D-notes, chosen by @Fn from @Notes" ---
   # @X - numerator
   # @Y - denominator
   # @D - duration of notes, e.g 16th-notes
   # @Fn - function to select note from @Notes, e.g. '++' or 'random-element'
   # @Notes - notes to choose from, take care to use a list or ring appropriately,
   #          i.e. '++' rings and pick 'random-element's from a list
   (macro
      (lyTuplet (pack @X "/" @Y)
         ^(make
            (do @X
               (link
                  (pack
                     (@Fn @Notes)
                     @D ) ) ) ) ) ) )


### it "works" but results are undesirable. use 'make-ly-times-alt' instead
# (make-ly-tuplet-alt 4 5 (mapcar '((R) (pack (random-element '("a" "b" "c")) R)) (random-rhythms "5/4")))
# (make-ly-tuplet-alt 2 3 (mapcar '((R) (pack (random-element '("a" "b" "c")) R)) (random-rhythms "3/2" 8 "...")))
(de make-ly-tuplet-alt (@X @Y @R @Music)
# @Music - e.g. (mapcar '((R) (pack (random-element '("a" "b" "c")) R)) (random-rhythms "4/4"))
   (macro
      (lyTuplet% (pack @X "/" @Y) @R
         # (prinl "\\once \\override TupletNumber.text = #(tuplet-number::non-default-tuplet-fraction-text "@Y" "@X")")
         ^(make
            (for M @Music
               (link
                  M ) ) ) ) ) )

###
# i want a function that makes crazy ly-times, like 'random-measure-of-durations'
# for ly-times need to keep track of 128th-note duration of the times, and fill
# with random stuff...

# this "works", but is not contained by the duration 'N'. crazy nonsense
# scores. i would like slightly less nonsense
(de random-ly-times (N @Fn @Notes) # N = 2 -> a half-note filled with crazy ly-times
# |
# V
# - generate random make-ly-times call, e.g (make-ly-times 13 17 64 ...) -> in
#   space of 13, put 17 64th-notes.
# - calculate 128th-note time for this call, e.g. (* @X (128th-note-value @D)), increment 'Curr'
# - fill with crazy randomness via 'random-measure-of-durations', e.g
#   '(random-measure-of-durations "13/64")' should work
# - map durations to notes
# - fill notes in ly-times-call
# - repeat with another random make-ly-times call that fits within '(- Full Curr)'
#
# - probably needs to use note rings
   (let [Full (duration-as-128th-notes N) Curr 0]
      (make
         (loop
            (T (>= Curr Full))
            (let [@X (rand 1 100)
                  @Y (rand 1 100)
                  D (random-element (nth (base-note-durations) (+ (index N (base-note-durations)) 1)))
                  Dur (* @X (duration-as-128th-notes D))
                  @Rhythms (random-rhythms (pack @X "/" D) N "...")
                  ]
               # (make-ly-times ...)
               (link
                  (macro
                     (lyTimes (pack @X "/" @Y)
                        ^(make
                           # map random-rhythms to notes
                           (for R @Rhythms
                              (link
                                 (pack
                                    (@Fn @Notes)
                                    R ) ) ) ) ) ) )
               # increment count of current measure
               (inc 'Curr Dur) ) ) ) ) )

(de base-note-durations () (list 1 2 4 8 16 32 64 128))

# (random-rhythms "4/4" 2 "..") -> measure of 4/4 with rhythms of "2.." or less
(de random-rhythms (Time MaxDur MaxDot)
   (default Time "4/4")
   (default MaxDur 1)
   (default MaxDot ".")
   (let [Lst  (mapcar '((L) (any (pack L))) (split (chop Time) "/"))  # e.g. "17/16" -> (17 16)
         Full (* (car Lst) (duration-as-128th-notes (cadr Lst)))      # length of measure as 128th notes
         Curr 0  # current count of 128th notes as measure is built
         Avail
            (filter  # no durations larger than max
               '((L) (>= (any (pack (split (chop (car L)) "."))) MaxDur))
               (filter  # no dots more than max
                  '((L) (not (sub? MaxDot (car L))))
                  *duration-as-128th-notes-table* ) )  # <- (("2" . 64) ... ("4." . 48))
         ]
      (make
         (loop
            (T (= Curr Full))
            (let Dur
               (random-element   # pick random-element from available durations
                  (filter        # that fits in remaining space of measure
                     '((D) (<= (cdr D) (- Full Curr)))
                     Avail ) )
               (link (car Dur))  # add it to the measure
               (inc 'Curr (cdr Dur)) ) ) ) ) )  # increment count of current measure


###
# (random-rhythms "4/4" 2 "..") -> measure of 4/4 with rhythms of "2." or less
# (random-rhythms "4/4" (4 16 64)) -> measure with durations 4/16/64
(de random-rhythms% (Time MaxDur MaxDot)
   (default Time "4/4")
   (default MaxDur 1)
   (default MaxDot ".")
   (let [Lst  (mapcar '((L) (any (pack L))) (split (chop Time) "/"))  # e.g. "17/16" -> (17 16)
         Full (* (car Lst) (duration-as-128th-notes (cadr Lst)))      # length of measure as 128th notes
         Curr 0  # current count of 128th notes as measure is built
         FilteredDots
            (filter  # no dots more than max
               '((L) (not (sub? MaxDot (car L))))
               *duration-as-128th-notes-table* )
         Avail
            # if MaxDur is a list, take only those durations
            (if (pair MaxDur)
               (make
                  (for N MaxDur
                     (chain
                        (filter  # no durations larger than max
                           '((L)
                              (=
                                 (if (str? N)
                                    (car L)
                                    (any (pack (split (chop (car L)) "."))) )
                                 N) )
                           FilteredDots ) ) ) )  # <- (("2" . 64) ... ("4." . 48))
               (filter  # no durations larger than max
                  '((L) (>= (any (pack (split (chop (car L)) "."))) MaxDur))
                   FilteredDots ) )
         ]
      (make
         (loop
            (T (= Curr Full))
            (let
               Dur
               (or
                  (random-element   # pick random-element from available durations
                     (filter        # that fits in remaining space of measure
                        '((D) (<= (cdr D) (- Full Curr)))
                        Avail ) )
                  (random-element   # pick random-element from available durations
                     (filter        # that fits in remaining space of measure
                        '((D) (<= (cdr D) (- Full Curr)))
                        *duration-as-128th-notes-table* ) ) )
               (link (car Dur))  # add it to the measure
               (inc 'Curr (cdr Dur)) ) ) ) ) )  # increment count of current measure

###
# (random-rhythms-from "4/4" (4 "4." 8 16)) -> measure with durations 4/"4."/8/16
#
# NOTE - this can also be used to "apply weights" to the randomness, e.g.
#
#    (random-rhythms-from "13/16" (4 8 16 16 16 16))
#
# will pick more 16th-notes as it will result in 4x as many in the 'Avail'able list
(de random-rhythms-from (Time Ds)
   # Time - time signature/total duration of desired rhythms
   # Ds   - allowed durations
   (default Time "4/4")
   (default Ds (1 2 4 8 16 32 64 128))
   (let [Lst  (mapcar '((L) (any (pack L))) (split (chop Time) "/"))  # e.g. "17/16" -> (17 16)
         Full (* (car Lst) (duration-as-128th-notes (cadr Lst)))      # length of measure as 128th notes
         Curr 0  # current count of 128th notes as measure is built
         Avail
            (make
               (for D Ds
                  (chain
                     (filter
                        '((L) (= (car L) (pack D)))
                        *duration-as-128th-notes-table* ) ) ) )  # <- (("2" . 64) ... ("4." . 48))
         ]
      (make
         (loop
            (T (= Curr Full))
            (let
               Dur
               (or
                  (random-element   # pick random-element from AVAILABLE durations
                     (filter        # that FITS in remaining space of measure
                        '((D) (<= (cdr D) (- Full Curr)))
                        Avail ) )
                  # NOTE - these clauses are so the function doesn't hang
                  # -----------------------------------------------------
                  (random-element   # pick random-element from ALL durations
                     (filter        # that USES remaining space of measure
                        '((D) (= (cdr D) (- Full Curr)))
                        *duration-as-128th-notes-table* ) )
                  (random-element   # pick random-element from ALL durations
                     (filter        # that FITS IN remaining space of measure
                        '((D) (<= (cdr D) (- Full Curr)))
                        *duration-as-128th-notes-table* ) ) )
               (link (car Dur))  # add it to the measure
               (inc 'Curr (cdr Dur)) ) ) ) ) )  # increment count of current measure

#####
#
#  (make-rhythms "4." 8 (2 . 4))    -> dotted 1/4-note, 8th-note, 2 quarter notes
#  (make-rhythms (T "3/2" 8))       -> 8th-note triplets
#  (make-rhythms (4 . (T "3/2" 8))  -> 4 sets 8th-note triplets
#  (make-rhythms                    -> 4 measures of random rhythms
#     (4 . (random-rhythms "4/4"))
#  (make-rhythms                    -> entire pattern repeated twice
#     (2 . ((T "3/2" 8) (T "5/4" 16) (T "3/2" 8)))
#
(de make-rhythms Lst
   (make
      (for L Lst
         (cond
            # N | "N.[...]"
            ((atom L) (link L) )
            # (N . ...) -- repeats
            ((num? (car L))
               (cond
                  # (4 . 16) -> 16 16 16 16
                  ((num? (cdr L))
                     (do (car L) (link (cdr L))) )
                  # (2 . (T "3/2" 8)) -> (T "3/2" 8 8 8) (T "3/2" 8 8 8)
                  ((atom (cadr L))
                     (macro
                        (do (car L)
                           (chain (make-rhythms ^(list (cdr L)))) ) ) )
                  # (2 . ((T "3/2" 8) (T "5/4 16))) -> 2x (T "3/2" 8 8 8) (T "5/4" 16 16 16 16 16)
                  (T (do (car L) (macro (chain (make-rhythms ^(cdr L)))))) ) )
            # (T "X/Y" N) -- tuplets/times
            ((=T (car L))
               (link
                  (make
                     (link T)
                     (link (cadr L))
                     (chain (need (any (caar (split (chop (cadr L)) "/"))) (caddr L)))) ) )
            # function call
            (T (chain (eval L)) ) ) ) ) )

#####
#
# (pack-rhythms
#    '(random-element (with-sharps (d-major-7-chord)))
#    (make-rhythms
#       (2 .
#          (T "3/2" 8)
#          (2 . (T "5/4" 16) ) ) ) )
#
# combine rhythms from 'make-rhythms' with notes from a list or note generator
# function
#
(de pack-rhythms (G Lst)
   # G - music generator, see example above
   # Lst - list of rhythms
   (make
      (for "L" Lst
         (cond
            ((atom "L") (link (pack (eval G) "L")))
            (T
               (link
                  (make
                     (link T)
                     (link (cadr "L"))
                     (for X (cddr "L") (link (pack (eval G) X))) ) ) ) ) ) ) )

#####
#
# (make-melody
#    (pack-rhythms
#       '(random-pitch-from-octave-range 0 2)
#       (make-rhythms (2 . ((T "3/2" 8) (2 . (T "5/4" 16)) (T "3/2" 8)))) ) )
#
# combine notes with a list of rhythms and create a melody/arpeggio.
# this function should auto-generate tuplets, likely via 'macro' that
# creates a 'lyWrap'ed list with whatever is needed
#
(de make-melody (Lst)
   (macro
      (lyWrap
         ^(make
            (for L Lst
               (if (atom L)
                  (link L)
                  # tuplets
                  (link (cons 'lyTuplet (cdr L)))) ) ) ) ) )

# same as above, but returns an unevaluted list. possibly useful for debugging.
(de make-melody% (Lst)
   (make
      (link 'lyWrap)
      (for L Lst
         (if (atom L)
            (link L)
            # tuplets
            (link (cons 'lyTuplet (cdr L)))) ) ) )

###
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

(de list-of-fifths ()
   (list
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
   (for Scale
         [list
         (cons "lydian" (1 3 5 7 2 4 6))
         (cons "major" (1 3 5 12 2 4 6))
         (cons "mixolydian" (1 3 5 13 2 4 11))
         (cons "dorian" (1 3 10 12 2 4 11))
         (cons "minor" (1 3 10 12 2 9 11))         # same
         (cons "natural-minor" (1 3 10 12 2 9 11)) # same
         (cons "aeolian" (1 3 10 12 2 9 11))       # same
         (cons "phrygian" (1 8 10 12 2 9 11))
         (cons "locrian" (1 8 10 12 7 9 11))
         (cons "wholetone" (1 3 5 7 9 11))

         # chords
         # "maj"
         # "maj6"
         # "6"
         # "maj+"
         # "maj-aug"
         # "maj7"
         # "maj7+5"
         # "maj13+11"
         # "maj9"
         # "min"
         # "min7"
         # "min9"
         # "min7-5"
         # "min7b5"
         # "dim"
         # "dim7"
         # "aug"

      ]
      (make-all-scales-of-type-from-circle-of-fifths (car Scale) (cdr Scale)) ) )

# scale helpers
(de with-sharps (Scale)
   (mapcar
      '((Note) (if (pair Note) (car @) Note))
      Scale ) )

(de with-flats (Scale)
   (mapcar
      '((Note) (if (pair Note) (cdr @) Note))
      Scale ) )
