(load "../../pond.l" "music-generators.l")

# another arpeggio in ees
(de code-gen-4 ()
   (let Notes '("ees" "g" "bes" "g" "bes" "ees'" "bes" "ees'" "g'")
      (make
         (for (I . 8va) '(0 1 2 2 1 0) # up/down 2 octaves
            (let Nts (if (< I 4) Notes (reverse Notes)) # reverse notes when going down
               (chain
                  (make
                     (do 9
                        (link
                           (pack
                              (pop 'Nts)
                              (pack (need 8va "'")) # adjust octave
                              8 ) ) ) ) ) ) ) ) ) )

(de render-code-gen-4 ()
   (lilypond "code-gen-4"
      (lyWrap
         (lyTime "9/8")
         ~(code-gen-4)) ) )
