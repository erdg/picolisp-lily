(load "../../pond.l" "music-generators.l")

# random arpeggios
(de code-gen-5 ()
   # pick 3 - 11 random notes
   (let @Notes (make (do (rand 3 11) (link (random-pitch-from-octave-range 0 1))))
      (macro 
         # make tuples of that many 16th notes in the space four 16th notes
         (lyTimes (pack "4/" ^(list (length @Notes)))
            ^(make
               (do (length @Notes)
                  (link
                     (pack
                        (pop '@Notes)
                        16 ) ) ) ) ) ) ) )

(de render-code-gen-5 ()
   (lilypond "code-gen-5"
      (lyWrap
         # 2 measures in 4/4
         (do 8 (code-gen-5)) ) ) )
