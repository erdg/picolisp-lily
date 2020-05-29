(load "../../pond.l" "../../music-generators.l")

(de random-measures-in-4/4 ()
   (lilypond "random-measures"
      # (lyJazz)
      (lyWrap
         ~(mapcar
            '((D) (pack (random-pitch-from-octave-range 0 2) D))
            (make
               (do 4
                  (chain (random-measure-of-durations "4/4")) ) ) ) ) ) )
