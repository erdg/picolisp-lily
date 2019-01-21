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
            (prinl Obj) ) )
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
#
[de lyVar (Name . Music)
   (ifn Music
      (prinl "\\" Name)
      (prinl Name " =")
      (mapc eval Music) ]

# sequential music
# wraps music expressions in curly braces
#
[de lyWrap Music
   (prinl "{")
   (lyEval Music)
   (prinl "}") ]

# simultaneous music
# wraps music expressions with angle braces
#
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
#
[de ly<> Music
   (prinl "< " (lyEval Music) " >") ]

# include lilypond files
#
# NOTE - this will need to be different for DB entities
#
[de lyInclude (File) (prinl "\\include \"" File "\"")]

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

[de lyRepeat (Times . Music)
   (prinl "\\repeat volta " Times)
   (prinl "{")
   (lyEval Music)
   (prinl "}") ]

[de lyAlternative Music
   (prinl "\\alternative ")
   (prinl "{")
   (mapc eval Music)
   (prinl "}") ]

[de lyChords "Music"
   (prinl "\\chords")
   (prinl "{ ")
   (prinl "\\set chordChanges = ##t")
   (prinl "\\set minorChordModifier = \\markup { - }")
   (lyEval "Music")
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
   (lyEval (packDurations "Music" Clef))  # eg. -> b4 b4 b4 b4
   (prinl "\\revert NoteHead #'style")
   (prinl "}")
   (prinl "}")
   (prinl "}") ]

# don't like the name of this function
#
# (packDurations '(a4 b4 c4 d4) "treble")          -> b4 b4 b4 b4
# (packDurations '(b4. c8 r8 a8 r8 gis8) "bass")   -> d4. d8 r8 d8 r8 d8
#
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


# the following functions generate svg "musical icons", to be used in a
# a web app

# note without staff, clef, key/time signature
(de lyRhythmIcon (Note)
   (lyStaff
      (prinl "\\omit Staff.Clef")
      (prinl "\\omit Staff.KeySignature")
      (prinl "\\omit Staff.TimeSignature")
      (prinl "\\omit Staff.BarLine")
      (prinl "\\omit Staff.StaffSymbol")
      (prinl Note) ) )

# note with staff/clef for pitch reference. no key/time signature
(de lyNoteIcon (Note Clef)
   (lySetGlobalStaffSize 100)
   (lyInclude "lilyjazz.ily")
   (lyStaff
      (lyClef Clef)
      (prinl "\\omit Staff.KeySignature")
      (prinl "\\omit Staff.TimeSignature")
      (prinl "\\omit Staff.BarLine")
      (prinl "\\newSpacingSection")
      (prinl "\\override Staff.NoteSpacing.space-to-barline = ##f")
      (prinl "\\override Score.SpacingSpanner.base-shortest-duration = #(ly:make-moment 1)")
      (prinl "\\override Staff.Stem.no-stem-extend = ##t")
      (prinl "\\override Staff.Stem.neutral-direction = #down")
      (prinl "\\override Staff.StaffSymbol.ledger-line-thickness = #'(0.05 . 0.05)")
      # << { ... } \\ { ... } >> pattern (implicit simultaneous voices)
      (ly<<
         (lyWrap
            # hacks for proper stem direction
            (case Clef
               ("bass"
                  (if
                     (or
                        (and
                           (>= (length (fish '((C) (= C "'")) (chop Note))) 1)
                           (or (not (= (car Note) "a")) (not (= (car Note) "b"))) )
                        (and
                           (= (length (fish '((C) (= C ",")) (chop Note))) 0)
                           (not (= (car (chop Note)) "c")) ) )
                     (prinl "\\stemDown") ) )
               ("treble"
                  (if (>= (length (fish '((C) (= C "'")) (chop Note))) 2)
                     (prinl "\\stemDown") ) ) )
            (prinl Note)
            (prinl "\\stemNeutral") )
         (prinl "\\\\")
         # hidden notes 4 ledger lines above and below staff, for uniform SVG size/layout
         (lyWrap "\\hideNotes"
            (case Clef
               ("bass" (prinl "c''"))
               ("treble" (prinl "a'''")) ) )
         (prinl "\\\\")
         (lyWrap "\\hideNotes"
            (case Clef
               ("bass" (prinl "e,,"))
               ("treble" (prinl "c")) ) ) ) ) )

(de lyClefIcon (Clef)
   (lyStaff
      (lyClef Clef)
      (prinl "\\omit Staff.KeySignature")
      (prinl "\\omit Staff.TimeSignature")
      (prinl "\\omit Staff.BarLine")
      (prinl "\\omit Staff.StaffSymbol") ) )

[de lilypondSVG (File . Music)
   # write lilypond code to file
   (out (pack File ".ly")
      (lyVersion)
      (lyLayout)
      (run Music) )
   # create SVGs
   (t (call *Lily "-dpreview" "-dbackend=svg" File))
   # preview in browser
   (call 'firefox (pack File ".preview.svg")
]

(scl 4)

[de lilypondSVG%% (File . Music)
   # write lilypond code to file
   (out (pack File ".ly")
      (lyVersion)
      (lyLayout)
      (mapc eval Music) )
   # create svg
   (t (call *Lily "-dpreview" "-dbackend=svg" File))
   (let Svg (pack File ".production.svg")
      #if production file exists, clear it
      (if (info Svg) (out Svg NIL))

      # this is an experiment to attach a function to
      # the line, ie. make them clickable
      (in (pack File ".preview.svg")
         (while (line T)
            (out (pack "+" Svg)
               (if (pre? "<line" @)
                  (prog
                     # clickable line
                     (prinl "<a onclick=\"alert('line')\">")
                     (pipe
                        (prinl @)
                        (prinl
                           (use Str
                              (setq Str (split (till (eol)) " "))
                              (patch Str '(~(chop "stroke-width=\"") @N "\"") "stroke-width=\"0.5\"")
                              (patch Str '(~(chop "stroke=\"currentColor\"")) "stroke=\"white\"")
                              (glue " " (mapcar pack Str)) ) ) )
                     (prinl "</a>")
                     # print line as is
                     (prinl "<a onclick=\"alert('line')\">")
                     (prinl @)
                     (prinl "</a>")
                     # clickable space
                     (prinl "<a onclick=\"alert('space')\">")
                     (pipe
                        (prinl @)
                        (prinl
                           (till "," T) "," (format (- (any (till ")" T)) 0.5) *Scl ".")
                           (use Str
                              (setq Str (split (till (eol)) " "))
                              (patch Str '(~(chop "stroke-width=\"") @N "\"") "stroke-width=\"0.5\"")
                              (patch Str '(~(chop "stroke=\"currentColor\"")) "stroke=\"white\"")
                              (glue " " (mapcar pack Str)) ) ) )
                     (prinl "</a>") )
                  (prinl @) ) ) ) )

      # cleanup
      (call 'rm (pack File ".ly"))
      (call 'rm (pack File ".svg"))
      (call 'rm (pack File ".preview.svg"))
      # rename
      # (call 'mv (pack @File ".production.svg") (pack @File ".svg"))
      # preview in browser
      (call 'firefox Svg)
]

# later...
# need to loop over all durations
# nested for loop?

#  (for N '(1 2 4 8 16 32)
#     (t (call 'lilypond "-dpreview" "-dbackend=svg" "-o" "svg" Note))

#(t (call 'lilypond "-dpreview" "-dbackend=svg" "-o" "svg" Note))
