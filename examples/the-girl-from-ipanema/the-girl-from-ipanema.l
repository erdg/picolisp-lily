(load "../pond.l")

(de the-girl-from-ipanema ()
   (lyHeader "The Girl from Ipanema" "Jobim")
   # NOTE - must be before style sheets
   # 30 seems good for leadsheets
   (lySetGlobalStaffSize 32)
   # notation styles (jazz)
   # (lyInclude "lv-goldenage.ly")
   (lyInclude "lilyjazz.ily")
   (lyInclude "jazzchords.ly")
   # score
   (lyScore
      (ly<<
         # chords
         (lyChords
            # A section (2x)
            (lyRepeat 2
               "f1:maj7" "f1:maj7" "g1:7" "g1:7"
               "g1:min7" "ges1:7" )
            (lyAlternative
               # 1st ending
               (lyWrap
                  "f1:maj7" "ges1:7" ) 
               # 2nd ending
               (lyWrap
                  "f1:maj7" "f1:maj7" ) )
            # B section
            # (lyWrap
               "ges1:maj7" "ges1:maj7" "b1:7" "b1:7"
               "fis1:min7" "fis1:min7" "d1:7" "d1:7"
               "g1:min7" "g1:min7" "ees1:7" "ees1:7"
               "a1:min7" "d1:7.5+" "g1:min7" "c1:7.5+" #)
            # A section
            # (lyWrap
               "f1:maj7" "f1:maj7" "g1:7" "g1:7"
               "g1:min7" "ges1:7" "f1:maj7" "f1:maj7" ) #)
         # melody
         (lyStaff
            (lyRelative "c''"
               (lyClef "treble")
               (lyTime "4/4")
               # A section (2x)
               (lyRepeat 2 
                  "g4." "e8" "e8" "d4" "g8~"
                  "g4" "e8" "e8~" "e8" "e8" "d8" "g8~"
                  "g4" "e4" "e4" "d8" "g8~"
                  "g8" "g8" "e8" "e8~" "e8" "e8" "d8" "f8~"
                  # remove clef on every line
                  (prinl "\\override Staff.Clef.stencil = ##f")
                  (lyBreak)

                  "f8" "d4" "d8~" "d8" "d8" "c8" "e8~"
                  "e8" "c4" "c8~" "c8" "c8" "bes4" )
               (lyAlternative 
                  # 1st ending
                  (lyWrap 
                     "r4" "c2.~"
                     "c1" )
                  # 2nd ending
                  (lyWrap 
                     "r4" "c2.~" 
                     "c2." "r4" (ly||) (lyBreak) ) )
               # B section
               (lyWrap
                  "f1~"
                  (lyTuplet "3/2" "f4" "ges4" "f4") (lyTuplet "3/2" "ees4" "f4" "ees4")
                  "des4." "ees8~" "ees2~"
                  "ees2." "r8" "gis8~" (lyBreak)

                  "gis1~"
                  (lyTuplet "3/2" "gis4" "a4" "gis4") (lyTuplet "3/2" "fis4" "gis4" "fis4")
                  "e4." "fis8~" "fis2~"
                  "fis2." "r8" "a8~" (lyBreak)

                  "a1~"
                  (lyTuplet "3/2" "a4" "bes4" "a4") (lyTuplet "3/2" "g4" "a4" "g4")
                  "f4." "g8~" "g2~"
                  "g2" (lyTuplet "3/2" "r4 a4 bes4") (lyBreak)

                  (lyTuplet "3/2" "c4" "c,4" "d4") (lyTuplet "3/2" "e4" "f4" "g4")
                  "gis2." "a4"
                  (lyTuplet "3/2" "bes4" "bes,4" "c4") (lyTuplet "3/2" "d4" "e4" "f4")
                  "fis1" (ly||) (lyBreak)

                  # A section
                  "g4." "e8" "e8" "d4" "g8~"
                  "g4" "e8" "e8~" "e8" "e8" "d8" "g8~"
                  "g4" "e4" "e4" "d8" "g8~"
                  "g8" "g8" "e8" "e8~" "e8" "e8" "d8" "a'8~" (lyBreak)

                  "a4." "f8" "f8" "f8" "d8" "c'8~"
                  "c4." "e,8" (lyTuplet "3/2" "e4" "e4" "d4")
                  "e1~"
                  "e4" "r4" "r2" (ly|.) ) ) ) ) ) )

(de echoLeadsheet ()
   (in "the-girl-from-ipanema.ly" (echo)) )

# render
(de renderTheGirlFromIpanema ()
   (lilypond "the-girl-from-ipanema" (the-girl-from-ipanema) ) )
