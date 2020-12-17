(load "../../pond.l")

(once (make-all-patterns))

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


(de cg14 ()
   (arp (random-element (with-flats (d/lyd)))
      (4 . (T "3/2" 8))
      (4 . (T "5/4" 16))
      (4 . (T "6/4" 16))
      (4 . (T "7/4" 16)) ) )

(de render-cg14 () (lilypond "cg14" (cg14)))


(de cg15 ()
   (let Notes '("des" "ees" "f" .)
      (arp (++ Notes)
         (4 . (T "3/2" 8))
         (4 . (T "5/4" 16))
         (4 . (T "6/4" 16))
         (4 . (T "7/4" 16)) ) ) )

(de render-cg15 () (lilypond "cg15" (cg15)))


(de cg16 ()
   (let Notes (ring (make-multi-octave-scale (with-flats (des|maj7)) "'" "''"))
      (arp (++ Notes)
         (4 . (T "3/2" 8))
         (4 . (T "5/4" 16))
         (4 . (T "6/4" 16))
         (4 . (T "7/4" 16)) ) ) )

(de render-cg16 () (lilypond "cg16" (cg16)))


(de cg17 ()
   (let Notes (ring (make-multi-octave-scale (with-flats (des|maj7)) "'" "''"))
      (arp (++ Notes)
         (4 . (T "3/2" 8))
         (7 . (random-rhythms-from "7/8" '(4 4 8 8 8 16 16 16 "8." "4.")))
         (4 . (T "5/4" 16))
         (4 . (T "6/4" 16))
         (4 . (T "7/4" 16)) ) ) )

(de render-cg17 () (lilypond "cg17" (cg17)))


(de cg18 ()
   (let Notes (ring (map-octave "'" '("f"  "ees" "f" "aes" "bes")))
      (arp (++ Notes)
         (lyTime "7/8")
         (7 . (random-rhythms-from "7/8" '(4 4 8 8 8 16 16 16 "8." "4."))) ) ) )

(de render-cg18 () (lilypond "cg18" (cg18)))


(de cg19 ()
   (macro
      (lyWrap
         (lyTime "7/8")
         ^(let Notes (ring (map-octave "'" '("f"  "ees" "f" "aes" "bes")))
            (arp-no-wrap (++ Notes)
               (7 . (random-rhythms-from "7/8" '(4 4 8 8 8 16 16 16 "8." "4."))) ) ) ) ) )

(de render-cg19 () (lilypond "cg19" (cg19)))


(de cg20 ()
   (lyWrap
      (lyTime "7/8")
      ~(let Notes (ring (map-octave "'" '("f"  "ees" "f" "aes" "bes")))
         (arp-no-wrap (++ Notes)
            (7 . (random-rhythms-from "7/8" '(4 4 8 8 8 16 16 16 "8." "4."))) ) ) ) )

(de render-cg20 () (lilypond "cg20" (cg20)))


(de cg21 ()
   (lyWrap
      ~(let Notes (map-octave "'" '("f"  "ees" "f" "aes" "bes"))
         (arp-in "7/8"
            (random-element-no-repeats Notes)
            (7 . (random-rhythms-from "7/8" '(4 4 8 8 8 16 16 16 "8." "4."))) ) )  ) )

(de render-cg21 () (lilypond "cg21" (cg21)))


(de cg22 ()
   (with-midi
      (lyPiano
         (let Notes (ring (map-octave "'" '("aes" "des'" "c'" "aes'")))
            (arp-in "13/16" (++ Notes) (4 . (random-rhythms-from "13/16" (2 4 4 8 8 16)))) )
         (let Notes (ring '("aes" "des" "ees" "aes,"))
            (arp-in "13/16" (++ Notes) (4 . (random-rhythms-from "13/16" (2 4 4 8 8 16)))) ) ) ) )

(de render-cg22 () (lilypond "cg22" (cg22)))


(de cg23 ()
   (lyPiano
      (let Notes (ring (map-octave "'" '("aes" "des'" "c'" "aes'")))
         (arp-in "4/4" (++ Notes)
            (4 . (random-rhythms-from "4/4" (2 4 4 8 8 16)))
            (4 . (random-rhythms-from "4/4" (4 8 8 16 16)))
            (4 . (random-rhythms-from "4/4" (8 8 16 "8." "16.")))
            (4 . (random-rhythms-from "4/4" (8  16 16)))))
      (let Notes (ring '("aes" "des" "ees" "aes,"))
         (arp-in "4/4" (++ Notes)
            (4 . (random-rhythms-from "4/4" (2 4 4 8 8 16)))
            (4 . (random-rhythms-from "4/4" (4 8 8 16 16)))
            (4 . (random-rhythms-from "4/4" (8 8 16 "8." "16.")))
            (4 . (random-rhythms-from "4/4" (8  16 16))) ) ) ) )

(de render-cg23 ()
   (_lilypond "cg23" (with-midi (cg23)))
   (lilypond "cg23" (cg23)) )


(de cg24 ()
   (lyPiano
      (let Oct ""
         (make
            (do 4
               (chain
                  (let Notes (ring (map-octave Oct '("des" "f" "aes" "c'")))
                     (arp-in "4/4" (++ Notes)
                        (random-rhythms-from "4/4" (2 4))
                        (random-rhythms-from "4/4" (4 8))
                        (random-rhythms-from "4/4" (8 16))
                        (random-rhythms-from "4/4" (16 32)) ) ) )
               (setq Oct (pack Oct "'")) ) ) ) ) )

(de render-cg24 ()
   (_lilypond "cg24" (with-midi (cg24)))
   (lilypond "cg24" (cg24)) )

(de cg25 ()
   (lyPiano
      (let Oct ""
         (make
            (do 4
               (chain
                  (let Notes (ring (map-octave Oct '("des" "f" "aes" "c'")))
                     (arp-in-rrf "4/4" (++ Notes)
                        (2 4)
                        (4 8)
                        (8 16)
                        (16 32) ) ) )
               (setq Oct (pack Oct "'")) ) ) ) ) )

(de render-cg25 ()
   (_lilypond "cg25" (with-midi (cg25)))
   (lilypond "cg25" (cg25)) )


# this has potential - C lydian
(de cg26 ()
   (lyPiano
      (let Notes (circ "<e' fis' b'>" "<d' fis' a'>")
         (arp-in "13/16" (++ Notes) (8 . (random-rhythms-from "13/16" (2 4 4 8 8 16)))) )
      (let Notes (circ "c," "g," "e" "g," "d" "a" "d" "g," "e" "g,")
         (arp-in "13/16" (++ Notes) (8 . (random-rhythms-from "13/16" (2 4 4 8 8 16)))) ) ) )

(de render-cg26 ()
   (_lilypond "cg26" (with-midi (cg26)))
   (lilypond "cg26" (cg26)) )



(de cg27 ()
   (lyPiano
      (let Notes (circ "f'" "g'" "bes'" "c''")
         (arp-in "4/4" (++ Notes)
            (2 . (4 . 4))  # 4 groups of 4 quarter notes
            (2 . (8 . 8))  # 8 groups of 8 eighth notes
            (4 (T "3/2" 8))
            (2 (2 . ((T "7/4" 16)(T "5/4" 16))))  # NOTE - must use 'dot' for 'run'-like behavior
            (8 (T "7/4" 32))
            (4 (random-measure-of-durations "4/4"))
            (2 (random-rhythms "4/4"))
            ) )
      (let Notes (circ "<f a bes c'>" "<ees bes c'>")
         (arp-in "4/4" (++ Notes)
            (2 . (2 . 2))
            (2 . 1)
            (T "3/2" 2)
            (2 (T "5/4" 4))
            (random-rhythms-from "4/4" (8 16 "8." "16." 4))
            (4 (random-measure-of-durations "4/4"))
            (2 (random-rhythms "4/4"))
            ) )
      ) )

(de render-cg27 ()
   (_lilypond "cg27" (with-midi (cg27)))
   (lilypond "cg27" (cg27)) )


# prototype arpeggio chain, variations on Notes
(de cg28 ()
   (lyPiano
      # LH
      (lyWrap
         ~(let Notes '("f'" "g'" "bes'" "c''")
            (make
               (chain
                  (let Ns (ring Notes)
                     (arp-in "4/4" (++ Ns)
                        (4 . ((T "5/4" 16) (T "3/2" 8))) # need "dot" for 'run' behavior
                      ) ) )
               (chain
                  (let Ns (ring (map-octave "'" Notes))  # octave up
                     (arp-in "4/4" (++ Ns)
                        (4 . ((T "5/4" 16) (T "3/2" 8)))
                     ) ) )
            ) ) )
      # RH
      (lyWrap
         ~(let Notes '("f" "g" "bes" "c'")
            (make
               (chain
                  (let Ns (ring Notes)
                     (arp-in "4/4" (++ Ns)
                        (8 . ((T "5/4" 32) (2 (T "3/2" 32))))
                      ) ) )
               (chain
                  (let Ns (ring (map-octave "'" Notes))  # octave up
                     (arp-in "4/4" (++ Ns)
                        (8 . ((T "5/4" 32) (2 (T "3/2" 32))))
                     ) ) )
            ) ) )
   ) )

(de render-cg28 ()
   (_lilypond "cg28" (with-midi (cg28)))
   (lilypond "cg28" (cg28)) )

# always hated the name 'lyWrap'
(def '\{ lyWrap)

# same as above, introduce 'arp-chain'
(de cg29 ()
   (lyPiano
      # LH
      (\{
         ~(let Notes '("f'" "g'" "bes'" "c''")
            (arp-chain
               (let Ns (ring Notes)
                  (arp-in "4/4" (++ Ns)
                     (4 . ((T "5/4" 16) (T "3/2" 8))) # need "dot" for 'run' behavior
                   ) ) )
               (let Ns (ring (map-octave "'" Notes))  # octave up
                  (arp-in "4/4" (++ Ns)
                     (4 . ((T "5/4" 16) (T "3/2" 8)))
                  ) ) ) )
      # RH
      (\{
         ~(let Notes '("f" "g" "bes" "c'")
            (arp-chain
               (let Ns (ring Notes)
                  (arp-in "4/4" (++ Ns)
                     (8 . ((T "5/4" 32) (2 (T "3/2" 32))))
                   ) ) )
               (let Ns (ring (map-octave "'" Notes))
                  (arp-in "4/4" (++ Ns)
                     (8 . ((T "5/4" 32) (2 (T "3/2" 32))))
                  ) ) ) )
) )

(de render-cg29 ()
   (_lilypond "cg29" (with-midi (cg29)))
   (lilypond "cg29" (cg29)) )



# holy shit, this works! nested read-macros lol!
#
# comparing 29 to 30...
#
#  if 'arp-chain' is "naked" (see below), nested read-macros are needed. if
#  'arp-chain' is wrapped in a 'let', use the '~' read-macro on the 'let' form.
#
# this is because 'lyWrap' (or '\{') expects "picolisp-lily/pond.l" code.
# everything needs to be either "music atoms" (e.g. "d4.") or 'ly[Function]'
# calls at run-time. most of the examples in this file eventually end up as a
# variation of the following:
#
#  (lyWrap "a4" "b4" (lyTuplet "3/2" ...) "more" "notes" (lyTuplet ...))

(de cg30 ()
   (lyPiano
      # LH
      (\{
         `(arp-chain
            `(let Notes (with-flats (des|maj7))
               (arp-in "4/4" (pack (random-element Notes) (random-octave-from-range 1 2))
                  (4 . ((T "5/4" 16) (T "3/2" 8))) ) ) # need "dot" for 'run' behavior
            `(let Notes (with-flats (des/lyd))
               (arp-in "4/4" (pack (random-element Notes) (random-octave-from-range 0 2))
                  (4 . ((T "5/4" 16) (T "3/2" 8))) ) ) ) )
      # RH
      (\{
         `(arp-chain
            `(let Notes (with-flats (ees|6))
               (arp-in "4/4" (pack (random-element Notes) (random-octave-from-range 0 -1))
                  (8 . ((T "5/4" 32) (2 (T "3/2" 32)))) ) )
            `(let Notes (with-sharps (d|maj7))
               (arp-in "4/4" (pack (random-element Notes) (random-octave-from-range 0 -1))
                  (8 . ((T "5/4" 32) (2 (T "3/2" 32)))) ) ) ) ) ) )

(de render-cg30 ()
   (_lilypond "cg30" (with-midi (cg30)))
   (lilypond "cg30" (cg30)) )


# introduce 'arps' (better name for 'arp-chain')
(de cg31 ()
   (lyPiano
      # LH
      (\{
         `(arps
            `(let Notes (with-flats (des|maj7))
               (arp-in "4/4" (pack (random-element-no-repeats Notes) (random-octave-from-range 1 2))
                  (4 . ((T "5/4" 16) (T "3/2" 8))) ) ) # need "dot" for 'run' behavior
            `(let Notes (with-flats (des/lyd))
               (arp-in "4/4" (pack (random-element-no-repeats Notes) (random-octave-from-range 0 2))
                  (4 . ((T "5/4" 16) (T "3/2" 8))) ) ) ) )
      # RH
      (\{
         `(arps
            `(let Notes (with-flats (ees|6))
               (arp-in "4/4" (pack (random-element-no-repeats Notes) (random-octave-from-range 0 -1))
                  (8 . ((T "5/4" 32) (2 (T "3/2" 32)))) ) )
            `(let Notes (with-sharps (d|maj7))
               (arp-in "4/4" (pack (random-element-no-repeats Notes) (random-octave-from-range 0 -1))
                  (8 . ((T "5/4" 32) (2 (T "3/2" 32)))) ) ) ) ) ) )

(de render-cg31 ()
   (_lilypond "cg31" (with-midi (cg31)))
   (lilypond "cg31" (cg31)) )

# test that pattern works outside of 'lyPiano'
(de cg32 ()
   (\{
      `(arps
         `(let Notes (with-flats (des|maj7))
            (arp-in "4/4" (pack (random-element Notes) (random-octave-from-range 1 2))
               (4 . ((T "5/4" 16) (T "3/2" 8))) ) ) # need "dot" for 'run' behavior
         `(let Notes (with-flats (des/lyd))
            (arp-in "4/4" (pack (random-element Notes) (random-octave-from-range 0 2))
               (4 . ((T "5/4" 16) (T "3/2" 8))) ) ) ) )
)

(de render-cg32 ()
   (_lilypond "cg32" (with-midi (cg32)))
   (lilypond "cg32" (cg32)) )

# this works and is roughly the syntax i want, but way too many-readmacros...
(de cg33 ()
   `(piano
      # LH
      `(arps
         `(let Notes (with-flats (des|maj7))
            (arp-in "4/4" (pack (random-element-no-repeats Notes) (random-octave-from-range 1 2))
               (4 . ((T "5/4" 16) (T "3/2" 8))) ) )
         `(let Notes (with-flats (des/lyd))
            (arp-no-wrap (pack (random-element-no-repeats Notes) (random-octave-from-range 0 2))
               (4 . ((T "5/4" 16) (T "3/2" 8))) ) ) )
      # RH
      `(arps
         `(let Notes (with-flats (ees|6))
            (arp-in "4/4" (pack (random-element-no-repeats Notes) (random-octave-from-range 0 -1))
               (2 . ((T "5/4" 8) (2 (T "3/2" 4)))) ) )
         `(let Notes (with-flats (aes|maj7))
            (arp-in "4/4" (pack (random-element-no-repeats Notes) (random-octave-from-range 0 -1))
               (2 . ((T "5/4" 8) (2 (T "3/2" 4)))) ) ) ) ) )

(de render-cg33 ()
   (_lilypond "cg33" (with-midi (cg33)))
   (lilypond "cg33" (cg33)) )

# better... but i'm not committed yet.
(de cg34 ()
   (piano%
      # LH
      (arps%
         (let Notes (with-flats (des|maj7))
            (arp-in "4/4" (pack (random-element-no-repeats Notes) (random-octave-from-range 1 2))
               (4 . ((T "5/4" 16) (T "3/2" 8))) ) )
         (let Notes (with-flats (des/lyd))
            (arp-no-wrap (pack (random-element-no-repeats Notes) (random-octave-from-range 0 2))
               (4 . ((T "5/4" 16) (T "3/2" 8))) ) ) )
      # RH
      (arps%
         (let Notes (with-flats (ees|6))
            (arp-in "4/4" (pack (random-element-no-repeats Notes) (random-octave-from-range 0 -1))
               (2 . ((T "5/4" 8) (2 (T "3/2" 4)))) ) )
         (let Notes (with-flats (aes|maj7))
            (arp-in "4/4" (pack (random-element-no-repeats Notes) (random-octave-from-range 0 -1))
               (2 . ((T "5/4" 8) (2 (T "3/2" 4)))) ) ) ) ) )

(de render-cg34 ()
   (_lilypond "cg34" (with-midi (cg34)))
   (lilypond "cg34" (cg34)) )
