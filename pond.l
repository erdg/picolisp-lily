[load "@lib/map@.l"]

[symbols 'lily 'pico]


[de lilypond "Args"
   (let [(@File . @Music)  "Args"]
      (macro
         (out (pack @File ".ly")  # write file
            (version)
            (mapc eval '@Music) )
         (call 'lilypond @File)
         (call 'evince (pack @File ".pdf") ]


# note to self - fns should print space/line as needed following fn call. 
[de version ()
   (prinl "\\version \"2.18.2\"")
   (prinl) ]

[de header (Title Composer)
   (prinl "\\header {")
   (when Title
      (prin "^Ititle = ") (println Title) )
   (when Composer
      (prin "^Icomposer = ") (println Composer) )
   (prinl "}")
   (prinl) ]

# fixme
[de score Music
   (prinl "\\score {")
   (prinl)
   (when Music
      (mapc eval @) )
   (prinl "}") ]
#

[de keysig "Args"
   (let [(@Note . @Type)  "Args"]
      (macro
         (prinl "\\key " '@Note " \\" '@Type " ") ]

[de timesig Sig
   (prinl "\\time " Sig) ]

[de relative (Note . Music)
   (prinl "\\relative " (pack Note) " {")
   (when Music
      (mapc eval @) )
   (prinl "}") ]

[de music (Obj)
   (or 
      (and (pair Obj) (eval @)) 
      (prin Obj " ") ]

# (chords 2 f1:min9 e:maj13+11)
#
# generates sheet music for given chord progression.
# any lists will be evaluated. this allows to include other
# musical stuff (double bar lines, meter changes, etc.)
#
# (chords 2 f1:min9 e:maj13+11 (|.))
[de chords "Args"
   (let [(@N . @Music)  "Args"]
      (macro
         (<<
            (prinl "\\chords { ")
            (prinl "\\set chordChanges = ##t")
            (prinl "\\set minorChordModifier = \\markup { - }")
            (mapc music '@Music) 
            (prinl "}")
            (slashes '@N) ]


# like chords, but uses rhythmic notation
# needs to some how parse the durations from the chords.
# (hits a4.:min6 b8:7 r e:7 r c:maj7)
[de hits () ]


[de || ()
   (prin "\\bar \"||\" ") ]

[de |. ()
   (prin "\\bar \"|.\" ") ]

[de ||: (Times . Music)
   (prin "\\repeat volta " Times " {")
   (when Music
      (mapc eval @) )
   (prinl "}") ]

[de wrap Music
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
[de rhy Music
   (prinl "{")
   (prinl "\\override NoteHead #'style = #'slash"
   (when Music
      (mapc eval @) )
   (prinl "\\revert NoteHead #'style")
   (prinl "}") ]
   
[de times "Args"
   (let [(@Sig . @Music)  "Args"]
      (macro
         (prin "\\times " '@Sig " { ")
         (mapc music '@Music)
         (prinl "}") ]
