# EDIT this fn for your own workflow.
[de lilypond "Args"
   (let [(@File . @Music)  "Args"]
      (macro
         (out (pack @File ".ly")  # write file
            (lyVersion)
            (mapc eval '@Music) )
         (call 'lilypond @File)
         (call 'evince (pack @File ".pdf") ]


# note to self - fns should print space/line as needed following fn call. 

[de lyVersion ()
   (prinl "\\version \"2.18.2\"")
   (prinl) ]

# currently not using this
[de lyHeader (Title Composer)
   (prinl "\\header {")
   (when Title
      (println "title = " Title) )
   (when Composer
      (println "composer = " Composer) )
   (prinl "}")
   (prinl) ]

[de lyScore Music
   (prinl "\\score {")
   (prinl)
   (mapc eval Music
   (prinl "}") ]

# wraps music expressions in curly braces
# sequential music
[de lyWrap Music
   (prinl "{")
   (lyEval Music)
   (prinl)
   (prinl "}") ]

# wraps music expressions with angle braces
# simultaneous music
[de << Music
   (prinl "<<")
   (mapc eval Music)
   (prinl ">>") ]

# chord function
# (ly<> "a" "c" "e") -> a minor chord
# clunky and probably not needed
# just include chord as a music symbol directly, e.g. "< a c e>"
[de ly<> Music
   (prinl "< " (lyEval Music) " >") ]

# this will need to be different for DB entities
# should probably just be an entity method, e.g. 'include>'
[de lyInclude (File) (prinl "\\include \"" (pack File ".ly") "\"")]

# Key signatures 
[de lyKey (Note Type)
   (prinl "\\key " Note " \\" Type) ]

# Time signatures
[de lyTime (Sig)
   (prinl "\\time " Sig) ]

# Clef options - "treble", "bass", etc...
[de lyClef (Clef)
   (prinl "\\clef " Clef) ]

# this seems to be the 'melody' function
# maybe rename to lyMelody?
[de lyRelative (Note . Music)
   (prinl "\\relative " (pack Note))
   (prinl "{")
   (mapc eval Music)
   (prinl)
   (prinl "}") ]

# bar lines
[de || ()
   (prin "\\bar \"||\" ") ]

[de |. ()
   (prin "\\bar \"|.\" ") ]

[de ||: (Times . Music)
   (prinl "\\repeat volta " Times) 
   (prinl " {")
   (mapc eval Music)
   (prinl)
   (prinl "}") ]

# lyEval
#
# recursively evaluates music expressions
# if object is an atom (e.g. "aes4." - an Ab dotted quarter note),
# it is 'prin'ted followed by a space.
# if it is a list, it's evaluated.
#
# allows for nested musical structures.
#
# seldom used, most functions seem to use the (mapc eval Music) pattern
[de lyEval (Lst)
   (mapc
      '((Obj)
         (if (pair Obj)
            (eval @)
            (prin Obj " ") ) )
      Lst ]

# (lyChanges 2 "f1:min9" "e:maj13+11")
#
# generates sheet music for given chord progression.
# any lists will be evaluated. this allows to include other
# musical stuff (double bar lines, meter changes, etc.)
#
# (lyChanges 2 "f1:min9" "e:maj13+11" (|.))
#
# if the 'car' of a list is a number, that number of chords 
# are added to the progression.
#
# (lyChanges 32 (16 . "e1:min11") (8 . "f1:min11") (8 . "e1:min11))
# 
# -> the changes to 'So What' by Miles Davis
#
[de lyChanges "Args"
   (let [(@N . @Music)  "Args"]
      (macro
         (<<
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
               '@Music )
            (prinl)
            (prinl "}")
            (slashes '@N) ]

[de slashes (N)   # number of bars
   (prinl "\\new Staff {")
   (sl
      (prin "\\relative c'' { ")
      (do N (lyEval '("b4" "b" "b" "b")))
      (prinl "}") )
   (prinl "}") ]

# slash notation
[de sl Music
   (prinl "{")
   (prinl "\\override NoteHead #'style = #'slash")
   (prinl "\\override Stem #'transparent = ##t")
   (mapc eval Music)
   (prinl "\\revert NoteHead #'style")
   (prinl "\\revert Stem #'transparent")
   (prinl "}") ]


# like chords, but uses rhythmic notation
# first arg is the time signature, must be a string.
# second is clef, also a string.
# followed by an arbitrary amount of chords/rests
#
# (hits "4/4" "treble" 
#    "a4.:min6" "b8:7" "r8" "e8:7" "r8" "c8:maj7" )
#
[de hits (TimeSig Clef . @Music)
   (macro
      (<<
         (prinl "\\chords")
         (prinl "{ ")
         (prinl "\\set chordChanges = ##t")
         (prinl "\\set minorChordModifier = \\markup { - }")
         (prinl "\\set noChordSymbol = \"\"")   # hide 'N.C.'s 
         (lyEval '@Music)
         (prinl)
         (prinl "}")
         (rhythms TimeSig Clef '@Music) ]

# rhythmic notation
[de rhythms (TimeSig Clef @Music)
   (default TimeSig "4/4" Clef "treble")
   (prinl "\\new Staff") 
   (prinl "{")
   (if (= Clef "treble") 
      (prinl "\\relative c''")
      (prinl "\\relative c") )
   (prinl "{")
   (lyTime TimeSig)
   (lyClef Clef)
   (prinl "{")
   (prinl "\\override NoteHead #'style = #'slash")
   (lyEval (macro (pack-durations '@Music (if (= Clef "bass") T))))
   (prinl)
   (prinl "\\revert NoteHead #'style")
   (prinl "}")
   (prinl "}")
   (prinl "}") ]

[de pack-durations (Music Flg)   # flag for bass clef
   (let Durs (mapcar '((M) (get-duration M)) Music)
      (lyEval
         (mapcar any
            (mapcar 
               '((X) 
                  (if (pre? "r" X) 
                     (pack X) 
                     (ifn Flg
                        (pack "b" X)
                        (pack "d" X) ) ) )
               Durs ]



# there has to be an easier way to do this
[de get-duration (Obj)
   (if (pre? "r" Obj)   # ignore if a rest
      (pack @)
      (let Dur (mapcar any (car (split (chop Obj) ":")))
         (pack
            (member
               (find num? Dur)
               Dur ]

# (lyTimes "2/3" "a4" "b4" "c4") -> 1/4 note triplets
# think of it as "in the space of 2 notes, put 3"
# (lyTimes "4/5" ...) -> in the space 4 notes, put 5
# etc...
(de lyTimes (Sig . Music)
   (prinl "\\times " Sig)
   (prinl "{ ")
   (lyEval Music)
   (prinl "}") )
