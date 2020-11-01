(load
   "../pond.l"
   "db.l"
   "@lib/http.l"
   "@lib/xhtml.l"
   "app.l"
   "sox.l" )

### main program api
#
# switch - switch to a new project (and create if it does not exist)
# projects - list existing projects (organized as db per project)
# music - list +Chart's in project

## +Chart methods
#
# rename> - rename obj
# work> - edit obj and update app
#
# and more - see "db.l"

# each project is a directory, with a db file and +Blob's
(de switch (Name)
   (let (Pool (pack "db/" Name "/" Name ".db")
         Blob (pack "db/" Name "/") )
      (setq
         *Pool Pool
         *Blob Blob )
      (call "mkdir" "-p" *Blob)
      (pool *Pool) )
   )


(de projects () (chdir "db/" (dir)))

(de charts ()
   (make
      (for Obj (collect 'id '+Chart)
         (link
            (list Obj (if (; Obj nm) @)) ) ) ) )

(de list-tracks (Tracks)
   (default Tracks (collect 'id '+Track))
   (make
      (for Track Tracks
         (link
            (cons
               (; Track nm)
               (insert 2
                  (cdr (track-info (blob Track 'wav)))
                  (track-duration (blob Track 'wav)) ) ) ) ) ) )

(de track-info (Track)
   (and
      (in (list 'soxi Track)
         (make
            (until (eof)
               (link (line T)) ) ) )
      (clip @)
      (head 6 @)
      (remove 5 @)   # 'duration' is special
      (remove 3 @)   # samplerate
      (remove 3 @)   # precision
      (mapcar '((S) (split (chop S) ":")) @)
      (mapcar last @)
      (mapcar clip @)
      (mapcar pack @)
      ) )

(de track-duration (Track)
   (and
      (in (list 'soxi Track)
         (make
            (until (eof)
               (link (line T)) ) ) )
      (clip @)
      (car (cddddr @))
      (split (chop @) "=")
      (car @)
      (split @ ":")
      (cdr @)
      (mapcar clip @)
      (cdr @)
      (glue ":" @)
      ) )

(de api-record ()
   (record> (new-track)) )


# init stuff
(setq
   *Pool "db/test/test.db"
   *Blob "db/test/" )

(de main ()
   (call "mkdir" "-p" *Blob)
   (pool *Pool *Dbs)
   # load +Chart's
   (for Obj (collect 'id '+Chart) (load (blob Obj 'l))) )

(de go () (server 8080 "!work"))

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

# returns fn from +Chart
(de blobFn (Obj)
   (and (blobDir Obj)
      (chop @)
      (split @ "/" ".")
      (pack (cdr @) "%" (; Obj id))
      (any @) ) )  # -> e.g. test%1 (project%id)
