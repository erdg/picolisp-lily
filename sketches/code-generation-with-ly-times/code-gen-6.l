(load "../../pond.l" "music-generators.l")

# random arpeggios
(de code-gen-6 ()
   (do 4
      (for Octave '(0 1 2 2 1 0)
      # pick 3 - 11 random notes, move up and down octaves
         (let @Notes (make (do (rand 3 11) (link (random-pitch-from-octave-range Octave Octave))))
            (macro 
               # make tuples of that many 16th notes in the space four 16th notes
               (lyTimes (pack "4/" ^(list (length @Notes)))
                  ^(make
                     (do (length @Notes)
                        (link
                           (pack
                              (pop '@Notes)
                              16 ) ) ) ) ) ) ) ) ) )

(de render-code-gen-6 ()
   (lilypond "code-gen-6"
      (lyScore
         (lyMidi)
         (lyWrap
            (code-gen-6)) ) ) )
