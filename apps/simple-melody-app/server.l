(load 
   "../pond.l" 
   "entities.l"
   "lib/picolisp-json/json.l" 
   "lib/picolisp-minimal-http/http.l"
)

(setq 
   *Pool "db/"
   *Blob "db/blob/"
   )

(de fetchMelody ()
   (http1 "application/json")
   (prinl "Access-Control-Allow-Origin: *^M")
   (prinl "Content-Length: ^M^J^M")
   (prin
      (json~encode
         (list
            (cons "melody"
               (in (blob '{2} 'preview.svg)
                  (pack
                     (make
                        (while (line T)
                           # remove <a> tags from svg. lilypond puts these in as 
                           # references to code in a file.
                           # not ok when your files are in the picolisp db and you're
                           # sending them out to the internet.
                           (if (pre? "<a" @)
                              (link "<a style=\"color:inherit;display:block;\"
                                       onclick=\"alert('a note has been clicked')\"
                                       onmouseover=\"this.style.color='blue'\"
                                       onmouseout=\"this.style.color='inherit'\">")
                              (link @) ) ) ) ) ) ) ) ) ) )

(de postMelody ()
   (let Json (json~decode *Post)
      (with (db 'id '+Melody 1)
         (put!> This 'note (getJson "note" Json))
         (put!> This 'tim  (getJson "timS" Json))
         (put!> This 'key  (getJson "keyS" Json))
         (put!> This 'clf  (getJson "clef" Json))
         (finally (commit) (queue (:: mus) (getJson "mus" Json)))
         (lily> This)
         (render> This)
         (respondJson
            (list
               (cons "melody"
                  (in (blob '{2} 'preview.svg)
                     (pack
                        (make
                           (while (line T)
                              # remove <a> tags from svg. lilypond puts these in as 
                              # references to code in a file.
                              # not ok when your files are in the picolisp db and you're
                              # sending them out to the internet.
                              (unless (or (pre? "<a" @) (pre? "</a>" @))
                                 (link @) ) ) ) ) ) ) ) ) ) ) )

(dbs
   (2 +Melody)
   (2 +Hits)
   (2 +Changes) )

(de main ()
   (call 'mkdir "-p" *Pool *Blob)
   (pool *Pool *Dbs)
   (unless (seq *DB)
      (with
         (new! '(+Melody) 
            'id (genKey 'id '+Melody)
            'nm "Test Melody"
            'note "c''"
            'tim "3/4"
            'mus '("a4" "b4" "c4" "d2.") )
         (lily> This)
         (render> This) ) ) )

(de go () (server 8888))

# utils
(de respondJson (Lst)
   (let Json (json~encode Lst)
      (http1 "application/json" 0)
      (prinl "Access-Control-Allow-Origin: *^M")
      (prinl "Content-Length: " (size Json) "^M^J^M")
      (prin Json) ) )

(de getJson (Key Lst)
   (cdr (assoc Key Lst)) )
