(de code-generation-with-lyTimes ()
   (let (@Notes (circ 'a 'b 'c 'd 'e 'f 'g)
         @Octave (circ "'" "''" "" "," ",,")
         @Accidentals (circ 'is 'es) )
      (do 4
         (macro
            (lyTimes (pack (rand 1 16) "/" (rand 1 100))
               ^(make
                  (do 5
                     (link
                        (pack
                           (car (nth @Notes (rand 1 20)))
                           (car (nth @Accidentals (rand 1 10)))
                           (car (nth @Octave (rand 1 20)))
                           (car (nth (circ 2 "2." 4 "4." 8 16) (rand 1 20))) ) ) ) ) ) ) ) ) )

         
(de render-code-generation-with-lyTimes ()
   (chdir "code-generation-with-lyTimes"
      (lilypond "code-generation-with-lyTimes"
         (lyWrap
            (code-generation-with-lyTimes) ) ) ) )
