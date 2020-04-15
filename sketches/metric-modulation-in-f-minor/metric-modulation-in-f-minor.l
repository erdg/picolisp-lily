[de metric-modulation-in-f-minor ()
   (chdir "metric-modulation-in-f-minor"
      (lilypond "metric-modulation-in-f-minor"
         (let [L '("c''8" "aes'8" "aes''8" "f'8" "c''8" "aes'8" "aes''8" "f'8")  # left hand notes
               R (mapcar '((X) (pack (delete "'" (chop X)))) L) ]  # right hand notes, drop octave "f'8" -> "f8"
            (lyPiano
               (left%)
               (append R R R R R R R R R) ) ] # 8 measures

# read macros and nested 'fill's, madness lurks below...

# this was the original idea... a picolisp (read) macro that writes
# picolisp-lilypond code that writes lilypond code that writes beautiful
# sheet music
# 
# the 'make' call has been turned into a function 'makeTuplets' below
(de left ()
   # read macro 
   `(fill
      '(lyWrap  
         ^(make # splice in result of 'make'
            # circular list allows to get the correct note, regardless of how
            # many tuplets or how many notes in a single tuplet. just keep poppin'!
            (let Notes (circ "c''8" "aes'8" "aes''8" "f'8")  
               (do 4 (link 
                  (fill '(lyTuplet "3/2" ^ (list (pop 'Notes)) ^ (list (pop 'Notes)) ^ (list (pop 'Notes)))))))))))

# generated code looks more or less like this
#
# (lyWrap
#    (lyTuplet "3/2" "c''8" "aes'8" "aes''8")
#    (lyTuplet "3/2" "f'8" "c''8" "aes'8")
#    (lyTuplet "3/2" "aes''8" "f'8" "c''8")
#    (lyTuplet "3/2" "aes'8" "aes''8" "f'8") )


# i needed another variation with 16th notes
#
# ^(make
#    (let Notes (circ "c''16" "aes'16" "aes''16" "f'16") # 16th notes
#       (do 4 (link 
#          (fill '(lyTuplet "6/4" ^ (make (do 6 (chain (list (pop 'Notes)))))))))))
#
# so similar, too much typing - time to make a new function!



# 'makeTuplets' generates 'lyTuplet' code above (not including 'lyWrap')
# this needs to be defined before because 'left%', it's calling
# function, because read macro
(de makeTuplets (N1 N2 Dur)
   (make 
      # since the whole sketch is based on this string of notes, this should really move
      # to 'left% or even the top-level 'metric-modulation-in-f-minor
      (let Notes (circ (pack "c''" Dur) (pack "aes'" Dur) (pack "aes''" Dur) (pack "f'" Dur))
         (do 4 (link 
            (fill '(lyTuplet ^(list (pack N1 "/" N2)) ^(make (do N1 (chain (list (pop 'Notes))))))))))))  # no wonder people don't use lisp


# left hand part
[de left% ()
   # read macro 
   `(fill
      '(lyWrap  
         # the notes
         ^(list "c''8" "aes'8" "aes''8" "f'8" "c''8" "aes'8" "aes''8" "f'8")
         ^(list "c''8" "aes'8" "aes''8" "f'8" "c''8" "aes'8" "aes''8" "f'8")
         # the original idea
         ^(make # ^ means to splice in result... of 'make' in this case
           (let Notes (circ "c''8" "aes'8" "aes''8" "f'8")
              (do 4 (link 
                 (fill '(lyTuplet "3/2" ^ (list (pop 'Notes)) ^ (list (pop 'Notes)) ^ (list (pop 'Notes))))))))
         ^(makeTuplets 3 2 8)  # same as above, 8th note triplets
         ^(do 2 (makeTuplets 4 4 16)) # same as above
         ^(do 2 (makeTuplets 5 4 16)) 
         ^(do 2 (makeTuplets 6 4 16))
         ^(do 2 (makeTuplets 7 4 16))
         ^(do 2 (makeTuplets 6 4 16))
         ^(do 2 (makeTuplets 5 4 16)) 
         ^(do 2 (makeTuplets 4 4 16))
         ^(do 2 (makeTuplets 3 2 8))
         ^(do 4 (makeTuplets 3 2 4)) ]

# This was an exercise in writing picolisp code that writes picolisp code that
# writes lilypond code that writes sheet music
