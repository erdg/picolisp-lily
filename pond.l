# /path/to/lilypond
(setq *Lily "/home/erik/bin/lilypond")
# /path/to/picolisp-lily
(setq *PicoLispLily "/home/erik/code/pl/picolisp-lily")
# version
(setq *Version "2.19.82")

# lilypond REPL - compiles lilypond files and opens pdf
# to continue development, return to PL terminal and hit ^C
#
# tested only with evince
#
[de lilypond (File . Music)
   (out (pack File ".ly")  # write file
      (lyVersion)
      (lyLayout)
      (lyHeader)
      (run Music 1) )
   (call *Lily File)
   (call 'evince (pack File ".pdf") ]

[de lilypondSVG (File . Music)
   # write lilypond code to file
   (out (pack File ".ly")
      (lyVersion)
      (lyLayout)
      (run Music) )
   # create SVGs
   (call *Lily "-dcrop" "-dbackend=svg" File)
]

# edit fn's from anywhere
[de lyVi (Fn)
   (chdir *PicoLispLily
      (vi Fn)
      (ld) ]

[de lyVersion () (prinl "\\version \"" *Version "\"")]

[de lyJazz ()
   ### jazz font
   (lyInclude "lilyjazz.ily")
   (lyInclude "jazzchords.ly") ]

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
# if Obj is an atom (e.g. "aes4." - an Ab dotted quarter note), it's printed
# with 'prinl'. if it's a list, it's evaluated. allows for nested musical
# structures.
#
# Note - most functions use the (mapc eval Music) pattern
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

# (lyPianoStaff
#    (lyStaff (lyMelody "c'" (lyClef "treble") "c4" "e" "d" "f" "e1"))
#    (lyStaff (lyMelody "c" (lyClef "bass") "c4" "e" "d" "f" "g1")) )
#
[de lyPianoStaff Music
   (prinl "\\new PianoStaff")
   (prinl "<<")
   (mapc eval Music)
   (prinl ">>") ]

# lyPiano - quickly sketch piano music
#
# (lyPiano
#    (cons "<ees,8 g>" (need 7 "<ees g>"))                  # LH
#    '("aes8" "ees" "bes" "ees" "aes" "ees" "aes" "ees") )  # RH
#
# NOTE - lists will be evaluated with 'lyEval', use 'quote' for
# a list of direct notes
#
[de lyPiano Music
   (let [(@L @R) Music] # left/right hand
      (macro
         (lyPianoStaff
            (lyStaff (lyClef "treble") (lyEval @L))
            (lyStaff (lyClef "bass")   (lyEval @R)) ]

# lyPianoChords - lyPiano with chords
#
# (lyPianoChords
#    '("bes1:7.5-")        # chord syms
#    '("<d'' aes' e>1")    # lh
#    '("<bes bes,>1") )    # rh
#
[de lyPianoChords Music
   (let [(@Chords @L @R) Music]
      (macro
         (ly<<
            (lyChords (lyEval @Chords))
            (lyPiano @L @R) ]

# lyPianoLeadsheet - lyPiano with chords/lyrics
#
# (lyPianoLeadsheet
#    '("bes1:7.5-")        # chord syms
#    '("<d'' aes' e>1")    # lh
#    '("<bes bes,>1") )    # rh
#    '("oooooooh") )       # lyrics
#
[de lyPianoLeadsheet Music
   (let [(@Chords @L @R @Lyrics) Music]
      (macro
         (ly<<
            (lyChords @Chords))
            (lyPiano @L @R)
            (lyLyrics @Lyrics) ]

[de lySet (Prop Val)    # context property, value
   (prinl "\\set " Prop " = " Val) ]

[de lyUnset (Prop)      # context property
   (prinl "\\unset " Prop) ]

# NOTE - should be called before any font configuration
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
# NOTE - probably not needed... just include chord as a music
# symbol directly, e.g. "<g b d>", it will be less writing.
#
# it's a neat little piece of code, nonetheless.
#
# MISC - duration goes outside the chord, e.g. "<g b d>4"
#
[de ly<> (Dur . @Notes)
   (macro (prinl "<" ^(list (glue " " @Notes)) ">" Dur) ]

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

#
# melodies
#
[de lyRelative (Note . Music)
   (prinl "\\relative " (pack Note))
   (prinl "{")
   (mapc eval Music)
   (prinl "}") ]

#
# same as 'lyRelative, but uses 'lyEval
# no need to explicitly use 'lyWrap
#
[de lyMelody (Note . Music)
   (prinl "\\relative " (pack Note))
   (prinl "{")
   (lyEval Music)
   (prinl "}") ]

# tuplets
#
# (lyTuplet "3/2" "f8" "g8" "a8") -> 1/8 note triplet
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

# line break - useful for formatting measures per line in leadsheets
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

[de lyMultiMeasureRests Music
   (prinl "\\compressFullBarRests")
   (prinl "\\override MultiMeasureRest.expand-limit = #1")  # no unreadable classical style multi-measure rests
   (lyEval Music) ]

[de lyChords "Music"
   (prinl "\\chords")
   (prinl "{ ")
   (prinl "\\set chordChanges = ##t")  # remove dups, only print chord sym upon changes
   (lyEval "Music")
   (prinl "}") ]

[de lyLyrics Lyrics
   (prinl "\\addlyrics")
   (prinl "{")
   (lyEval Lyrics)
   (prinl "}") ]

# simple leadsheets - a melody with chords and (optionally) lyrics
#
# (lyLeadsheet
#    '("c1:7" "f1:maj7")                             # chords
#    '("r4" "c'4" "d'4" "e'4" "f'8(" "g'8" "e'2.)")  # melody
#    '("this is a song __") )                        # lyrics
#
# NOTE - lists will be evaluated with 'lyEval', use 'quote' for
# a list of direct chords/notes/lyrics
#
[de lyLeadsheet Music
   (let [(@Chords @Melody @Lyrics) Music]
      (macro
         (lyScore
            (ly<<
               (lyChords (lyEval @Chords))
               (lyStaff  (lyEval @Melody))
               (lyLyrics (lyEval @Lyrics)) ]

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
#    (quote
#       (16 . "e1:min11")
#       (8 . "f1:min11")
#       (8 . "e1:min11") ) )
#
# -> the changes to 'So What' by Miles Davis (bass clef)
#
[de lyChanges (N Time Clef "Music")  # number of bars, time signature, clef, music exprs
   (ly<<
      (prinl "\\chords")
      (prinl "{ ")
      (prinl "\\set chordChanges = ##t")
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

# set scale for SVG x/y values
(scl 4)

# generic note icons with clickable staff lines/spaces
[de lilypondNoteIconSVG (File Clef . Music)
   # write lilypond code to file
   (out (pack File ".ly")
      (lyVersion)
      (lyLayout)
      (mapc eval Music) )
   # create SVGs
   (t (call *Lily "-dpreview" "-dbackend=svg" File))
   (let [Svg (pack File ".production.svg")
         Notes (circ 'a 'b 'c 'd 'e 'f 'g) ]
      #if production file exists, clear it
      (if (info Svg) (out Svg NIL))
      # arrange notes bottom staff line first
      [case Clef
         ("bass" (do 2 (rot Notes)))
         ("treble" (do 4 (rot Notes)))
      ]
      # fancy svg processing - attach a function to lines and spaces, ie. make
      # them clickable
      #
      # how it works - for each staff '<line>', first add a "fat" white
      # (transparent) line underneath.  this makes the space around the line
      # clickable, so it works consistently on a touch screen.  then print the
      # normal (black) staff line (also clickable). finally, print another
      # "fat" transparent line with an Y offset of -0.5. this makes the space
      # clickable.
      (in (pack File ".preview.svg")
         (while (line T) # -> @
            (out (pack "+" Svg)
               (if (pre? "<line" @) # -> @
                  (prog
                     # next pitch
                     (pop 'Notes)
                     # clickable line
                     (prinl "<a onclick=\"alert('line " (car Notes) "')\">")   # EDIT ONCLICK FN HERE
                     (pipe
                        (prinl @) # <- 'if'
                        (prinl
                           (use Str
                              (setq Str (split (till (eol)) " "))
                              (patch Str '(~(chop "stroke-width=\"") @N "\"") "stroke-width=\"0.5\"")
                              (patch Str '(~(chop "stroke=\"currentColor\"")) "stroke=\"white\"")
                              (glue " " (mapcar pack Str)) ) ) )
                     (prinl "</a>")
                     # print line as is, clickable
                     (prinl "<a onclick=\"alert('line " (car Notes) "')\">")   # EDIT ONCLICK FN HERE
                     (prinl @) # <- 'if'
                     (prinl "</a>")
                     # next pitch
                     (pop 'Notes)
                     # clickable space
                     (prinl "<a onclick=\"alert('space " (car Notes) "')\">")   # EDIT ONCLICK FN HERE
                     (pipe
                        (prinl @) # <- 'if'
                        (prinl
                           (till "," T) "," (format (- (any (till ")" T)) 0.5) *Scl ".")
                           (use Str
                              (setq Str (split (till (eol)) " "))
                              (patch Str '(~(chop "stroke-width=\"") @N "\"") "stroke-width=\"0.5\"")
                              (patch Str '(~(chop "stroke=\"currentColor\"")) "stroke=\"white\"")
                              (glue " " (mapcar pack Str)) ) ) )
                     (prinl "</a>") )
                  (prinl @) ) ) ) ) # <- 'if'
      # cleanup
      (call 'rm (pack File ".ly"))
      (call 'rm (pack File ".svg"))
      (call 'rm (pack File ".preview.svg"))
      # rename
      (call 'mv Svg (pack File ".svg"))
      # preview in browser
      (call 'firefox (pack File ".svg"))
]

# note icons with clickable staff lines, for interacting with hyperapp-js
[de lilypondSVG-noteIcon-hyperapp (File Clef . Music)
   # write lilypond code to file
   (out (pack File ".ly")
      (lyVersion)
      (lyLayout)
      (mapc eval Music) )
   # create svg
   (t (call *Lily "-dpreview" "-dbackend=svg" File))
   (let [Svg (pack File ".production.svg")
         Notes (circ 'a 'b 'c 'd 'e 'f 'g) ]
      #if production file exists, clear it
      (if (info Svg) (out Svg NIL))
      # arrange notes bottom staff line first
      [case Clef
         ("bass" (do 2 (rot Notes)))         # '(g a b c d e f .)
         ("treble" (do 4 (rot Notes)))  # '(e f g a b c d .)
      ]
      # fancy svg processing - attach a function to lines and spaces, ie. make them clickable
      (in (pack File ".preview.svg")
         (while (line T)
            (out (pack "+" Svg)
               (if (pre? "<line" @)
                  (prog
                     # next pitch
                     (pop 'Notes)
                     # clickable line
                     (prinl "<a onclick=\"window.top.main.setNote('" (car Notes) "')\">")   # EDIT ONCLICK FN HERE
                     (pipe
                        (prinl @)
                        (prinl
                           (use Str
                              (setq Str (split (till (eol)) " "))
                              (patch Str '(~(chop "stroke-width=\"") @N "\"") "stroke-width=\"0.5\"")
                              (patch Str '(~(chop "stroke=\"currentColor\"")) "stroke=\"white\"")
                              (glue " " (mapcar pack Str)) ) ) )
                     (prinl "</a>")
                     # print line as is, clickable
                     (prinl "<a onclick=\"window.top.main.setNote('" (car Notes) "')\">")   # EDIT ONCLICK FN HERE
                     (prinl @)
                     (prinl "</a>")
                     # next pitch
                     (pop 'Notes)
                     # clickable space
                     (prinl "<a onclick=\"window.top.main.setNote('" (car Notes) "')\">")   # EDIT ONCLICK FN HERE
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
      (call 'mv Svg (pack File ".svg"))
      # preview in browser
      (call 'firefox (pack File ".svg"))
]

# later...
# need to loop over all durations
# nested for loop?

#  (for N '(1 2 4 8 16 32)
#     (t (call 'lilypond "-dpreview" "-dbackend=svg" "-o" "svg" Note))

#(t (call 'lilypond "-dpreview" "-dbackend=svg" "-o" "svg" Note))
