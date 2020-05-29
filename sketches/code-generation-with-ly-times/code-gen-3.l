(load "../../pond.l" "music-generators.l")

# arpeggio in ees
(de code-gen-3 ()
   (let Notes '("ees'" "g'" "aes'" "ees''" "bes'" "g''")
      (for (I . 8va) '(0 1 2 2 1 0) # up/down 2 octaves
         (let @Notes (if (< I 4) Notes (reverse Notes)) # reverse notes when going down
            (macro
               (lyTimes "4/6"
                  ^(make
                   # (do 6 ... but need counter for tie ('~')
                     (for I2 6
                        (link
                           (pack
                              (pop '@Notes)
                              (pack (need 8va "'"))
                              8
                              # tie the common note at the top
                              (when (and (= I 3) (= I2 6)) "~") ) ) ) ) ) ) ) ) ) )

(de render-code-gen-3 ()
   (lilypond "code-gen-3"
      (lyWrap
         (code-gen-3)) ) )
