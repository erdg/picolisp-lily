(class +Melody +Entity)
(rel id (+Key +Number))
(rel nm (+String))

(rel note (+String))       # relative note
(rel tim (+String))        # time signature
(rel clf (+String))        # clef
(rel mus (+List +String))  # music (lilypond symbols)

# this is a hack, but I kind of like the idea of hijacking
# the file extentsion
(rel ly (+Blob))           # lilypond file
(rel svg (+Blob))          # svg
(rel preview.svg (+Blob))  # cropped svg

# write lilypond file
(dm lily> ()
   (put!> This 'ly T)
   (out (blob This 'ly)
      (lyVersion)
      (lyRelative (: note)
         (if (: tim) (lyTime @))
         (if (: clf) (lyClef @))
         (lyEval (: mus)) ) ) )

# render lilypond file to svg
# will need a function to strip all '<a>' tags from the svg file
# lilypond links to lines in the source file. not okay for sharing
# svg's on the internet, when the source files are +Blob's in the
# picolisp DB
(dm render> ()
   (unless (: svg) (put!> This 'svg T))
   (unless (: preview.svg) (put!> This 'preview.svg T))
   (t (call 'lilypond "-dpreview" "-dbackend=svg" "-o" (blobDir This) (blob This 'ly))) )


(class +Hits +Entity)
(rel id (+Key +Number))
(rel nm (+String))

(rel tim (+String))        # time signature
(rel clf (+String))        # clef
(rel mus (+List +String))  # music (lilypond symbols)

(rel ly (+Blob))           # lilypond file
(rel svg (+Blob))          # svg
(rel preview.svg (+Blob))  # cropped svg

# write lilypond file
(dm lily> ()
   (put!> This 'ly T)
   (out (blob This 'ly)
      (lyVersion)
      (lyHits (: tim) (: clf) (: mus)) ) )

# render lilypond file to svg
(dm render> ()
   (unless (: svg) (put!> This 'svg T))
   (unless (: preview.svg) (put!> This 'preview.svg T))
   (t (call 'lilypond "-dpreview" "-dbackend=svg" "-o" (blobDir This) (blob This 'ly))) )


(class +Changes +Entity)
(rel id (+Key +Number))
(rel nm (+String))

(rel num (+Number))        # number of measures
(rel mus (+List +String))  # music (lilypond symbols)

(rel ly (+Blob))           # lilypond file
(rel svg (+Blob))          # svg
(rel preview.svg (+Blob))  # cropped svg

# write lilypond file
(dm lily> ()
   (put!> This 'ly T)
   (out (blob This 'ly)
      (lyVersion)
      (lyChanges (: num) (: mus)) ) )

# render lilypond file to svg
(dm render> ()
   (unless (: svg) (put!> This 'svg T))
   (unless (: preview.svg) (put!> This 'preview.svg T))
   (t (call 'lilypond "-dpreview" "-dbackend=svg" "-o" (blobDir This) (blob This 'ly))) )

# utils

# returns blob subdirectory
# (blobDir '{A1}) -> "db/blob/A/"
# (blobDir '{2}) -> "db/blob/"
(de blobDir (Obj)
   (pack
      (glue "/"
         (filter '((X) (not (num? (any (car X)))))
            (split (chop (blob Obj)) "/") ) )
      "/" ) )
