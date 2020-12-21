(load "../../pond.l" "../../music-generators.l")

# due to the '~' read macro, this function will be redefined
# each time the file is loaded
(de random-measures-in-different-time-signatures ()
   (lilypond "random-measures-in-different-time-signatures"
      (lyScore
         (lyMidi)
         (lyWrap
            ~(make
               (for N (2 3 4 5 6 7 8 9 11)
                  (for D (4 8 16)
                     (let @Time (pack N "/" D)
                        (macro
                           (link '(lyTime @Time))
                           (chain
                              (mapcar
                                 '((D) (pack (random-pitch-from-octave-range 1 2) D))
                                 (random-measure-of-durations @Time)) ) ) ) ) ) ) ) ) ) )
