# /path/to/lilypond
(setq *Lily "/home/erik/bin/lilypond")
# version
(setq *Version "2.19.82")

# REPL
# compiles lilypond files and opens pdf
# to continue development, return to PL terminal and hit ^C
# tested only with evince
#
[de lilypond "Args"
   (let [(@File . @Music)  "Args"]
      (macro
         (out (pack @File ".ly")  # write file
            (lyVersion)
            (lyLayout)
            (mapc eval '@Music) )
         (call *Lily @File)
         (call 'evince (pack @File ".pdf") ]

[de lyVersion () (prinl "\\version \"" *Version "\"")]

[de lyLayout () 
   (prinl "\\layout")
   (prinl "{")
   # no indent on first stave
   (prinl "indent = 0")
   (prinl "\\context")
   (prinl "{")
   (prinl "\\Score")
   # no bar numbers
   (prinl "\\omit BarNumber")
   (prinl "}")
   (prinl "}") ]

[de lyHeader (Title Composer)
   (prinl "\\header")
   (prinl "{")
   (prinl "tagline = ##f")
   (when Title
      (prinl "title = \"" Title "\"") )
   (when Composer
      (prinl "composer = \"" Composer "\"") )
   (prinl "}") ]

# lyEval - recursively evaluates music expressions
#
# if Obj is an atom (e.g. "aes4." - an Ab dotted quarter note),
# it's 'prin'ted followed by a space. if it's a list, it's
# evaluated.
#
# allows for nested musical structures.
#
# Note - most functions seem to use the (mapc eval Music) pattern
#
[de lyEval (Lst)
   (mapc
      '((Obj)
         (if (pair Obj)
            (eval @)
            (prinl Obj " ") ) )
      Lst ) ]

[de lyScore Music
   (prinl "\\score")
   (prinl "{")
   (mapc eval Music)
   (prinl "}") ]

[de lyStaff Music
   (prinl "\\new Staff")
   (prinl"{")
   (mapc eval Music)
   (prinl "}") ]

[de lySet (Prop Val)    # context property, value
   (prinl "\\set " Prop " = " Val) ]

[de lyUnset (Prop)    # context property, value
   (prinl "\\unset " Prop) ]

[de lySetGlobalStaffSize (N)
   (prinl "#(set-global-staff-size " N ")") ]

# lilypond varibles
#
# usage - declare variable
#
# (lyVar "notes" (lyRelative "c''" (lyWrap "a4" "b4" "c4" "b4" "a1")))
# -> notes = \relative c'' { a4 b4 c4 b4 a1 }
#
# usage - call variable
#
# (lyVar "notes")
# -> \notes
[de lyVar (Name . Music)
   (ifn Music
      (prinl "\\" Name)
      (prinl Name " =")
      (mapc eval Music) ]

# sequential music
# wraps music expressions in curly braces
[de lyWrap Music
   (prinl "{")
   (lyEval Music)
   (prinl "}") ]

# simultaneous music
# wraps music expressions with angle braces
[de ly<< Music
   (prinl "<<")
   (mapc eval Music)
   (prinl ">>") ]

# chords
#
# (ly<> "g" "b" "d") -> G major chord
#
# probably not needed... just include chord as a music
# symbol directly, e.g. "<g b d>"
[de ly<> Music
   (prinl "< " (lyEval Music) " >") ]

# include lilypond files
#
# Note - this will need to be different for DB entities
[de lyInclude (File) (prinl "\\include \"" (pack File ".ly") "\"")]

# key signatures
[de lyKey (Note Type)
   (prinl "\\key " Note " \\" Type) ]

# time signatures
[de lyTime (Time)
   (if (= Time "4/4")
      (prinl "\\numericTimeSignature")
      (prinl "\\defaultTimeSignature") )
   (prinl "\\time " Time) ]

# clef options - "treble", "bass", etc...
#
# currently only "treble", "bass", and "percussion" clefs
# are supported in 'lyChanges' and 'lyHits'. see below
#
[de lyClef (Clef)
   (prinl "\\clef " Clef) ]

# melodies
#
# this seems to be the "melody" function
# maybe rename to 'lyMelody'?
#
[de lyRelative (Note . Music)
   (prinl "\\relative " (pack Note))
   (prinl "{")
   (mapc eval Music)
   (prinl "}") ]

# tuplets
#
# (lyTuplet "3/2" "f8 g8 "a8") -> 1/8 note triplet
#
[de lyTuplet (Sig . Music)
   (prinl "\\tuplet " Sig)
   (prinl "{")
   (lyEval Music)
   (prinl "}") ]

# times - like tuplets, but crazier
#
# (lyTimes "2/3" "a4" "b4" "c4") -> 1/4 note triplets
#
# in english, the above could be, "in the space of 2 (quarter notes),
# put 3 (quarter notes)"
#
# (lyTimes "4/5" ...) -> in the space 4 notes, put 5
#
(de lyTimes (Sig . Music)
   (prinl "\\times " Sig)
   (prinl "{ ")
   (lyEval Music)
   (prinl "}") )

# pickup notes
#
# (lyPickup "2" "a4 b4") -> 2 quarter notes
#
(de lyPickup (N . Music)
   (prinl "\\partial " N " ")
   (lyEval Music) )

# single bar (lilypond bar check)
[de ly| () (prinl "\\bar \"|\" ")]

# dotted bar
[de ly! () (prinl "\\bar \"!\"")]

# double bar
[de ly|| () (prinl "\\bar \"||\" ")]

[de lyBreak () (prinl "\\break")]

# ending double bar
[de ly|. () (prinl "\\bar \"|.\" ")]

# repeats
[de ly.|: () (prinl "\\bar \".|:\"")]  # -> ||:

[de ly:|. () (prinl "\\bar \":|.\"")]  # -> :||

# winged repeats                       #    //
[de ly<|: () (prinl "\\bar \"[|:\"")]  # -> ||:
                                       #    \\

                                       #     \\
[de ly:|> () (prinl "\\bar \":|]\"")]  # -> :||
                                       #     //

# repeat music (standard repeat signs)
[de ly||: Music
   (prinl "{")
   (ly.|:)
   (lyEval Music)
   (ly:|.)
   (prinl "}") ]

# repeat music (winged repeat signs)
[de ly<||: Music
   (prinl "{")
   (ly<|:)
   (lyEval Music)
   (ly:|>)
   (prinl "}") ]


# chord changes
#
# generates sheet music for given chord progression.
# any lists will be evaluated. this allows to include other
# musical stuff (double bar lines, meter changes, etc.)
#
# (lyChanges 2 "4/4" "treble"
#    (list "f1:min9" "e1:maj13.11+" (|.)) )
#
# -> 2 measure chord progression... Fmin9 - Emaj7(#11) with an
#    ending bar
#
# if the 'car' of a list is a number, that number of chords
# are added to the progression.
#
# (lyChanges 32 "4/4" "bass"
#    (list
#       (16 . "e1:min11")
#       (8 . "f1:min11")
#       (8 . "e1:min11) ) )
#
# -> the changes to 'So What' by Miles Davis (bass clef)
#
[de lyChanges (N Time Clef "Music")  # number of bars, time signature, clef, music exprs
   (ly<<
      (prinl "\\chords")
      (prinl "{ ")
      (prinl "\\set chordChanges = ##t")
      (prinl "\\set minorChordModifier = \\markup { - }")
      # variation on 'lyEval' to allow repeated chord shorthand
      (mapc
         '((Obj)
            (if2 (pair Obj) (num? (car Obj))
               (do (car Obj) (prin (cdr Obj) " "))
               (eval @)
               NIL
               (prin Obj " ") ) )
         "Music" )
      (prinl)
      (prinl "}")
      (lySlashes N Time Clef) ]

[de lySlashes (N Time Clef)  # number of bars, time signature, clef
   (let [S     (split (chop Time) "/")
         Beats (any (pack (car S)))
         Pulse (any (pack (cdr S))) ]
      (prinl "\\new Staff {")
      (prinl "{")
      (prinl "\\override NoteHead #'style = #'slash")
      (prinl "\\override Stem #'transparent = ##t")
      (prinl "\\relative c"
         (cond
            ((= Clef "bass"))
            ((= Clef "percussion") "'")
            (T "''") )
         " {")
      (lyTime Time)
      (lyClef Clef)
      (do N
         (lyEval
            (need Beats
               (pack
                  (cond
                     ((= Clef "bass") "d")
                     ((= Clef "percussion") "c")
                     (T "b" ) )
                  Pulse) ) ) )
      (prinl "}") )
      (prinl "\\revert NoteHead #'style")
      (prinl "\\revert Stem #'transparent")
      (prinl "}")
      (prinl "}") ]


# hits
#
# like changes, but uses rhythmic notation.
# first arg is the time signature (string), second is
# clef (string), followed by list of chords/rests
#
# (lyHits "4/4" "treble"
#    (list "a4.:min6" "b8:7" "r8" "e8:7" "r8" "c8:maj7") )
#
[de lyHits (Time Clef "Music")
   (ly<<
      (prinl "\\chords")
      (prinl "{ ")
      (prinl "\\set chordChanges = ##t")
      (prinl "\\set minorChordModifier = \\markup { - }")
      (prinl "\\set noChordSymbol = \"\"")   # hide 'N.C.'s
      (lyEval "Music")
      (prinl "}")
      (lyRhythms Time Clef "Music") ]

# rhythmic notation
[de lyRhythms (Time Clef "Music")
   (prinl "\\new Staff")
   (prinl "{")
   (prinl "\\relative c"
      (cond
         ((= Clef "bass"))
         ((= Clef "percussion") "'")
         (T "''") ) )
   (prinl "{")
   (lyTime Time)
   (lyClef Clef)
   (prinl "{")
   (prinl "\\override NoteHead #'style = #'slash")
   (lyEval (packDurations "Music" Clef))
   (prinl "\\revert NoteHead #'style")
   (prinl "}")
   (prinl "}")
   (prinl "}") ]

# don't like the name of this function
[de packDurations (Music Clef)
   (let Durs (mapcar '((M) (getDuration M)) Music)
      (mapcar any
         (mapcar
            '((X)
               (if (pre? "r" X)
                  (pack @)
                  (cond
                     ((= Clef "bass") (pack "d" X))
                     ((= Clef "percussion") (pack "c" X))
                     (T (pack "b" X)) ) ) )
            Durs ]

# get the duration of music object
#
# if Obj is a rest (e.g. "r4"), rest is returned unchanged
#
# (getDuration "r4.") -> "r4."
# (getDuration "a4.:maj9") -> "4."
#
[de getDuration (Obj)
   (if (pre? "r" Obj)   # ignore if a rest
      (pack @)
      (let Dur (mapcar any (car (split (chop Obj) ":")))
         (pack
            (member
               (find num? Dur)
               Dur ]
