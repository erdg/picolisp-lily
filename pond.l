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

[de relative () ]

[de notes Notes
   (map@ Notes
      (prin @ " ") ]

[de chords (Bars . Chords)
   (<<
      (prin "\\chords { ")
      (prinl "\\set minorChordModifier = \\markup { - }")
      [when Chords
         (map@ @
            (prin @ " ") ]
      (prinl "}")
      (slash Bars) ]

[de || ()
   (prin "\\bar \"||\" ") ]

[de |. ()
   (prin "\\bar \"|.\" ") ]

[de ||: (Times . Music)
   (prin "\\repeat volta " Times " {")
   (when Music
      (mapc eval @) )
   (prinl "}") ]

[de << Music
   (prinl "<<")
   (when Music
      (mapc eval @) )
   (prinl ">>") ]



# slash notation
[de slashes Music
   (prinl "{")
   (prinl "\\override NoteHead #'style = #'slash")
   (prinl "\\override Stem #'transparent = ##t")
   (when Music 
      (mapc eval @) )
   (prinl "\\revert NoteHead #'style")
   (prinl "\\revert Stem #'transparent")
   (prinl "}") ]

[de slash (N)   # number of bars
   (prinl "\\new Staff {")
   (slashes
      (prin "\\relative c'' { ")
      (do N (notes b4 b b b))
      (prinl "}") )
   (prinl "}") ]
