(class +Melody +Entity)
(rel id (+Key +Number))
(rel nm (+String))

(rel note (+String)) # relative note
(rel tim (+String))  # time signature
(rel key (+String))  # key signature
(rel clf (+String))  # clef
(rel mus (+List +String))  # music (lilypond symbols)

(rel ly (+Blob))    # lilypond file
# this is a hack, but I kind of like the idea of hijacking
# the file extentsion
(rel svg (+Blob))          # svg
(rel preview.svg (+Blob))  # cropped svg

# write lilypond file
(dm lily> ()
   (put!> This 'ly T)
   (out (blob This 'ly)
      (lyVersion)
      (lyRelative (: note)
         (if (: tim) (lyTime @))
         (if (: key) (lyKey @))
         (if (: clf) (lyClef @))
         (lyEval (: mus)) ) ) )

# render lilypond file to svg
# will need a function to strip all '<a>' tags from the svg file
# lilypond links to lines in the source file. not okay for sharing
# svg's on the internet, when the source files are +Blob's in the
# picolisp DB
(dm render> ()
   (put!> This 'svg T)
   (put!> This 'preview.svg T)
   (call 'lilypond "-dpreview" "-dbackend=svg" "-o" *Blob (blob This 'ly)) )


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

[de lyKey (Note Type)
   (prinl "\\key " Note " \\" Type) ]

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
   (when Music (mapc eval @))
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
            (lyEval '@Music) 
            (prinl)
            (prinl "}")
            (slashes '@N) ]


# like chords, but uses rhythmic notation
# needs to some how parse the durations from the chords.
# first arg is the time signature, must be a string
# followed by an arbitrary amount of chords
# (hits "4/4" "a4.:min6" "b8:7" "r8" "e8:7" "r8" "c8:maj7")
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
      (lyEval @) )
   (prinl)
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
      (do N (lyEval '(b4 b b b)))
      (prinl "}") )
   (prinl "}") ]

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
      (mapc music
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
