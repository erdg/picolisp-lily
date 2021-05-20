# /path/to/lilypond
(setq *Lily "/home/erik/bin/lilypond")
# version
(setq *Version "2.20.0")

(once (load (pack (car (file)) "music-generators.l")))
(once (make-all-patterns))
(once (load (pack (car (file)) "lyread.l")))

# starts lilypond server on port 12321
(de lyServer ()
   (call 'sh "-c" "lilypond lilypond-stuff/server.ly &") )

(de lyc (File . Music)
    (out (pack File ".ly")  # write file
      (lyVersion)
      (lyLayout)
      (run Music) )
    (call 'sh "-c" (pack "./lilypond-stuff/lyc " File ".ly")) )

# lilypond REPL - compiles lilypond files and opens pdf
# to continue development, return to PL terminal and hit ^C
#
# tested only with evince
#
[de lilypond (File . Music)
   (out (pack File ".ly")  # write file
      (lyVersion)
      (lyLayout)
      (run Music) )
   (call *Lily File)
   (call 'evince (pack File ".pdf") ]

# just compile
(de _lilypond (File . Music)
   (out (pack File ".ly")  # write file
      (lyVersion)
      (lyLayout)
      (run Music) )
   (call *Lily File) )

[de lilypondSVG (File . Music)
   # write lilypond code to file
   (out (pack File ".ly")
      (lyVersion)
      (lyLayout)
      (run Music) )
   # create SVGs
   (call *Lily "-dcrop" "-dbackend=svg" File)
]

[de lyVersion () (prinl "\\version \"" *Version "\"")]

# fonts
(de lyJazzFont ()
   (if (= "picolisp-lily" (stem (chop (pwd)) "/"))
      (prog
         (lyInclude "lilypond-stuff/stylesheets/lilyjazz.ily")
         (lyInclude "lilypond-stuff/stylesheets/jazzchords.ily") )
      (prog
         (lyInclude "picolisp-lily/lilypond-stuff/stylesheets/lilyjazz.ily")
         (lyInclude "picolisp-lily/lilypond-stuff/stylesheets/jazzchords.ily") ) ) )

(de lyBeethovenFont ()
   (if (= "picolisp-lily" (stem (chop (pwd)) "/"))
      (lyInclude "lilypond-stuff/stylesheets/beethoven.ily")
      (lyInclude "picolisp-lily/lilypond-stuff/stylesheets/beethoven.ily") ) )

(de lyHaydnFont ()
   (if (= "picolisp-lily" (stem (chop (pwd)) "/"))
      (lyInclude "lilypond-stuff/stylesheets/haydn.ily")
      (lyInclude "picolisp-lily/lilypond-stuff/stylesheets/haydn.ily") ) )

(de lyImprovisoFont ()
   (if
      (= "picolisp-lily" (stem (chop (pwd)) "/"))
         (prog
            (lyInclude "lilypond-stuff/stylesheets/improviso.ily")
            (lyInclude "lilypond-stuff/stylesheets/jazzchords.ily") )
         (prog
            (lyInclude "picolisp-lily/lilypond-stuff/stylesheets/improviso.ily")
            (lyInclude "picolisp-lily/lilypond-stuff/stylesheets/jazzchords.ily") ) ) )

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

# lyMidi - create a midi file from score
#
# (lyScore
#    (lyMidi)
#    ... music here ... )
#
[de lyMidi ()
   (prinl "\\midi")
   (prinl "{")
   (prinl "}") ]

(de with-midi Music
   (macro
      (lyScore
         (lyMidi)
         ^ Music ) ) )

[de lyHeader (Title Composer)
   (prinl "\\header")
   (prinl "{")
   (prinl "tagline = ##f")
   (when Title
      (prinl "title = \"" Title "\"") )
   (when Composer
      (prinl "composer = \"" Composer "\"") )
   (prinl "}") ]


# NOTE - pretty sure this is the same as the built-in 'prEval'
#
# lyEval - recursively evaluates music expressions
#
# if Obj is an atom (e.g. "aes4." - an Ab dotted quarter note), it's printed
# with 'prinl'. if it's a list, it's evaluated. allows for nested musical
# structures.
#
# Note - most functions use the (run Music) pattern
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
   (run Music)
   (prinl "}") ]

(def 'score lyScore)

[de lyStaff Music
   (prinl "\\new Staff")
   (prinl"{")
   (run Music)
   (prinl "}") ]

(def 'staff 'lyStaff)

(de lyRhythmicStaff Music
   (prinl "\\new RhythmicStaff")
   (prinl "{")
   (run Music)
   (prinl "}") )

(def 'rythmic-staff lyRhythmicStaff)

(de lyDynamics "Music"
   (prinl "\\new Dynamics")
   (prinl"{")
   (run "Music")
   (prinl "}") )

(def 'dynamics lyDynamics)

(de lyStaffGroup Music
   (prinl "\\new StaffGroup")
   (prinl "<<")
   (lyEval Music)
   (prinl ">>") )

(def 'staff-group lyStaffGroup)

# (lyPianoStaff
#    (lyStaff (lyMelody "c'" (lyClef "treble") "c4" "e" "d" "f" "e1"))
#    (lyStaff (lyMelody "c" (lyClef "bass") "c4" "e" "d" "f" "g1")) )
#
[de lyPianoStaff Music
   (prinl "\\new PianoStaff")
   (prinl "<<")
   (run Music)
   (prinl ">>") ]

(def 'piano-staff lyPianoStaff)

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
            (lyStaff (lyClef "treble") (prEval @L))
            (lyStaff (lyClef "bass")   (prEval @R)) ]

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

(def 'piano-leadsheet lyPianoLeadsheet)

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
      (run Music) ]

(de variable Args
   (let [(Name . Music) Args]
      (ifn Music
         (prinl "\\" Name)
         (prinl Name " =")
         (run Music) ) ) )

#####
# sequential music
# wraps music expressions in curly braces

# # original
# (de lyWrap Music
#    (prinl "{")
#    (prEval Music)
#    (prinl "}") )


# with automatic timesigs
#
#  (melody c
#    { 3/4 a4 b c |
#      2/4 (tup 3/2 e8 e) })
#
#     vs
#
#  (melody c
#    { (meter 3/4) a4 b c |
#      (meter 2/4) (tup 3/2 e8 e) })
#
# atomic time signatures (see 'timeSig?') are converted to '(meter ...)', which
# is 'prEval'ed and yields the lilypond code '\time ...'

(de lyWrap Music
   (prinl "{")
   (macro
      (prEval
         '(^(make
               (for M Music
                  (link
                     (if (and (atom M) (timeSig? M))
                        (list 'meter M)
                        M ) ) ) ) ) ) )
   (prinl "}") )

#####

# simultaneous music
# wraps music expressions with angle braces
#
[de ly<< Music
   (prinl "<<")
   (run Music)
   (prinl ">>") ]

(de << "Music"
   (prinl "<<")
   (prEval "Music")
   (prinl ">>") )

# chords
#
# (ly<> "g" "b" "d") -> G major chord
#
# NOTE - probably not needed... just include chord as a music
# symbol directly, e.g. "<g b d>", it will be less writing.
#
# it's a neat little piece of code, nonetheless.
#
# NOTE - duration goes outside the chord, e.g. "<g b d>4"
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

(def '\\key lyKey)
(def 'keySig lyKey)

# time signatures
[de lyTime (Time)
   (if (= Time "4/4")
      (prinl "\\numericTimeSignature")
      (prinl "\\defaultTimeSignature") )
   (prinl "\\time " Time) ]

# time signatures (with optional beat structure)
#  (\\time "3/4)
#  (\\time (2 2 3) "7/8")
(de \\time Lst
   (ifn (pair (car Lst))
      (prinl "\\time " (car Lst))
      (prin "\\time #'") (print @) (prinl " " (cadr Lst)) ) )

(def 'meter \\time)

#  (lyTempo 4 120)            -> 4 = 120 (quarter note = 120)
#  (lyTempo 4 120 126)        -> 4 = 120 - 126
#  (lyTempo "Allegro")        -> Allegro
#  (lyTempo "Allegro" 4 132)  -> Allegro (4 = 132)
#  (lyTempo " " 4 132)        -> (4 = 132)
#
# NOTE - must use " " instead of "" when using lilypond syntax

(de lyTempo @
   (prin "\\tempo ")
   (case (length (rest))
      (1 (prinl (sym (next))))
      (2 (prinl (next) " = " (next)))
      (3 (cond
            ((not (arg 1))
               (prog (next) (prinl "\"\" " (next) " = " (next)) ) )
            ((num? (arg 1))
               (prinl (next) " = " (next) " - " (next)) )
            (T (prinl (sym (next)) " " (next) " = " (next))) ) ) ) )

(def 'tempo lyTempo)


# clef options - "treble", "bass", etc...
#
# currently only "treble", "bass", and "percussion" clefs
# are supported in 'lyChanges' and 'lyHits'. see below
#
[de lyClef (Clef)
   (prinl "\\clef " Clef) ]

(def '\\clef lyClef)
(def 'clef lyClef)

#
# melodies
#
[de lyRelative (Note . Music)
   (prinl "\\relative " (pack Note))
   (prinl "{")
   (run Music)
   (prinl "}") ]

(de relative (Note . Music)
   (prinl "\\relative " (pack Note))
   (prEval Music) )

# melody - relative, but better
#
#  (melody c'' {...})   # auto clef detection ("'"s = treble, [","s|" "] = bass)
#  (melody cis' minor bass 7/8 {...})  # clef override and modifiers (in any order)
#
# args should generally be 1 or several atoms, followed by a list (generally
# 'lyWrap', or { ... } in lilypond syntax)

(de melody Lst
   (let ((Note . Music) Lst)
      (prinl "\\relative " Note)
      (prinl "{")
      (accidentalStyle "neo-modern-cautionary")
      (if (= (last (chop Note)) "'")
         (clef "treble")
         (clef "bass") )
      (while (++ Music)
         (cond
            ((pair @) (eval @))
            ((timeSig? @) (lyTime @))
            ((keyMod? @) (lyKey Note @))
            ((clef? @) (lyClef @)) ) )
      (prinl "}") ) )

(de timeSig? (Sym)
   (and (sub? "/" Sym) (format (split (chop @) "/")) Sym) )

(de clef? (Sym)
   (and (<= 4 (length Sym))
      (or
         (pre? Sym "bass")
         (pre? Sym "treble")
         (pre? Sym "percussion") ) ) )

# key modifier
(de keyMod? (Sym)
   (and (< 1 (length Sym))
      (or
         (pre? Sym "major")
         (pre? Sym "minor") ) ) )

(de accidentalStyle Lst
   (prinl "\\accidentalStyle " (++ Lst)) )

# melody with abbreviated tuplet syntax
# can optionally use 'lyWrap' (looks better with lilypond syntax)
#
#  (lyMelody "c''"
#     "c4" "b" "a" "g" (T "3/2" "f" "e" "f") (T "3/2" "g" "a" "b") "c1" )
#
#  (lyMelody "c''"
#     (lyWrap "c4" "b" "a" "g" (T "3/2" "f" "e" "f") (T "3/2" "g" "a" "b") "c1" ) )
#
#  # lilypond syntax
#  (lyMelody c''
#     c4 b a g (T 3/2 f e f) (T 3/2 g a b) c1 )
#
#  (lyMelody c'' { c4 b a g (T 3/2 f e f) (T 3/2 g a b) c1 })
#
# NOTE - this is not really needed with 'tup' abbrev of 'lyTuplet'

(de lyMelody (Note . Music)
   (macro
      (prinl "\\relative " (pack Note))
      (prinl "{")
      (prEval
         '(^(make
               (for M (if (= (caar Music) 'lyWrap) (cdar Music) Music)
                  (cond
                     ((and (pair M) (=T (car @)))
                        (link (cons 'lyTuplet (cdr M))) )
                     (T (link M)) ) ) ) ) )
      (prinl "}") ) )

(de transpose (From To . Music)
   (prinl (text "\\transpose @1 @2" From To))
   (prEval Music) )

# tuplets
#
# (lyTuplet "3/2" "f8" "g8" "a8") -> 1/8 note triplet
#
[de lyTuplet (Sig . Music)
   (prinl "\\tuplet " Sig)
   (prinl "{")
   (lyEval Music)
   (prinl "}") ]

(def 'tup lyTuplet)

[de lyTuplet% (Sig Base . Music)
   (prinl "\\tuplet " Sig " " Base)
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
(de lyPartial (N . Music)
   (prinl "\\partial " N)
   (prEval Music) )

(def 'pickup lyPartial)

(de bar (Sym)
   (prinl "\\bar \"" Sym "\"") )

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
   (run Music)
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

(def 'leadsheet 'lyLeadsheet)


# leadsheet with rhythmic hits below the chord names
#
#  (leadsheet/hits
#     { d4.:min7 g8:7~ g4:7 c4:maj7 }  # chords / hits
#     (relative c''                    # melody
#        { d8 des ais b g f e c' } ) )

(de leadsheet/hits Music
   (let [(@Chords @Melody @Lyrics) Music]
      (macro
         (lyScore
            (ly<<
               (lyChords @Chords)
               (lyRhythmicStaff
                  (lyWrap
                     (prinl "\\override NoteHead.style = #'slash")
                     (prinl "\\override NoteHead.font-size = #-4")
                     ^(mapcar removeChord (cdr @Chords)) ) )
               (lyStaff @Melody)
               (lyLyrics (lyEval @Lyrics)) )
            (leadsheet-with-hits-layout) ) ) ) )

# remove chord from lilypond symbol, e.g. "d4.:maj9" -> "d4."
(de removeChord (Sym)
   (let Chop (chop Sym)
      (pack (car (split Chop ":")) (when (= (last Chop) "~") "~")) ) )

(de leadsheet-with-hits-layout ()
         (prinl "\\layout")
         (prinl "{")
         (prinl "\\context")
         (prinl "{")
         (prinl "\\RhythmicStaff")
         (prinl "\\remove \"Time_signature_engraver\"")
         (prinl "\\remove \"Clef_engraver\"")
         (prinl "\\override BarLine.transparent = ##t")
         (prinl "\\override StaffSymbol.line-count = #0")
         # adjust spacing of rhythmic staff here
         (prinl "\\override VerticalAxisGroup.staff-staff-spacing.padding = #2")
         (prinl "}")
         (prinl "}") )

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
#    (16 . "e1:min11")
#    (8 . "f1:min11")
#    (8 . "e1:min11") )
#
# -> the changes to 'So What' by Miles Davis (bass clef)

[de lyChanges (N Time Clef . "Music")  # number of bars, time signature, clef, music exprs
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

(def '\\changes lyChanges)

# same as 'lyChanges' with defaults and optional overrides
#
#  (changes 2 "c1:7" "f:min9") -> defaults to treble clef, 4/4
#  (changes 8 bass 3/4 (4 . "bes1:min9") (4 . "aes:maj7"))
#
# NOTE - works within 'lyWrap' (e.g. { (changes ...) (changes ...) } if no
# lists in '...' wrap.
(de changes Lst
   (let ((N . "Music") Lst)
      (use (Time Clef)
         (default Time "4/4" Clef "treble")
         (ly<<
            (prinl "\\chords")
            (prinl "{ ")
            (prinl "\\set chordChanges = ##t")
            (while (++ "Music")  # @@@ the most picolisp code of all time @@@
               (let Mus @
                  (cond
                     ((pair @)
                        (let L @  # current list
                           (if (num? (car @))
                              (do @ (prinl (cdr L)))
                              (eval L) ) ) )
                     ((timeSig? @) (setq Time (lyTime @)))
                     ((clef? @)    (setq Clef (lyClef @)))
                     (T (prinl Mus)) ) ) )
            (prinl "}")
            (lySlashes N Time Clef) ) ) ) )

#  (complex-changes
#     7/8 c2..:maj7 ees2..:maj7
#     4/4 f1:maj7
#     6/8 aes4.:dim7 bes4.:6 )

(de complex-changes Args
   (let [TimeSigs
            (filter timeSig? Args)
         TimeSigDurations
            (make
               (for Sig TimeSigs
                  (link
                     (and (split (chop Sig) "/")
                        (mapcar pack @)
                        (list (any (car @)) (duration-as-128th-notes (cdr @)))
                        (apply * @) ) ) ) )
         ChordLists
            (cdr (split (mapcar '((X) (if (timeSig? X) T X)) Args) T))
         ChordDurations
            (make
               (for X (mapcar '((L) (mapcar getDuration L)) ChordLists)
                  (link
                     (apply + (mapcar duration-as-128th-notes X)) ) ) )
         Chords
            (fish atom ChordLists)
         MeasuresPerTimeSig
            (mapcar '((X Y) (/ X Y)) ChordDurations TimeSigDurations)
         @Slashes
            (cons 'slashes (mapcar '((X Y) (list X Y)) MeasuresPerTimeSig TimeSigs)) ]
      (macro
         (<<
            (lyChords ^ Chords)
            @Slashes ) ) ) )

[de lySlashes (N Time Clef)  # number of bars, time signature, clef
   (default Time "4/4" Clef "treble")
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


# slashes -- like 'lySlashes' but allows changing time signatures
#
#  (slashes (2 "4/4") (2 "7/8"))

[de slashes Args
      (prinl "\\new Staff {")
      (prinl "{")
      (prinl "\\override NoteHead #'style = #'slash")
      (prinl "\\override Stem #'transparent = ##t")
      (for A Args
         (let [(N Time Clef) A]  # number of bars, time signature, clef
            (default Time "4/4" Clef "treble")
            (let [S     (split (chop Time) "/")
                  Beats (any (pack (car S)))
                  Pulse (any (pack (cdr S))) ]
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
               (prinl "}") )  ) )
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
#    "a4.:min6" "b8:7" "r8" "e8:7" "r8" "c8:maj7" )
#
[de lyHits (Time Clef . "Music")
   (ly<<
      (prinl "\\chords")
      (prinl "{ ")
      (prinl "\\set chordChanges = ##t")
      (prinl "\\set minorChordModifier = \\markup { - }")
      (prinl "\\set noChordSymbol = \"\"")   # hide 'N.C.'s
      (lyEval "Music")
      (prinl "}")
      (lyRhythms Time Clef "Music") ]

(def 'hits lyHits)

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

(def 'rhythms lyRhythms)

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
      (run Music) )
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
      (run Music) )
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
