(load "../../pond.l" "../../music-generators.l")

###

(de code-gen-8 ()
   (lyWrap
      (do 2
         (make-ly-times 8 7 8 ++
            (ring-from-list (with-flats (des-major-scale))) ) ) ) )

(de render-code-gen-8 ()
   (lilypond "code-gen-8" (code-gen-8)) )

###

(de code-gen-9 ()
   (lyWrap
      (do 4
         (make-ly-times-alt 4 5
            (mapcar
               '((R) (pack (random-element (with-flats (des-lydian-scale))) R))
               (random-rhythms "5/4" 2 "..") ) ) ) ) )

(de render-code-gen-9 ()
   (lilypond "code-gen-9" (code-gen-9)) )

###

(de code-gen-10 ()
   (lyWrap
      (for S '("c" "ees" "f" "aes" "bes")
         (let Notes
               (mapcar
                  '((Note) (pack Note (random-octave-from-range 1 2)))
                  (eval
                     (list
                        (case S
                              ((or "c" "f") 'with-sharps)
                              (T 'with-flats) )
                        (list (any (pack S "-lydian-scale"))) ) ) )
            (do 4
               (make-ly-times-alt 4 5
                  (mapcar
                     '((R) (pack (random-element Notes) R))
                     (random-rhythms "5/4" 2 "..") ) ) ) ) ) ) )

(de render-code-gen-10 ()
   (lilypond "code-gen-10" (code-gen-10)) )

###

(de code-gen-11 ()
   (eval
      (make-melody
         (pack-rhythms
            '(random-pitch-from-octave-range 0 2)
            (make-rhythms (4 . ((T "3/2" 8)(2 . (T "5/4" 16))(T "3/2" 8)))) ) ) ) )

(de render-code-gen-11 ()
   (lilypond "code-gen-11" (code-gen-11)) )

###

(de code-gen-12 ()
   (let L (with-flats (ees-dorian-scale))
      (make-melody
         (pack-rhythms
            '(pack (random-element L) (random-octave-from-range 1 2))
            (make-rhythms
               (4 . (T "3/2" 8))
               (4 . (T "5/4" 16))
               (4 . (T "6/4" 16))
               (4 . (T "7/4" 16)))) ) ) )

(de render-code-gen-12 ()
   (lilypond "code-gen-12" (code-gen-12)) )

###

# same as 12, but with no doubles (same note back to back)
(de code-gen-13 ()
   (let (L (with-flats (ees-dorian-scale)) LastNote NIL)
      (make-melody
         (pack-rhythms
            '(random-element-no-repeats L)
            (make-rhythms
               (4 . (T "3/2" 8))
               (4 . (T "5/4" 16))
               (4 . (T "6/4" 16))
               (4 . (T "7/4" 16)) ) ) ) ) )

(de render-code-gen-13 ()
   (lilypond "code-gen-13" (code-gen-13)) )
