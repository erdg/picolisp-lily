(class +Chart +Entity)
(rel id (+Need +Key +Number))
(rel nm (+Ref +String))
(rel tracks (+List +Joint) chart (+Track))

(rel l (+Blob))
(rel ly (+Blob))
(rel svg (+Blob))
(rel cropped.svg (+Blob))

# '+Chart' creator method
#
#   creates picolisp file with unique fn, e.g. 'test%1' (see 'blobFn')
#
(dm T ()
   (put!> This 'id (genKey 'id '+Chart))
   (put!> This 'l T)
   # put prototype in file
   (out (blob This 'l) (prin "(de " (blobFn This) " ())"))
   # load it
   (load (blob This 'l)) )

(de new-chart () (new! '(+Chart)))

# edit picolisp file
(dm vi> ()
   (macro
      (vi (quote ^(list (blobFn This)))) )
   (load (blob This 'l)) )  # and reload it

# write lilypond file
(dm ly> ()
   (unless (: ly) (put!> This 'ly T))
   (out (blob This 'ly)
      # need to write variation of 'lilypond' here
      (lyVersion)
      (lyLayout)
      (lyInclude "lilyjazz.ily")
      (lyInclude "jazzchords.ly")
      ((blobFn This)) ) )  # call function in pl file

(dm echo> ()
   (in (blob This 'ly) (echo)) )

# render lilypond file to svg
(dm render> ()
   (unless (: svg) (put!> This 'svg T))
   (unless (: cropped.svg) (put!> This 'cropped.svg T))
   (t (call 'lilypond "-dcrop" "-dbackend=svg" "-o" (blobDir This) (blob This 'ly))) )

# FIXME - this method makes a mess of the console. figure out way to mute
# output
(dm clean> ()
   (let CleanSvg
      (in (blob This 'svg)
         (pack
            (make
               (while (line T)
                  # remove <a> tags from svg
                  (unless (or (pre? "<a" @) (pre? "</a>" @))
                     (link @) ) ) ) ) )
      (out (blob This 'svg) (prin CleanSvg)) )
   (let CleanCroppedSvg
      (in (blob This 'cropped.svg)
         (pack
            (make
               (while (line T)
                  # remove <a> tags from svg
                  (unless (or (pre? "<a" @) (pre? "</a>" @))
                     (link @) ) ) ) ) )
      (out (blob This 'cropped.svg) (prin CleanCroppedSvg)) ) )

# send updated SVG to the browser
(dm send> ()
   (let @Sse (any (pack "*Obj" (: id) "chart"))
      (macro
         (serverSend @Sse
            (<img> ^(list (pack "http://localhost:8080/" (blob This 'cropped.svg) "#" (date) (time)))) ) )
      T ) )

# sse helpers, e.g. *SsEvt -> (("obj3" *Obj3) ... )
(dm sseVar> () (any (pack "*Obj" (: id))))
(dm sseId>  () (pack "obj" (: id)))  # connects to <div> from 'collectCharts'

(dm work> ()
   (vi> This)
   (ly> This)
   (render> This)
   (clean> This)
   (send> This) )

(dm rename> (Name)
   (put!> This 'nm Name)
   (let @Sse (any (pack "*Obj" (: id) "name"))
      (macro
         (serverSend @Sse
            (<h2> NIL ^(list (: nm))) ) )
      T ) )

(class +Track +Entity)
(rel id (+Need +Key +Number))
(rel nm (+Ref +String))
(rel chart (+Joint) tracks (+Chart))

(rel wav (+Blob))

(de new-track ()
   (new! '(+Track)) )

(dm T ()
   (put!> This 'id (genKey 'id '+Track)) )

(dm record> (Name)
   (put!> This 'nm Name)
   (unless (: wav) (put!> This 'wav T))
   (record (blob This 'wav))
   (noContent)
   (serverSend *Tracks
      (<TracksTable> (collect 'id '+Track)) ) )

(dm rename> (Name)
   (put!> This 'nm Name)
   (serverSend *Tracks 
      (<TracksTable>) )
   T )
