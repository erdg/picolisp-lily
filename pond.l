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

[de lyHeader (Title Composer)
   (prinl "\\header {")
   (when Title
      (prin "^Ititle = ") (println Title) )
   (when Composer
      (prin "^Icomposer = ") (println Composer) )
   (prinl "}")
   (prinl) ]

# fixme
[de lyScore Music
   (prinl "\\score {")
   (prinl)
   (when Music
      (mapc eval @) )
   (prinl "}") ]
#

[de lyKey "Args"
   (let [(@Note . @Type)  "Args"]
      (macro
         (prinl "\\key " '@Note " \\" '@Type " ") ]

[de lyTime (Sig)
   (prinl "\\time " Sig) ]

# Clef options - "treble", "bass", etc...
[de lyClef (Clef)
   (prinl "\\clef " Clef) ]

# this seems to be the 'melody' function
# maybe rename to lyMelody?
[de lyRelative (Note . Music)
   (prinl "\\relative " (pack Note))
   (prinl " {")
   (when Music
      (mapc music @) )
   (prinl)
   (prinl "}") ]

# this is a horrible function name
# maybe lyEval?
[de music (Obj)
   (or 
      (and (pair Obj) (eval @)) 
      (prin Obj " ") ]

# this is a common pattern
# this is a terrible function name
[de prMusic (Lst)
   (mapc music Lst) ]

# combined version of the above two functions
# recursively evaluates music expressions
# if object is atomic (e.g. "aes4." - an Ab dotted quarter not)
# it is 'prin'ted followed by a space.
# if it is a list, it's evaluated.
# allows for nested musical structures.
[de lyEval (Lst)
   (mapc
      '((Obj)
         (or
            (and (pair Obj) (eval @))
            (prin Obj " ") ) )
      Lst ]

# (chords 2 f1:min9 e:maj13+11)
#
# generates sheet music for given chord progression.
# any lists will be evaluated. this allows to include other
# musical stuff (double bar lines, meter changes, etc.)
#
# (chords 2 f1:min9 e:maj13+11 (|.))
#
[de chords "Args"
   (let [(@N . @Music)  "Args"]
      (macro
         (<<
            (prinl "\\chords")
            (prinl "{ ")
            (prinl "\\set chordChanges = ##t")
            (prinl "\\set minorChordModifier = \\markup { - }")
            (mapc music '@Music) 
            (prinl)
            (prinl "}")
            (slashes '@N) ]


# like chords, but uses rhythmic notation
# needs to some how parse the durations from the chords.
# first arg is the time signature, must be a string
# followed by an arbitrary amount of chords
# (hits "4/4" a4.:min6 b8:7 r e:7 r c:maj7)
[de hits (TimeSig . @Music)
   (macro
      (<<
         (prinl "\\chords")
         (prinl "{ ")
         (prinl "\\set chordChanges = ##t")
         (prinl "\\set minorChordModifier = \\markup { - }")
         (prinl "\\set noChordSymbol = \"\"")   # hide 'N.C.'s 
         (mapc music '@Music)
         (prinl)
         (prinl "}")
         (rhythms '@Music TimeSig) ]

[de || ()
   (prin "\\bar \"||\" ") ]

[de |. ()
   (prin "\\bar \"|.\" ") ]

[de ||: (Times . Music)
   (prinl "\\repeat volta " Times) 
   (prinl " {")
   (when Music
      (mapc eval @) )
   (prinl)
   (prinl "}") ]

# wraps music expressions in curly braces
# sequence
[de lyWrap Music
   (prinl "{")
   (when Music
      (mapc eval @) )
   (prinl "}") ]

[de << Music
   (prinl "<<")
   (when Music
      (mapc eval @) )
   (prinl ">>") ]



# slash notation
[de sl Music
   (prinl "{")
   (prinl "\\override NoteHead #'style = #'slash")
   (prinl "\\override Stem #'transparent = ##t")
   (when Music 
      (mapc eval @) )
   (prinl "\\revert NoteHead #'style")
   (prinl "\\revert Stem #'transparent")
   (prinl "}") ]

[de slashes (N)   # number of bars
   (prinl "\\new Staff {")
   (sl
      (prin "\\relative c'' { ")
      (do N (mapc music '(b4 b b b)))
      (prinl "}") )
   (prinl "}") ]

# rhythmic notation
[de rhythms (@Music TimeSig)
   (default TimeSig "4/4")
   (prinl "\\new Staff") 
   (prinl "{")
   (prinl "\\relative c''")
   (prinl "{")
   (lyTime (eval TimeSig))
   (prinl "{")
   (prinl "\\override NoteHead #'style = #'slash")
   (mapc music (macro (pack-durations '@Music))
   (prinl)
   (prinl "\\revert NoteHead #'style")
   (prinl "}")
   (prinl "}")
   (prinl "}") ]

[de pack-durations (Music)
   (let Durs (mapcar '((M) (get-duration M)) Music)
      (mapc music
         (mapcar any
            (mapcar 
               '((X) (if (pre? "r" X) (pack X) (pack "b" X)))
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

[de lyTimes "Args"
   (let [(@Sig . @Music)  "Args"]
      (macro
         (prin "\\times " '@Sig " { ")
         (mapc music '@Music)
         (prinl "}") ]
