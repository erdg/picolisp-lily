(load "../pond.l")

(class +MusicObj +Entity)
(rel id (+Need +Key +Number))
# (rel nm (+Ref +String))

(rel l (+Blob))            # pl file
(rel ly (+Blob))           # ly file
(rel svg (+Blob))          # svg
(rel preview.svg (+Blob))  # cropped svg

(dm T ()
   (put!> This 'id (genKey 'id '+MusicObj))
   (put!> This 'l T)
   # put prototype in file
   (out (blob This 'l) (prin "(de " (blobFn This) " ())"))
   # load it
   (load (blob This 'l)) )

# edit picolisp file
(dm vi> ()
   (macro
      (vi (quote ^(list (blobFn This)))) )
   (load (blob This 'l)) )

# write lilypond file
(dm lilypond> ()
   (unless (: ly) (put!> This 'ly T))
   (out (blob This 'ly)
      # need to write variation of 'lilypond' here
      (lyVersion)
      ((blobFn This)) ) )

(dm echo> ()
   (in (blob This 'ly) (echo)) )

# render lilypond file to svg
#
# NOTE - will need a function to strip all '<a>' tags from the svg file
# lilypond links to lines in the source file. not okay for sharing
# svg's on the internet, when the source files are +Blob's in the
# picolisp DB
(dm render> ()
   (unless (: svg) (put!> This 'svg T))
   (unless (: preview.svg) (put!> This 'preview.svg T))
   (t (call 'lilypond "-dpreview" "-dbackend=svg" "-o" (blobDir This) (blob This 'ly))) )

(dm sanitizeSVGs> ()
   (let CleanSvg
      (in (blob This 'svg)
         (pack
            (make
               (while (line T)
                  # remove <a> tags from svg
                  (unless (or (pre? "<a" @) (pre? "</a>" @))
                     (link @) ) ) ) ) )
      (out (blob This 'clean.svg) (prin CleanSvg)) )
   (let CleanPreviewSvg
      (in (blob This 'preview.svg)
         (prin
            (pack
               (make
                  (while (line T)
                     # remove <a> tags from svg
                     (unless (or (pre? "<a" @) (pre? "</a>" @))
                        (link @) ) ) ) ) ) )
      (out (blob This 'clean.preview.svg) (prin CleanPreviewSvg)) ) )

(de sendMusic ()
   (serverSend *Sse
      (ht:Pack
         (make
            (for Obj (collect 'id '+MusicObj)
               (chain
                  (<span> '(draggable (style . "width: min-content; position: fixed;"))
                     (<img> (pack "http://localhost:8080/" (blob Obj 'clean.preview.svg))) ) ) ) ) ) ) )

(setq
   *Pool "db/test.db"
   *Blob "db/blob/" )

(de main ()
   (call "mkdir" "-p" *Blob)
   (pool *Pool *Dbs)
   # load +MusicObj's
   (for Obj (collect 'id '+MusicObj) (load (blob Obj 'l))) )

(load "@lib/http.l" "@lib/xhtml.l")

(de go () (server 8080 "!work"))

(de work ()
   (app)
   (timeout)
   (redirect (baseHRef) *SesId "!musicApp") )


(push '*JS "interact.min.js")

(de musicApp ()
   (app)
   (html NIL "music app" NIL NIL
      (serverSentEvent "sse" '*Sse)
      (<div> '(id . "sse")
         (for Obj (collect 'id '+MusicObj)
            (<span> '(draggable (style . "width: min-content; position: fixed;"))
               (<img> (pack "http://localhost:8080/" (blob Obj 'clean.preview.svg))) ) ) )
      # this should be in another file
      (javascript NIL
         "interact('.draggable').draggable({
            listeners: {
               move: dragMoveListener
            },
            autoScroll: true
         })
         function dragMoveListener (event) {
            var target = event.target
            var x = (parseFloat(target.getAttribute('data-x')) || 0) + event.dx
            var y = (parseFloat(target.getAttribute('data-y')) || 0) + event.dy
            target.style.transform = 'translate(' + x + 'px, ' + y + 'px)'
            target.setAttribute('data-x', x)
            target.setAttribute('data-y', y)
         }" ) ) )

### utils

# returns blob subdirectory
# (blobDir '{A1}) -> "db/blob/A/"
# (blobDir '{2}) -> "db/blob/"
(de blobDir (Obj)
   (pack
      (glue "/"
         (filter '((X) (not (num? (any (car X)))))
            (split (chop (blob Obj)) "/") ) )
      "/" ) )

(de blobFn (Obj)
   (and (blob Obj)
      (chop @)
      (split @ "/" ".")
      (pack (cdr @))
      (any @) ) )
