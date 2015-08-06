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
   (when Music
      (mapc eval @) )
   (prinl "}") ]
#

[de keysig (Note Type)
   (prinl "\\key " Note " \\" Type " ") ]

[de timesig Sig
   (prinl "\\time " Sig) ]

[de relative (Note . Music)
   (prinl "\\relative " (pack Note) " {")
   (when Music
      (mapc eval @) )
   (prinl "}") ]

[de notes Notes
   (map@ Notes
      (prin @ " ") ]

[de chords (Bars . Chords)
   (<<
      (prinl "\\chords { ")
      (prinl "\\set chordChanges = ##t")
#      (prinl "\\set minorChordModifier = \\markup { - }")
      [when Chords
         (map@ @
            (prin @ " ") ]
      (prinl "}")
      (slash Bars) ]


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
   (slashes
      (prin "\\relative c'' { ")
      (do N (notes b4 b b b))
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
   
[de times (Sig . Music)
   (prin "\\times " Sig " { ")
   (when Music
      (mapc eval @) )
   (prinl "}") ]
